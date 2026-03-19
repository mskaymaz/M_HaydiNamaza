import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:intl/intl.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';

import '../../app/calculation_method_storage.dart';
import '../../app/locale_controller.dart';
import '../../app/location_storage.dart';
import '../../app/reminder_audio_service.dart';
import '../../app/prayer_row_settings_storage.dart';
import '../../app/prayer_service.dart';
import '../../app/reminder_text_settings_storage.dart';
import '../../app/reminder_trigger_storage.dart';
import '../../app/ui_palette_controller.dart';
import '../../core/config/config_registry.dart';
import '../../core/prayer_engine/prayer.dart';
import '../../core/prayer_engine/prayer_times.dart';
import '../reminders/flashing_reminder_card.dart';
import '../settings/location_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final LocaleController localeController;
  final UiPaletteController uiPaletteController;

  const HomeScreen({
    super.key,
    required this.localeController,
    required this.uiPaletteController,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _locationStorage = LocationStorage();
  final _methodStorage = CalculationMethodStorage();
  final _rowSettingsStorage = PrayerRowSettingsStorage();
  final _reminderTextStorage = ReminderTextSettingsStorage();
  final _reminderTriggerStorage = ReminderTriggerStorage();
  final _reminderAudioService = ReminderAudioService();
  final _prayerService = PrayerService();
  final Map<Prayer, _PrayerRowSettings> _rowSettings = {};
  final Map<Prayer, TextEditingController> _reminderControllers = {};
  final Map<String, String> _triggerLog = {};

  late Future<_HomeData> _future;
  Timer? _ticker;
  Timer? _voiceRepeatTimer;
  Timer? _visualCycleTimer;
  Timer? _vibrationRepeatTimer;
  DateTime _now = DateTime.now();
  DateTime _lastRefreshDay = DateTime.now();
  bool _showList = true;
  bool _showHijriDate = false;
  bool _reminderCheckInProgress = false;
  DateTime? _voiceLoopUntil;
  String? _voiceLoopPrayerLabel;
  DateTime? _visualLoopUntil;
  String? _visualLoopPrayerLabel;
  String? _visualLoopMessage;
  String? _vibrationLoopPrayerLabel;
  bool _showVisualOverlay = false;
  ReminderTextSettings _reminderSettings = const ReminderTextSettings(
    voiceText: '',
    visualText: '',
  );

  @override
  void initState() {
    super.initState();
    _lastRefreshDay = DateTime(_now.year, _now.month, _now.day);
    unawaited(_loadPrayerRowSettings());
    unawaited(_loadReminderSettings());
    unawaited(_loadReminderTriggerLog());
    _future = _loadData();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final dayChanged = now.year != _lastRefreshDay.year ||
          now.month != _lastRefreshDay.month ||
          now.day != _lastRefreshDay.day;
      setState(() {
        _now = now;
        if (dayChanged) {
          _lastRefreshDay = DateTime(now.year, now.month, now.day);
          _future = _loadData();
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _voiceRepeatTimer?.cancel();
    _visualCycleTimer?.cancel();
    _vibrationRepeatTimer?.cancel();
    _reminderAudioService.dispose();
    for (final controller in _reminderControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<_HomeData> _loadData() async {
    final location = await _locationStorage.read();
    var methodCode = await _methodStorage.readCode();
    methodCode ??= 'turkey';
    if (location == null) {
      return _HomeData(location: null, methodCode: methodCode);
    }

    final lat = double.tryParse(location.latitude);
    final lon = double.tryParse(location.longitude);
    if (methodCode != 'turkey' && (lat == null || lon == null)) {
      return _HomeData(
        location: location,
        methodCode: methodCode,
        error: 'invalid_location',
      );
    }

    final timeZone = _offsetToTz(DateTime.now().timeZoneOffset);
    final times = await _prayerService.calculateToday(
      location: location,
      latitude: lat ?? 0,
      longitude: lon ?? 0,
      timeZone: timeZone,
      methodCode: methodCode,
    );

    return _HomeData(
      location: location,
      methodCode: methodCode,
      times: times,
    );
  }

  Future<void> _loadReminderSettings() async {
    final settings = await _reminderTextStorage.read();
    if (!mounted) {
      _reminderSettings = settings;
      return;
    }
    setState(() {
      _reminderSettings = settings;
    });
  }

  Future<void> _loadReminderTriggerLog() async {
    final saved = await _reminderTriggerStorage.read();
    _triggerLog
      ..clear()
      ..addAll(saved);
  }

  void _stopVoiceLoop() {
    _voiceRepeatTimer?.cancel();
    _voiceRepeatTimer = null;
    if (_voiceLoopUntil != null || _voiceLoopPrayerLabel != null) {
      setState(() {
        _voiceLoopUntil = null;
        _voiceLoopPrayerLabel = null;
      });
    }
    _syncVibrationLoop();
  }

  void _stopVisualLoop() {
    _visualCycleTimer?.cancel();
    _visualCycleTimer = null;
    if (_visualLoopUntil != null ||
        _visualLoopPrayerLabel != null ||
        _visualLoopMessage != null ||
        _showVisualOverlay) {
      setState(() {
        _visualLoopUntil = null;
        _visualLoopPrayerLabel = null;
        _visualLoopMessage = null;
        _showVisualOverlay = false;
      });
    }
    _syncVibrationLoop();
  }

  void _stopVibrationLoop() {
    _vibrationRepeatTimer?.cancel();
    _vibrationRepeatTimer = null;
    if (_vibrationLoopPrayerLabel != null) {
      setState(() {
        _vibrationLoopPrayerLabel = null;
      });
    }
  }

  void _syncVibrationLoop() {
    if (_voiceLoopPrayerLabel == null && _visualLoopPrayerLabel == null) {
      _stopVibrationLoop();
    }
  }

  void _startVoiceLoop({
    required String prayerLabel,
    required DateTime prayerTime,
  }) {
    _stopVoiceLoop();
    final repeatSeconds = _reminderSettings.voiceRepeatSeconds;
    if (repeatSeconds <= 0) return;
    setState(() {
      _voiceLoopUntil = prayerTime;
      _voiceLoopPrayerLabel = prayerLabel;
    });
    _voiceRepeatTimer = Timer.periodic(Duration(seconds: repeatSeconds), (_) async {
      if (!mounted ||
          _voiceLoopUntil == null ||
          DateTime.now().isAfter(_voiceLoopUntil!) ||
          !_canPlayVoiceReminder()) {
        _stopVoiceLoop();
        return;
      }
      try {
        await _reminderAudioService.playReminder(
          settings: _reminderSettings,
          selectedLocale: widget.localeController.value,
          prayerLabel: prayerLabel,
        );
      } catch (_) {}
    });
  }

  void _startVisualLoop({
    required String prayerLabel,
    required String message,
    required DateTime prayerTime,
  }) {
    _stopVisualLoop();
    setState(() {
      _visualLoopUntil = prayerTime;
      _visualLoopPrayerLabel = prayerLabel;
      _visualLoopMessage = message;
      _showVisualOverlay = true;
    });
    _scheduleVisualPhase(isVisible: true);
  }

  void _startVibrationLoop({required String prayerLabel}) {
    _vibrationRepeatTimer?.cancel();
    final vibrationOnMilliseconds =
        _reminderSettings.vibrationDurationSeconds * 1000;
    final vibrationOffMilliseconds =
        _reminderSettings.vibrationPauseSeconds * 1000;
    setState(() {
      _vibrationLoopPrayerLabel = prayerLabel;
    });
    _vibrationRepeatTimer = Timer.periodic(
      Duration(
        milliseconds: vibrationOnMilliseconds + vibrationOffMilliseconds,
      ),
      (_) async {
        if (!mounted ||
            (_voiceLoopPrayerLabel == null &&
                _visualLoopPrayerLabel == null)) {
          _stopVibrationLoop();
          return;
        }
        await _playVibrationPulse(vibrationOnMilliseconds);
      },
    );
  }

  Future<void> _playVibrationPulse(int durationMilliseconds) async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        await Vibration.vibrate(duration: durationMilliseconds);
        return;
      }
    } catch (_) {}
    await HapticFeedback.mediumImpact();
  }

  void _scheduleVisualPhase({required bool isVisible}) {
    _visualCycleTimer?.cancel();
    final until = _visualLoopUntil;
    if (!mounted || until == null || DateTime.now().isAfter(until)) {
      _stopVisualLoop();
      return;
    }
    final seconds = isVisible
        ? _reminderSettings.visualDisplaySeconds
        : _reminderSettings.visualReopenSeconds;
    if (!isVisible && seconds <= 0) {
      setState(() {
        _showVisualOverlay = true;
      });
      _scheduleVisualPhase(isVisible: true);
      return;
    }
    _visualCycleTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted || _visualLoopUntil == null || DateTime.now().isAfter(_visualLoopUntil!)) {
        _stopVisualLoop();
        return;
      }
      setState(() {
        _showVisualOverlay = !isVisible;
      });
      _scheduleVisualPhase(isVisible: !isVisible);
    });
  }

  String _offsetToTz(Duration offset) {
    final totalMinutes = offset.inMinutes;
    final sign = totalMinutes < 0 ? '-' : '+';
    final total = totalMinutes.abs();
    final hours = (total ~/ 60).toString().padLeft(2, '0');
    final mins = (total % 60).toString().padLeft(2, '0');
    return '$sign$hours:$mins';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatGregorianYear(DateTime dt, AppLocalizations l10n) {
    return DateFormat.y(l10n.localeName).format(dt);
  }

  String _formatGregorianDayMonth(DateTime dt, AppLocalizations l10n) {
    return DateFormat.MMMMd(l10n.localeName).format(dt);
  }

  String _formatHijriYear(DateTime dt) {
    final hijri = _toHijri(dt);
    return hijri.year.toString();
  }

  String _formatHijriDayMonth(DateTime dt, AppLocalizations l10n) {
    final hijri = _toHijri(dt);
    final months = _hijriMonths(l10n.localeName);
    final monthName =
        (hijri.month >= 1 && hijri.month <= 12) ? months[hijri.month - 1] : '';
    return '${hijri.day} $monthName';
  }

  String _titleCase(String input, String locale) {
    final isTr = locale.startsWith('tr');
    final lower = _lowerLocale(input.trim(), isTr);
    if (lower.isEmpty) return lower;
    final buffer = StringBuffer();
    var capitalizeNext = true;
    for (final rune in lower.runes) {
      final ch = String.fromCharCode(rune);
      if (_isWordChar(ch)) {
        if (capitalizeNext) {
          buffer.write(_upperLocale(ch, isTr));
          capitalizeNext = false;
        } else {
          buffer.write(ch);
        }
      } else {
        buffer.write(ch);
        capitalizeNext = ch == ' ' || ch == '/' || ch == '-' || ch == '.';
      }
    }
    return buffer.toString();
  }

  String _lowerLocale(String value, bool isTr) {
    if (!isTr) return value.toLowerCase();
    return value
        .replaceAll('I', 'ı')
        .replaceAll('İ', 'i')
        .toLowerCase();
  }

  String _upperLocale(String value, bool isTr) {
    if (!isTr) return value.toUpperCase();
    if (value == 'i') return 'İ';
    if (value == 'ı') return 'I';
    return value.toUpperCase();
  }

  bool _isWordChar(String ch) {
    return RegExp(r'[0-9A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(ch);
  }

  List<String> _hijriMonths(String locale) {
    if (locale.startsWith('ar')) {
      return const [
        'محرم',
        'صفر',
        'ربيع الأول',
        'ربيع الآخر',
        'جمادى الأولى',
        'جمادى الآخرة',
        'رجب',
        'شعبان',
        'رمضان',
        'شوال',
        'ذو القعدة',
        'ذو الحجة',
      ];
    }
    if (locale.startsWith('tr')) {
      return const [
        'Muharrem',
        'Safer',
        'Rebiülevvel',
        'Rebiülahir',
        'Cemaziyelevvel',
        'Cemaziyelahir',
        'Recep',
        'Şaban',
        'Ramazan',
        'Şevval',
        'Zilkade',
        'Zilhicce',
      ];
    }
    return const [
      'Muharram',
      'Safar',
      'Rabiʻ al-awwal',
      'Rabiʻ al-thani',
      'Jumada al-awwal',
      'Jumada al-thani',
      'Rajab',
      'Shaʻban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qadah',
      'Dhu al-Hijjah',
    ];
  }

  _HijriDate _toHijri(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final a = ((14 - m) / 12).floor();
    final y2 = y + 4800 - a;
    final m2 = m + 12 * a - 3;
    final jd = d +
        ((153 * m2 + 2) / 5).floor() +
        365 * y2 +
        (y2 / 4).floor() -
        (y2 / 100).floor() +
        (y2 / 400).floor() -
        32045;
    var l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    final j = (((10985 - l) / 5316).floor()) *
            (((50 * l) / 17719).floor()) +
        (((l / 5670).floor()) * (((43 * l) / 15238).floor()));
    l = l -
        (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) -
        ((j / 16).floor()) * (((15238 * j) / 43).floor()) +
        29;
    final month = ((24 * l) / 709).floor();
    final day = l - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;
    return _HijriDate(year: year, month: month, day: day);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          localeController: widget.localeController,
          uiPaletteController: widget.uiPaletteController,
        ),
      ),
    );
    await _loadReminderSettings();
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _openQibla(LocationData? location) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _QiblaScreen(location: location),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.location == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.locationNotSet,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: Text(l10n.settingsTitle),
                  ),
                ],
              ),
            );
          }

          if (data.error == 'invalid_location') {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.locationFillAll,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: Text(l10n.settingsTitle),
                  ),
                ],
              ),
            );
          }

          final times = data.times;
          if (times == null) {
            return Center(
              child: Text(
                l10n.comingSoon,
                textAlign: TextAlign.center,
              ),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_checkAndTriggerReminders(times, l10n));
          });

          final items = _buildItems(l10n, times);
          final active = _activePrayer(times, _now);
          final next = _nextPrayer(times, _now, l10n);
          final countdown = _formatCountdown(_now, next.time);
          final nextTime = _formatTime(next.time);
          final location = data.location!;
          final provinceLabel = _titleCase(location.province, l10n.localeName);
          final districtLabel = _titleCase(location.district, l10n.localeName);
          final displayName = districtLabel.trim().isEmpty
              ? provinceLabel
              : '$provinceLabel / $districtLabel';
          final dateYearLabel = _showHijriDate
              ? _formatHijriYear(_now)
              : _formatGregorianYear(_now, l10n);
          final dateDayMonthLabel = _showHijriDate
              ? _formatHijriDayMonth(_now, l10n)
              : _formatGregorianDayMonth(_now, l10n);
          final timeLabel = _formatClock(_now);
          final palette = widget.uiPaletteController.value;
          final ui = ConfigRegistry.mainUiFor(palette);
          final statusBarColor =
              Color.lerp(palette.zeminColor, Colors.white, 0.5) ??
              palette.zeminColor;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: palette.backgroundZeminColor),
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 30,
                  child: SizedBox.shrink(),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 30,
                  child: ColoredBox(color: statusBarColor),
                ),
                Positioned.fill(
                  top: 30,
                  child: IgnorePointer(
                    child: Image.asset(
                      'img/templates_line/bg_motif02.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      color: palette.backgroundCizgiColor.withValues(alpha: 0.5),
                      colorBlendMode: BlendMode.modulate,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: ui.screenPadding,
                    child: Column(
                      children: [
                        GestureDetector(
                          onDoubleTap: () => setState(() => _showList = !_showList),
                          child: _TopPanel(
                            provinceLabel: provinceLabel,
                            districtLabel: districtLabel,
                            nextLabel: next.label,
                            nextTime: nextTime,
                            countdown: countdown,
                            dateYearLabel: dateYearLabel,
                            dateDayMonthLabel: dateDayMonthLabel,
                            timeLabel: timeLabel,
                            onToggleDate: () =>
                                setState(() => _showHijriDate = !_showHijriDate),
                            onLocationTap: () => _openLocationSettings(location),
                            onQibla: () => _openQibla(location),
                            onSettings: _openSettings,
                            style: ui.topPanel,
                            padding: ui.topPanelPadding,
                            settingsIconSize: ui.settingsIconSize,
                            settingsIconBoxSize: ui.settingsIconBoxSize,
                            settingsIconOpacity: ui.settingsIconOpacity,
                            typography: ui.typography,
                            cizgiColor: palette.cizgiColor,
                          ),
                        ),
                        SizedBox(height: ui.sectionGap),
                        Expanded(
                          child: AnimatedCrossFade(
                            duration: const Duration(milliseconds: 220),
                            crossFadeState: _showList
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: _PrayerList(
                              items: items,
                              active: active,
                              timeFormat: _formatTime,
                              style: ui.listPanel,
                              listPadding: ui.listPadding,
                              rowGap: ui.rowGap,
                              iconStyle: ui.iconToggle,
                              chipStyle: ui.reminderChip,
                              typography: ui.typography,
                              cizgiColor: palette.cizgiColor,
                              activeColor: palette.zeminColor,
                              showVoiceIcon: _reminderSettings.showVoiceIcon,
                              showVisualIcon: _reminderSettings.showVisualIcon,
                              showAzanIcon: _reminderSettings.showAzanIcon,
                              showVibrationIcon:
                                  _reminderSettings.showVibrationIcon,
                              onReminderChanged: _setReminderMinutes,
                              onVoiceToggle: _toggleVoiceReminder,
                              onVisualToggle: _toggleVisualReminder,
                              onAzanToggle: _toggleAzanReminder,
                              onVibrationToggle: _toggleVibrationReminder,
                            ),
                            secondChild: _CollapsedHint(
                              label: l10n.locationLabel,
                              value: displayName,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_voiceLoopUntil != null || _visualLoopUntil != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: SafeArea(
                      top: false,
                      child: _ActiveReminderPanel(
                        voicePrayerLabel: _voiceLoopPrayerLabel,
                        visualPrayerLabel: _visualLoopPrayerLabel,
                        visualMessage: _visualLoopMessage,
                        showVisualCard: _showVisualOverlay,
                        onCloseVoice: _stopVoiceLoop,
                        onCloseVisual: _stopVisualLoop,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Prayer _activePrayer(PrayerTimes times, DateTime now) {
    final fajr = _atToday(times.fajr, now);
    final sunrise = _atToday(times.sunrise, now);
    final dhuhr = _atToday(times.dhuhr, now);
    final asr = _atToday(times.asr, now);
    final maghrib = _atToday(times.maghrib, now);
    final isha = _atToday(times.isha, now);
    if (!now.isBefore(isha)) {
      return Prayer.isha;
    }
    if (!now.isBefore(maghrib)) {
      return Prayer.maghrib;
    }
    if (!now.isBefore(asr)) {
      return Prayer.asr;
    }
    if (!now.isBefore(dhuhr)) {
      return Prayer.dhuhr;
    }
    if (!now.isBefore(sunrise)) {
      return Prayer.sunrise;
    }
    if (!now.isBefore(fajr)) {
      return Prayer.fajr;
    }
    return Prayer.fajr;
  }

  Future<void> _openLocationSettings(LocationData? location) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LocationScreen(
          initial: location,
          uiPaletteController: widget.uiPaletteController,
        ),
      ),
    );
    if (changed == true) {
      setState(() {
        _future = _loadData();
      });
    }
  }

  _PrayerNext _nextPrayer(PrayerTimes times, DateTime now, AppLocalizations l10n) {
    final fajr = _atToday(times.fajr, now);
    final sunrise = _atToday(times.sunrise, now);
    final dhuhr = _atToday(times.dhuhr, now);
    final asr = _atToday(times.asr, now);
    final maghrib = _atToday(times.maghrib, now);
    final isha = _atToday(times.isha, now);
    if (now.isBefore(fajr)) {
      return _PrayerNext(label: l10n.prayerFajr, time: fajr);
    }
    if (now.isBefore(sunrise)) {
      return _PrayerNext(label: l10n.prayerSunrise, time: sunrise);
    }
    if (now.isBefore(dhuhr)) {
      return _PrayerNext(label: l10n.prayerDhuhr, time: dhuhr);
    }
    if (now.isBefore(asr)) {
      return _PrayerNext(label: l10n.prayerAsr, time: asr);
    }
    if (now.isBefore(maghrib)) {
      return _PrayerNext(label: l10n.prayerMaghrib, time: maghrib);
    }
    if (now.isBefore(isha)) {
      return _PrayerNext(label: l10n.prayerIsha, time: isha);
    }
    return _PrayerNext(
      label: l10n.prayerFajr,
      time: fajr.add(const Duration(days: 1)),
    );
  }

  String _formatCountdown(DateTime now, DateTime nextTime) {
    final diff = nextTime.difference(now);
    final totalSeconds = diff.inSeconds.clamp(0, 86400);
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  DateTime _atToday(DateTime source, DateTime now) {
    return DateTime(
      now.year,
      now.month,
      now.day,
      source.hour,
      source.minute,
      source.second,
    );
  }

  Future<void> _checkAndTriggerReminders(
    PrayerTimes times,
    AppLocalizations l10n,
  ) async {
    if (_reminderCheckInProgress || !mounted) return;
    _reminderCheckInProgress = true;
    try {
      final now = _now;
      final prayerTimes = <Prayer, DateTime>{
        Prayer.fajr: _atToday(times.fajr, now),
        Prayer.sunrise: _atToday(times.sunrise, now),
        Prayer.dhuhr: _atToday(times.dhuhr, now),
        Prayer.asr: _atToday(times.asr, now),
        Prayer.maghrib: _atToday(times.maghrib, now),
        Prayer.isha: _atToday(times.isha, now),
      };
      for (final entry in prayerTimes.entries) {
        final settings = _settingsFor(entry.key);
        final reminderTime = entry.value.subtract(
          Duration(minutes: settings.reminderMinutes.clamp(0, 1440)),
        );
        final reminderWindowEnd = reminderTime.add(const Duration(minutes: 1));
        final reminderTriggerId = _triggerId(entry.key, 'reminder');
        final reminderTriggerKey = _triggerKey(
          entry.key,
          'reminder',
          reminderTime,
          entry.value,
        );
        if ((settings.voiceEnabled ||
                settings.visualEnabled ||
                settings.vibrationEnabled) &&
            !now.isBefore(reminderTime) &&
            now.isBefore(reminderWindowEnd) &&
            _triggerLog[reminderTriggerId] != reminderTriggerKey) {
          await _triggerReminder(
            prayer: entry.key,
            rowSettings: settings,
            l10n: l10n,
            stage: _ReminderStage.reminder,
            prayerTime: entry.value,
          );
          _triggerLog[reminderTriggerId] = reminderTriggerKey;
          await _reminderTriggerStorage.write(_triggerLog);
        }
        final prayerWindowEnd = entry.value.add(const Duration(minutes: 1));
        final prayerTriggerId = _triggerId(entry.key, 'prayer');
        final prayerTriggerKey = _triggerKey(
          entry.key,
          'prayer',
          entry.value,
          entry.value,
        );
        if ((settings.azanEnabled || settings.vibrationEnabled) &&
            !now.isBefore(entry.value) &&
            now.isBefore(prayerWindowEnd) &&
            _triggerLog[prayerTriggerId] != prayerTriggerKey) {
          await _triggerReminder(
            prayer: entry.key,
            rowSettings: settings,
            l10n: l10n,
            stage: _ReminderStage.prayer,
            prayerTime: entry.value,
          );
          _triggerLog[prayerTriggerId] = prayerTriggerKey;
          await _reminderTriggerStorage.write(_triggerLog);
        }
      }
    } finally {
      _reminderCheckInProgress = false;
    }
  }

  Future<void> _triggerReminder({
    required Prayer prayer,
    required _PrayerRowSettings rowSettings,
    required AppLocalizations l10n,
    required _ReminderStage stage,
    required DateTime prayerTime,
  }) async {
    final prayerLabel = _prayerLabel(prayer, l10n);
    if (stage == _ReminderStage.prayer) {
      _stopVoiceLoop();
      _stopVisualLoop();
    }
    if (rowSettings.vibrationEnabled &&
        (stage == _ReminderStage.reminder || rowSettings.reminderMinutes > 0)) {
      await _playVibrationPulse(_reminderSettings.vibrationDurationSeconds * 1000);
      if (stage == _ReminderStage.reminder &&
          (rowSettings.voiceEnabled || rowSettings.visualEnabled)) {
        _startVibrationLoop(prayerLabel: prayerLabel);
      }
    }
    if (stage == _ReminderStage.prayer && rowSettings.azanEnabled) {
      await _reminderAudioService.playAlert();
    }
    if (stage == _ReminderStage.reminder &&
        rowSettings.voiceEnabled &&
        _canPlayVoiceReminder()) {
      try {
        await _reminderAudioService.playReminder(
          settings: _reminderSettings,
          selectedLocale: widget.localeController.value,
          prayerLabel: prayerLabel,
        );
        _startVoiceLoop(prayerLabel: prayerLabel, prayerTime: prayerTime);
      } catch (_) {}
    }
    if (stage == _ReminderStage.reminder &&
        rowSettings.visualEnabled &&
        mounted) {
      final visualText = _effectiveVisualReminderText();
      if (visualText.isEmpty) return;
      _startVisualLoop(
        prayerLabel: prayerLabel,
        message: visualText,
        prayerTime: prayerTime,
      );
    }
  }

  bool _canPlayVoiceReminder() {
    switch (_reminderSettings.audioMode) {
      case ReminderAudioMode.textToSpeech:
        return _reminderSettings.voiceText.trim().isNotEmpty;
      case ReminderAudioMode.deviceAudio:
      case ReminderAudioMode.mp3File:
        return (_reminderSettings.selectedAudioPath ?? '').trim().isNotEmpty;
    }
  }

  String _effectiveVisualReminderText() {
    final visualText = _reminderSettings.visualText.trim();
    if (visualText.isNotEmpty) {
      return visualText;
    }
    return _reminderSettings.voiceText.trim();
  }

  String _prayerLabel(Prayer prayer, AppLocalizations l10n) {
    switch (prayer) {
      case Prayer.none:
        return '';
      case Prayer.fajr:
        return l10n.prayerFajr;
      case Prayer.sunrise:
        return l10n.prayerSunrise;
      case Prayer.dhuhr:
        return l10n.prayerDhuhr;
      case Prayer.asr:
        return l10n.prayerAsr;
      case Prayer.maghrib:
        return l10n.prayerMaghrib;
      case Prayer.isha:
        return l10n.prayerIsha;
    }
  }

  String _triggerId(Prayer prayer, String stage) => '${prayer.name}|$stage';

  String _triggerKey(
    Prayer prayer,
    String stage,
    DateTime reminderTime,
    DateTime prayerTime,
  ) {
    String two(int value) => value.toString().padLeft(2, '0');
    final reminderStamp =
        '${reminderTime.year}${two(reminderTime.month)}${two(reminderTime.day)}'
        '${two(reminderTime.hour)}${two(reminderTime.minute)}';
    final prayerStamp = '${two(prayerTime.hour)}${two(prayerTime.minute)}';
    return '${prayer.name}|$stage|$reminderStamp|$prayerStamp';
  }

  _PrayerRowSettings _settingsFor(Prayer prayer) {
    return _rowSettings.putIfAbsent(prayer, () {
      final minutes = _defaultReminderMinutes(prayer);
      _reminderControllers.putIfAbsent(
        prayer,
        () => TextEditingController(text: minutes.toString()),
      );
      return _PrayerRowSettings(reminderMinutes: minutes);
    });
  }

  Future<void> _loadPrayerRowSettings() async {
    final saved = await _rowSettingsStorage.read();
    if (!mounted || saved.isEmpty) return;
    setState(() {
      for (final entry in saved.entries) {
        _rowSettings[entry.key] = _PrayerRowSettings(
          reminderMinutes: entry.value.reminderMinutes,
          voiceEnabled: entry.value.voiceEnabled,
          visualEnabled: entry.value.visualEnabled,
          azanEnabled: entry.value.azanEnabled,
          vibrationEnabled: entry.value.vibrationEnabled,
        );
        final controller = _reminderControllers[entry.key];
        if (controller != null) {
          controller.text = entry.value.reminderMinutes.toString();
        }
      }
    });
  }

  Future<void> _persistPrayerRowSettings() {
    final payload = <Prayer, PrayerRowSettingsRecord>{};
    for (final entry in _rowSettings.entries) {
      payload[entry.key] = PrayerRowSettingsRecord(
        reminderMinutes: entry.value.reminderMinutes,
        voiceEnabled: entry.value.voiceEnabled,
        visualEnabled: entry.value.visualEnabled,
        azanEnabled: entry.value.azanEnabled,
        vibrationEnabled: entry.value.vibrationEnabled,
      );
    }
    return _rowSettingsStorage.write(payload);
  }

  int _defaultReminderMinutes(Prayer prayer) {
    return prayer == Prayer.sunrise ? 0 : 15;
  }

  TextEditingController _controllerFor(Prayer prayer) {
    final settings = _settingsFor(prayer);
    return _reminderControllers.putIfAbsent(
      prayer,
      () => TextEditingController(text: settings.reminderMinutes.toString()),
    );
  }

  void _setReminderMinutes(Prayer prayer, String value) {
    final minutes = int.tryParse(value) ?? 0;
    setState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(reminderMinutes: minutes);
    });
    unawaited(_persistPrayerRowSettings());
  }

  void _toggleVoiceReminder(Prayer prayer) {
    setState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(voiceEnabled: !current.voiceEnabled);
    });
    unawaited(_persistPrayerRowSettings());
  }

  void _toggleVisualReminder(Prayer prayer) {
    setState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(visualEnabled: !current.visualEnabled);
    });
    unawaited(_persistPrayerRowSettings());
  }

  void _toggleAzanReminder(Prayer prayer) {
    setState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(azanEnabled: !current.azanEnabled);
    });
    unawaited(_persistPrayerRowSettings());
  }

  void _toggleVibrationReminder(Prayer prayer) {
    setState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(
        vibrationEnabled: !current.vibrationEnabled,
      );
    });
    unawaited(_persistPrayerRowSettings());
  }

  List<_PrayerItem> _buildItems(AppLocalizations l10n, PrayerTimes times) {
    _PrayerItem itemFor(Prayer prayer, String label, DateTime time) {
      final settings = _settingsFor(prayer);
      return _PrayerItem(
        prayer: prayer,
        label: label,
        time: time,
        reminderMinutes: settings.reminderMinutes,
        reminderController: _controllerFor(prayer),
        voiceEnabled: settings.voiceEnabled,
        visualEnabled: settings.visualEnabled,
        azanEnabled: settings.azanEnabled,
        vibrationEnabled: settings.vibrationEnabled,
      );
    }

    return [
      itemFor(Prayer.fajr, l10n.prayerFajr, times.fajr),
      itemFor(Prayer.sunrise, l10n.prayerSunrise, times.sunrise),
      itemFor(Prayer.dhuhr, l10n.prayerDhuhr, times.dhuhr),
      itemFor(Prayer.asr, l10n.prayerAsr, times.asr),
      itemFor(Prayer.maghrib, l10n.prayerMaghrib, times.maghrib),
      itemFor(Prayer.isha, l10n.prayerIsha, times.isha),
    ];
  }
}

class _HomeData {
  final LocationData? location;
  final String? methodCode;
  final PrayerTimes? times;
  final String? error;

  _HomeData({
    required this.location,
    required this.methodCode,
    this.times,
    this.error,
  });
}

class _PrayerItem {
  final Prayer prayer;
  final String label;
  final DateTime time;
  final int reminderMinutes;
  final TextEditingController reminderController;
  final bool voiceEnabled;
  final bool visualEnabled;
  final bool azanEnabled;
  final bool vibrationEnabled;

  _PrayerItem({
    required this.prayer,
    required this.label,
    required this.time,
    required this.reminderMinutes,
    required this.reminderController,
    required this.voiceEnabled,
    required this.visualEnabled,
    required this.azanEnabled,
    required this.vibrationEnabled,
  });
}

class _PrayerRowSettings {
  final int reminderMinutes;
  final bool voiceEnabled;
  final bool visualEnabled;
  final bool azanEnabled;
  final bool vibrationEnabled;

  const _PrayerRowSettings({
    required this.reminderMinutes,
    this.voiceEnabled = false,
    this.visualEnabled = false,
    this.azanEnabled = false,
    this.vibrationEnabled = false,
  });

  _PrayerRowSettings copyWith({
    int? reminderMinutes,
    bool? voiceEnabled,
    bool? visualEnabled,
    bool? azanEnabled,
    bool? vibrationEnabled,
  }) {
    return _PrayerRowSettings(
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      visualEnabled: visualEnabled ?? this.visualEnabled,
      azanEnabled: azanEnabled ?? this.azanEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }
}

enum _ReminderStage { reminder, prayer }

class _PrayerNext {
  final String label;
  final DateTime time;

  _PrayerNext({required this.label, required this.time});
}

class _HijriDate {
  final int year;
  final int month;
  final int day;

  const _HijriDate({required this.year, required this.month, required this.day});
}

class _TopPanel extends StatelessWidget {
  final String provinceLabel;
  final String districtLabel;
  final String nextLabel;
  final String nextTime;
  final String countdown;
  final String dateYearLabel;
  final String dateDayMonthLabel;
  final String timeLabel;
  final VoidCallback onToggleDate;
  final VoidCallback onLocationTap;
  final VoidCallback onQibla;
  final VoidCallback onSettings;
  final SurfaceStyle style;
  final EdgeInsets padding;
  final double settingsIconSize;
  final double settingsIconBoxSize;
  final double settingsIconOpacity;
  final HomeTypography typography;
  final Color cizgiColor;

  const _TopPanel({
    required this.provinceLabel,
    required this.districtLabel,
    required this.nextLabel,
    required this.nextTime,
    required this.countdown,
    required this.dateYearLabel,
    required this.dateDayMonthLabel,
    required this.timeLabel,
    required this.onToggleDate,
    required this.onLocationTap,
    required this.onQibla,
    required this.onSettings,
    required this.style,
    required this.padding,
    required this.settingsIconSize,
    required this.settingsIconBoxSize,
    required this.settingsIconOpacity,
    required this.typography,
    required this.cizgiColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowerSectionHeight = typography.nextTimeSize + typography.nextLabelSize + 20;
    final topRowHeight = settingsIconBoxSize > typography.locationSize + 8
        ? settingsIconBoxSize
        : typography.locationSize + 8;
    final locationTextStyle = theme.textTheme.titleMedium?.copyWith(
      color: cizgiColor,
      fontWeight: FontWeight.w500,
      fontSize: typography.locationSize,
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: style.borderRadius,
        boxShadow: style.shadows,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: topRowHeight,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: onLocationTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: cizgiColor,
                          size: typography.locationSize + 1,
                        ),
                        const SizedBox(width: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: provinceLabel, style: locationTextStyle),
                              if (districtLabel.trim().isNotEmpty) ...[
                                TextSpan(text: ' / ', style: locationTextStyle),
                                TextSpan(
                                  text: districtLabel,
                                  style: locationTextStyle?.copyWith(
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Transform.translate(
                    offset: const Offset(-38, 4),
                    child: IconButton(
                      onPressed: onQibla,
                      icon: Icon(
                        Icons.explore_outlined,
                        color: cizgiColor.withValues(alpha: 0.92),
                        size: settingsIconSize * 1.2,
                      ),
                      tooltip: 'Kıble Yönü',
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: settingsIconBoxSize,
                        minHeight: settingsIconBoxSize,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: const Offset(13, 0),
                    child: IconButton(
                      onPressed: onSettings,
                      icon: Icon(
                        Icons.settings_outlined,
                        color: cizgiColor.withValues(alpha: settingsIconOpacity),
                        size: settingsIconSize * 1.3,
                      ),
                      tooltip: AppLocalizations.of(context)!.settingsTitle,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(
                        minWidth: settingsIconBoxSize,
                        minHeight: settingsIconBoxSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            color: cizgiColor.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: lowerSectionHeight,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onToggleDate,
                        child: Text(
                          '$dateDayMonthLabel $dateYearLabel',
                          style: theme.textTheme.titleSmall?.copyWith(
                                color: cizgiColor,
                                fontWeight: FontWeight.w600,
                                fontSize: (typography.methodSize + 1) * 1.2,
                              ),
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                              color: cizgiColor.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w300,
                              fontSize: typography.nextLabelSize * 1.2,
                            ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: const Alignment(1 / 3, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nextLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                                  color: cizgiColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: typography.nextLabelSize,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            nextTime,
                            style: theme.textTheme.titleSmall?.copyWith(
                                  color: cizgiColor.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w300,
                                  fontSize: typography.nextLabelSize,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        countdown,
                        style: theme.textTheme.headlineSmall?.copyWith(
                              color: cizgiColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              fontSize: typography.nextTimeSize,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerList extends StatelessWidget {
  final List<_PrayerItem> items;
  final Prayer active;
  final String Function(DateTime) timeFormat;
  final SurfaceStyle style;
  final EdgeInsets listPadding;
  final double rowGap;
  final InlineIconStyle iconStyle;
  final InlineChipStyle chipStyle;
  final HomeTypography typography;
  final Color cizgiColor;
  final Color activeColor;
  final bool showVoiceIcon;
  final bool showVisualIcon;
  final bool showAzanIcon;
  final bool showVibrationIcon;
  final void Function(Prayer prayer, String value) onReminderChanged;
  final void Function(Prayer prayer) onVoiceToggle;
  final void Function(Prayer prayer) onVisualToggle;
  final void Function(Prayer prayer) onAzanToggle;
  final void Function(Prayer prayer) onVibrationToggle;

  const _PrayerList({
    required this.items,
    required this.active,
    required this.timeFormat,
    required this.style,
    required this.listPadding,
    required this.rowGap,
    required this.iconStyle,
    required this.chipStyle,
    required this.typography,
    required this.cizgiColor,
    required this.activeColor,
    required this.showVoiceIcon,
    required this.showVisualIcon,
    required this.showAzanIcon,
    required this.showVibrationIcon,
    required this.onReminderChanged,
    required this.onVoiceToggle,
    required this.onVisualToggle,
    required this.onAzanToggle,
    required this.onVibrationToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: style.borderRadius,
        boxShadow: style.shadows,
      ),
      child: ListView.separated(
        padding: listPadding,
        itemBuilder: (context, index) {
          final item = items[index];
          final activeIndex = items.indexWhere((entry) => entry.prayer == active);
          final isPast = activeIndex != -1 && index < activeIndex;
          final isActive = item.prayer == active;
          final labelColor = isActive
              ? cizgiColor
              : isPast
                  ? cizgiColor.withValues(alpha: 0.45)
                  : cizgiColor;
          final timeColor = isActive
              ? cizgiColor.withValues(alpha: 0.9)
              : isPast
                  ? cizgiColor.withValues(alpha: 0.5)
                  : cizgiColor.withValues(alpha: 0.9);
          final controlColor = cizgiColor;
          final chipBackgroundColor = isActive
              ? activeColor.withValues(alpha: 0.12)
              : chipStyle.backgroundColor;
          final chipBorderColor = isActive
              ? activeColor.withValues(alpha: 0.45)
              : chipStyle.borderColor;
          final visibleIconCount = [
            showVoiceIcon,
            showVisualIcon,
            showAzanIcon,
            showVibrationIcon,
          ].where((isVisible) => isVisible).length;
          final hiddenIconCount = 4 - visibleIconCount;
          final dynamicIconGap =
              rowGap + (4 - visibleIconCount).clamp(0, 3).toDouble();
          final trailingCompensation = hiddenIconCount * 12.0;
          final iconWidgets = <Widget>[];

          void addIcon(Widget widget) {
            if (iconWidgets.isNotEmpty) {
              iconWidgets.add(SizedBox(width: dynamicIconGap));
            }
            iconWidgets.add(widget);
          }

          if (showVoiceIcon) {
            addIcon(
              _IconToggle(
                icon: Icons.volume_up_outlined,
                style: iconStyle,
                isEnabled: item.voiceEnabled,
                cizgiColor: controlColor,
                onTap: () => onVoiceToggle(item.prayer),
              ),
            );
          }
          if (showVisualIcon) {
            addIcon(
              _IconToggle(
                icon: Icons.desktop_windows_outlined,
                style: iconStyle,
                isEnabled: item.visualEnabled,
                cizgiColor: controlColor,
                onTap: () => onVisualToggle(item.prayer),
              ),
            );
          }
          if (showAzanIcon) {
            addIcon(
              _IconToggle(
                icon: Icons.mosque_outlined,
                style: iconStyle,
                isEnabled: item.azanEnabled,
                cizgiColor: controlColor,
                onTap: () => onAzanToggle(item.prayer),
              ),
            );
          }
          if (showVibrationIcon) {
            addIcon(
              _IconToggle(
                icon: Icons.vibration_outlined,
                style: iconStyle,
                isEnabled: item.vibrationEnabled,
                cizgiColor: controlColor,
                onTap: () => onVibrationToggle(item.prayer),
              ),
            );
          }
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isActive
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: labelColor,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w300,
                          fontSize: typography.nextLabelSize,
                        ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeFormat(item.time),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: timeColor,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                            fontSize: typography.nextLabelSize,
                          ),
                    ),
                    const SizedBox(width: 5),
                    _ReminderChip(
                      controller: item.reminderController,
                      style: chipStyle,
                      cizgiColor: controlColor,
                      backgroundColor: chipBackgroundColor,
                      borderColor: chipBorderColor,
                      onChanged: (value) => onReminderChanged(item.prayer, value),
                    ),
                    if (iconWidgets.isNotEmpty) SizedBox(width: rowGap),
                    ...iconWidgets,
                    if (trailingCompensation > 0)
                      SizedBox(width: trailingCompensation),
                  ],
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: Color(0x22000000),
        ),
        itemCount: items.length,
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final TextEditingController controller;
  final InlineChipStyle style;
  final Color cizgiColor;
  final Color backgroundColor;
  final Color borderColor;
  final ValueChanged<String> onChanged;

  const _ReminderChip({
    required this.controller,
    required this.style,
    required this.cizgiColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: style.width,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cizgiColor,
              fontWeight: FontWeight.w700,
              fontSize: style.fontSize,
            ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: backgroundColor,
          contentPadding: EdgeInsets.symmetric(vertical: style.verticalPadding),
          enabledBorder: OutlineInputBorder(
            borderRadius: style.borderRadius,
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: style.borderRadius,
            borderSide: BorderSide(color: cizgiColor),
          ),
        ),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final InlineIconStyle style;
  final bool isEnabled;
  final Color cizgiColor;
  final VoidCallback onTap;

  const _IconToggle({
    required this.icon,
    required this.style,
    required this.isEnabled,
    required this.cizgiColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isEnabled ? cizgiColor : cizgiColor.withValues(alpha: 0.4);
    final hitSize = style.size * 1.3;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: Center(
          child: Icon(icon, size: style.iconSize, color: iconColor),
        ),
      ),
    );
  }
}

class _ActiveReminderPanel extends StatelessWidget {
  final String? voicePrayerLabel;
  final String? visualPrayerLabel;
  final String? visualMessage;
  final bool showVisualCard;
  final VoidCallback onCloseVoice;
  final VoidCallback onCloseVisual;

  const _ActiveReminderPanel({
    required this.voicePrayerLabel,
    required this.visualPrayerLabel,
    required this.visualMessage,
    required this.showVisualCard,
    required this.onCloseVoice,
    required this.onCloseVisual,
  });

  String _toTurkishUpper(String value) {
    return value
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasVoice = (voicePrayerLabel ?? '').trim().isNotEmpty;
    final hasVisual = (visualPrayerLabel ?? '').trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasVisual && showVisualCard) ...[
          FlashingReminderCard(
            prayerLabel: '${_toTurkishUpper(visualPrayerLabel!)} VAKTİ',
            message: visualMessage ?? '',
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              if (hasVoice)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCloseVoice,
                    icon: const Icon(Icons.volume_off_outlined),
                    label: Text('${voicePrayerLabel!} Sesli Kapat'),
                  ),
                ),
              if (hasVoice && hasVisual) const SizedBox(width: 8),
              if (hasVisual)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCloseVisual,
                    icon: const Icon(Icons.close_fullscreen_outlined),
                    label: Text('${visualPrayerLabel!} Görsel Kapat'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollapsedHint extends StatelessWidget {
  final String label;
  final String value;

  const _CollapsedHint({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1E6D3C),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _QiblaScreen extends StatelessWidget {
  static const double _kaabaLatitude = 21.4225;
  static const double _kaabaLongitude = 39.8262;

  final LocationData? location;

  const _QiblaScreen({required this.location});

  double? _parse(String? value) => double.tryParse((value ?? '').trim());

  double _bearingToKaaba(double latitude, double longitude) {
    final lat1 = _degToRad(latitude);
    final lon1 = _degToRad(longitude);
    final lat2 = _degToRad(_kaabaLatitude);
    final lon2 = _degToRad(_kaabaLongitude);
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (_radToDeg(math.atan2(y, x)) + 360) % 360;
  }

  double _degToRad(double deg) => deg * math.pi / 180;
  double _radToDeg(double rad) => rad * 180 / math.pi;

  @override
  Widget build(BuildContext context) {
    final latitude = _parse(location?.latitude);
    final longitude = _parse(location?.longitude);
    final hasLocation = latitude != null && longitude != null;
    final qiblaBearing = hasLocation ? _bearingToKaaba(latitude!, longitude!) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Kıble Yönü')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: !hasLocation
                ? const Text(
                    'Kıble yönü için önce konum seçin.',
                    textAlign: TextAlign.center,
                  )
                : StreamBuilder<CompassEvent>(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot) {
                      final heading = snapshot.data?.heading;
                      if (heading == null) {
                        return const Text(
                          'Pusula verisi bekleniyor.',
                          textAlign: TextAlign.center,
                        );
                      }
                      final rotation = ((qiblaBearing! - heading) * math.pi) / 180;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF5F0E6),
                              border: Border.all(
                                color: const Color(0xFF1F7A3E).withValues(alpha: 0.22),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x16000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Text(
                                  'N',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Transform.rotate(
                                  angle: rotation,
                                  child: const Icon(
                                    Icons.navigation_rounded,
                                    size: 120,
                                    color: Color(0xFF1F7A3E),
                                  ),
                                ),
                                const Positioned(
                                  bottom: 22,
                                  child: Text(
                                    'Kâbe',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Kıble açısı: ${qiblaBearing.toStringAsFixed(1)}°',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Telefonu düz tutup yeşil oku takip edin.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
