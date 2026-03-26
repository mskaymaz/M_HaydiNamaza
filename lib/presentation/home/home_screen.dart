import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:intl/intl.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';

import '../../app/calculation_method_storage.dart';
import '../../app/custom_prayer_storage.dart';
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
  final _customPrayerStorage = CustomPrayerStorage();
  final _rowSettingsStorage = PrayerRowSettingsStorage();
  final _reminderTextStorage = ReminderTextSettingsStorage();
  final _reminderTriggerStorage = ReminderTriggerStorage();
  final _reminderAudioService = ReminderAudioService();
  final _prayerService = PrayerService();
  final Map<Prayer, _PrayerRowSettings> _rowSettings = {};
  final Map<Prayer, TextEditingController> _reminderControllers = {};
  final Map<String, String> _triggerLog = {};
  final List<_CustomPrayerDraft> _customPrayerRows = [];
  final ScrollController _prayerListScrollController = ScrollController();

  late Future<_HomeData> _future;
  Timer? _ticker;
  Timer? _voiceRepeatTimer;
  Timer? _visualCycleTimer;
  Timer? _vibrationRepeatTimer;
  DateTime _now = DateTime.now();
  DateTime _lastRefreshDay = DateTime.now();
  double _drawerProgress = 0;
  bool _showHijriDate = false;
  bool _reminderCheckInProgress = false;
  int _customPrayerSeed = 0;
  DateTime? _voiceLoopUntil;
  String? _voiceLoopPrayerLabel;
  DateTime? _visualLoopUntil;
  String? _visualLoopPrayerLabel;
  String? _visualLoopMessage;
  DateTime? _vibrationLoopUntil;
  String? _vibrationLoopPrayerLabel;
  bool _showVisualOverlay = false;
  ReminderTextSettings _reminderSettings = const ReminderTextSettings(
    voiceText: kDefaultVoiceReminderText,
    visualText: '',
  );

  @override
  void initState() {
    super.initState();
    _lastRefreshDay = DateTime(_now.year, _now.month, _now.day);
    unawaited(_loadPrayerRowSettings());
    unawaited(_loadCustomPrayerRows());
    unawaited(_loadReminderSettings());
    unawaited(_loadReminderTriggerLog());
    _future = _loadData();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final dayChanged =
          now.year != _lastRefreshDay.year ||
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
    _prayerListScrollController.dispose();
    for (final controller in _reminderControllers.values) {
      controller.dispose();
    }
    for (final row in _customPrayerRows) {
      row.labelController.dispose();
      row.reminderController.dispose();
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
    if (methodCode != 'turkey' &&
        methodCode != 'diyanet_tabanli' &&
        (lat == null || lon == null)) {
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

    return _HomeData(location: location, methodCode: methodCode, times: times);
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
  }

  void _stopVibrationLoop() {
    _vibrationRepeatTimer?.cancel();
    _vibrationRepeatTimer = null;
    if (_vibrationLoopUntil != null || _vibrationLoopPrayerLabel != null) {
      setState(() {
        _vibrationLoopUntil = null;
        _vibrationLoopPrayerLabel = null;
      });
    }
  }

  void _dismissVoiceReminder() {
    _stopVoiceLoop();
    _stopVibrationLoop();
  }

  void _dismissVisualReminder() {
    _stopVisualLoop();
    _stopVibrationLoop();
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
    _voiceRepeatTimer = Timer.periodic(Duration(seconds: repeatSeconds), (
      _,
    ) async {
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

  void _startVibrationLoop({
    required String prayerLabel,
    required DateTime prayerTime,
  }) {
    _vibrationRepeatTimer?.cancel();
    final vibrationOnMilliseconds =
        _reminderSettings.vibrationDurationSeconds * 1000;
    final vibrationRepeatMilliseconds =
        (_reminderSettings.vibrationPauseSeconds * 1000).clamp(1, 3600000);
    setState(() {
      _vibrationLoopUntil = prayerTime;
      _vibrationLoopPrayerLabel = prayerLabel;
    });
    _vibrationRepeatTimer = Timer.periodic(
      Duration(milliseconds: vibrationRepeatMilliseconds),
      (_) async {
        if (!mounted ||
            _vibrationLoopUntil == null ||
            DateTime.now().isAfter(_vibrationLoopUntil!)) {
          _stopVibrationLoop();
          return;
        }
        await _playVibrationPulse(vibrationOnMilliseconds);
      },
    );
  }

  Future<void> _playVibrationPulse(int durationMilliseconds) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
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
      if (!mounted ||
          _visualLoopUntil == null ||
          DateTime.now().isAfter(_visualLoopUntil!)) {
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
    final monthName = (hijri.month >= 1 && hijri.month <= 12)
        ? months[hijri.month - 1]
        : '';
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
    return value.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
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
        'Ù…Ø­Ø±Ù…',
        'ØµÙØ±',
        'Ø±Ø¨ÙŠØ¹ Ø§Ù„Ø£ÙˆÙ„',
        'Ø±Ø¨ÙŠØ¹ Ø§Ù„Ø¢Ø®Ø±',
        'Ø¬Ù…Ø§Ø¯Ù‰ Ø§Ù„Ø£ÙˆÙ„Ù‰',
        'Ø¬Ù…Ø§Ø¯Ù‰ Ø§Ù„Ø¢Ø®Ø±Ø©',
        'Ø±Ø¬Ø¨',
        'Ø´Ø¹Ø¨Ø§Ù†',
        'Ø±Ù…Ø¶Ø§Ù†',
        'Ø´ÙˆØ§Ù„',
        'Ø°Ùˆ Ø§Ù„Ù‚Ø¹Ø¯Ø©',
        'Ø°Ùˆ Ø§Ù„Ø­Ø¬Ø©',
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
      'RabiÊ» al-awwal',
      'RabiÊ» al-thani',
      'Jumada al-awwal',
      'Jumada al-thani',
      'Rajab',
      'ShaÊ»ban',
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
    final jd =
        d +
        ((153 * m2 + 2) / 5).floor() +
        365 * y2 +
        (y2 / 4).floor() -
        (y2 / 100).floor() +
        (y2 / 400).floor() -
        32045;
    var l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;
    final j =
        (((10985 - l) / 5316).floor()) * (((50 * l) / 17719).floor()) +
        (((l / 5670).floor()) * (((43 * l) / 15238).floor()));
    l =
        l -
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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _QiblaScreen(location: location)));
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
                  Text(l10n.locationNotSet, textAlign: TextAlign.center),
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
                  Text(l10n.locationFillAll, textAlign: TextAlign.center),
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
              child: Text(l10n.comingSoon, textAlign: TextAlign.center),
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
                      color: palette.backgroundCizgiColor.withValues(
                        alpha: 0.5,
                      ),
                      colorBlendMode: BlendMode.modulate,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: ui.screenPadding,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const panelOverlap = 15.0;
                        const handleAreaHeight = 22.0;
                        const minDrawerHeight = handleAreaHeight;
                        const maxDrawerHeightLimit = 320.0;
                        final topRowHeight = math.max(
                          ui.settingsIconBoxSize,
                          ui.typography.locationSize + 8,
                        );
                        final lowerSectionHeight =
                            ui.typography.nextTimeSize +
                            ui.typography.nextLabelSize +
                            20;
                        final topPanelHeight =
                            ui.topPanelPadding.vertical +
                            topRowHeight +
                            4 +
                            1 +
                            10 +
                            lowerSectionHeight;
                        final drawerTop = topPanelHeight - panelOverlap;
                        final availableDrawerSpace =
                            constraints.maxHeight - drawerTop;
                        final maxDrawerHeight = math.max(
                          minDrawerHeight,
                          math.min(
                            availableDrawerSpace,
                            maxDrawerHeightLimit,
                          ),
                        );
                        final drawerHeight =
                            minDrawerHeight +
                            ((maxDrawerHeight - minDrawerHeight) *
                                _drawerProgress);
                        final bandColor = Color.lerp(
                          ui.listPanel.color,
                          palette.zeminColor,
                          0.16,
                        )!;

                        void updateDrawerProgress(DragUpdateDetails details) {
                          final travel = (maxDrawerHeight - minDrawerHeight)
                              .clamp(1.0, double.infinity);
                          setState(() {
                            _drawerProgress = (_drawerProgress +
                                    (details.delta.dy / travel))
                                .clamp(0.0, 1.0)
                                .toDouble();
                          });
                        }

                        void settleDrawerProgress(DragEndDetails details) {
                          final velocity = details.primaryVelocity ?? 0;
                          setState(() {
                            if (velocity > 250) {
                              _drawerProgress = 1;
                            } else if (velocity < -250) {
                              _drawerProgress = 0;
                            } else {
                              _drawerProgress = _drawerProgress >= 0.35 ? 1 : 0;
                            }
                          });
                        }

                        Widget buildHandleBand({
                          required bool pointUp,
                          Border? border,
                        }) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _toggleDrawer,
                            onVerticalDragUpdate: updateDrawerProgress,
                            onVerticalDragEnd: settleDrawerProgress,
                            child: Container(
                              height: handleAreaHeight,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    bandColor.withValues(alpha: 0.98),
                                    ui.listPanel.color,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: border,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                    ),
                                  ),
                                  CustomPaint(
                                    size: const Size(78, 12),
                                    painter: _DrawerHandlePainter(
                                      color: palette.cizgiColor.withValues(
                                        alpha: 0.8,
                                      ),
                                      pointUp: pointUp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: drawerTop,
                              left: 0,
                              right: 0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                height: drawerHeight,
                                decoration: BoxDecoration(
                                  color: ui.listPanel.color,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    if (_drawerProgress > 0.02)
                                      SizedBox(height: panelOverlap + 12),
                                    if (_drawerProgress > 0.02)
                                      Expanded(
                                        child: _PrayerList(
                                          controller:
                                              _prayerListScrollController,
                                          items: items,
                                          active: active,
                                          style: ui.listPanel,
                                          listPadding: ui.listPadding,
                                          rowGap: ui.rowGap,
                                          iconStyle: ui.iconToggle,
                                          chipStyle: ui.reminderChip,
                                          typography: ui.typography,
                                          cizgiColor: palette.cizgiColor,
                                          activeColor: palette.zeminColor,
                                          showVoiceIcon:
                                              _reminderSettings.showVoiceIcon,
                                          showVisualIcon:
                                              _reminderSettings.showVisualIcon,
                                          showAzanIcon:
                                              _reminderSettings.showAzanIcon,
                                          showVibrationIcon:
                                              _reminderSettings
                                                  .showVibrationIcon,
                                          onAddCustomPrayer:
                                              _addCustomPrayerRow,
                                        ),
                                      ),
                                    if (_drawerProgress > 0.02)
                                      buildHandleBand(
                                        pointUp: true,
                                        border: Border(
                                          top: BorderSide(
                                            color: palette.cizgiColor
                                                .withValues(alpha: 0.12),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (_drawerProgress <= 0.02)
                              Positioned(
                                top: topPanelHeight - 1,
                                left: 0,
                                right: 0,
                                child: buildHandleBand(
                                  pointUp: false,
                                  border: Border(
                                    top: BorderSide(
                                      color: palette.cizgiColor.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: GestureDetector(
                                onDoubleTap: _toggleDrawer,
                                child: _TopPanel(
                                  provinceLabel: provinceLabel,
                                  districtLabel: districtLabel,
                                  nextLabel: next.label,
                                  nextTime: nextTime,
                                  countdown: countdown,
                                  dateYearLabel: dateYearLabel,
                                  dateDayMonthLabel: dateDayMonthLabel,
                                  timeLabel: timeLabel,
                                  onToggleDate: () => setState(
                                    () => _showHijriDate = !_showHijriDate,
                                  ),
                                  onLocationTap: () =>
                                      _openLocationSettings(location),
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
                            ),
                          ],
                        );
                      },
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
                        onCloseVoice: _dismissVoiceReminder,
                        onCloseVisual: _dismissVisualReminder,
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

  _PrayerNext _nextPrayer(
    PrayerTimes times,
    DateTime now,
    AppLocalizations l10n,
  ) {
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
      await _playVibrationPulse(
        _reminderSettings.vibrationDurationSeconds * 1000,
      );
      if (stage == _ReminderStage.reminder) {
        _startVibrationLoop(prayerLabel: prayerLabel, prayerTime: prayerTime);
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
      final visualText = _effectiveVisualReminderText(prayerLabel);
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
        return true;
      case ReminderAudioMode.deviceAudio:
      case ReminderAudioMode.mp3File:
        return (_reminderSettings.selectedAudioPath ?? '').trim().isNotEmpty;
    }
  }

  String _effectiveVisualReminderText(String prayerLabel) {
    final visualText = _reminderSettings.visualText.trim();
    if (visualText.isNotEmpty) {
      return visualText;
    }
    final voiceText = _reminderSettings.voiceText.trim();
    if (voiceText.isNotEmpty) {
      return voiceText;
    }
    return '$prayerLabel vakti';
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

  Future<void> _loadCustomPrayerRows() async {
    final saved = await _customPrayerStorage.read();
    if (!mounted || saved.isEmpty) return;
    final loadedRows = <_CustomPrayerDraft>[];
    var maxSeed = _customPrayerSeed;
    for (final record in saved) {
      final manualTime =
          record.manualHour == null || record.manualMinute == null
          ? null
          : TimeOfDay(hour: record.manualHour!, minute: record.manualMinute!);
      loadedRows.add(
        _CustomPrayerDraft(
          id: record.id,
          labelController: TextEditingController(text: record.label),
          reminderController: TextEditingController(
            text: record.reminderMinutes.toString(),
          ),
          settings: _PrayerRowSettings(
            reminderMinutes: record.reminderMinutes,
            voiceEnabled: record.voiceEnabled,
            visualEnabled: record.visualEnabled,
            azanEnabled: record.azanEnabled,
            vibrationEnabled: record.vibrationEnabled,
          ),
          timeRule: _CustomPrayerTimeRule(
            mode: _customPrayerTimeModeFromKey(record.timeMode),
            anchorPrayer: record.anchorPrayer,
            secondaryAnchorPrayer: record.secondaryAnchorPrayer,
            offsetMinutes: record.offsetMinutes,
            manualTime: manualTime,
          ),
        ),
      );
      final match = RegExp(r'^nafile_(\d+)$').firstMatch(record.id);
      final seed = int.tryParse(match?.group(1) ?? '');
      if (seed != null && seed >= maxSeed) {
        maxSeed = seed + 1;
      }
    }
    setState(() {
      _customPrayerRows
        ..clear()
        ..addAll(loadedRows);
      _customPrayerSeed = maxSeed;
    });
  }

  Future<void> _persistCustomPrayerRows() {
    final payload = _customPrayerRows.map((row) {
      return CustomPrayerRecord(
        id: row.id,
        label: row.labelController.text.trim(),
        reminderMinutes: row.settings.reminderMinutes,
        voiceEnabled: row.settings.voiceEnabled,
        visualEnabled: row.settings.visualEnabled,
        azanEnabled: row.settings.azanEnabled,
        vibrationEnabled: row.settings.vibrationEnabled,
        timeMode: row.timeRule.mode.name,
        anchorPrayer: row.timeRule.anchorPrayer,
        secondaryAnchorPrayer: row.timeRule.secondaryAnchorPrayer,
        offsetMinutes: row.timeRule.offsetMinutes,
        manualHour: row.timeRule.manualTime?.hour,
        manualMinute: row.timeRule.manualTime?.minute,
      );
    }).toList();
    return _customPrayerStorage.write(payload);
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

  Future<void> _editReminderMinutes({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) async {
    final editController = TextEditingController(text: controller.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 150),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hatırlatma Süresi'),
              const SizedBox(height: 6),
              SizedBox(
                width: 112,
                child: Center(
                  child: SizedBox(
                    width: 72,
                    child: TextField(
                      controller: editController,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Dakika',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Vazgeç',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(editController.text),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Tamam',
                      icon: const Icon(Icons.check_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (result == null) return;
    final value = result.trim();
    controller.text = value.isEmpty ? '0' : value;
    onChanged(controller.text);
  }

  void _toggleVoiceReminder(Prayer prayer) {
    setState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(
        voiceEnabled: !current.voiceEnabled,
      );
    });
    unawaited(_persistPrayerRowSettings());
  }

  void _toggleVisualReminder(Prayer prayer) {
    setState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(
        visualEnabled: !current.visualEnabled,
      );
    });
    unawaited(_persistPrayerRowSettings());
  }

  void _toggleAzanReminder(Prayer prayer) {
    setState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(
        azanEnabled: !current.azanEnabled,
      );
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

  void _toggleDrawer() {
    setState(() {
      _drawerProgress = _drawerProgress > 0.35 ? 0 : 1;
    });
  }

  void _addCustomPrayerRow() {
    final label = 'Nafile ${_nextAvailableNafileIndex()}';
    final row = _CustomPrayerDraft(
      id: 'nafile_${_customPrayerSeed++}',
      labelController: TextEditingController(text: label),
      reminderController: TextEditingController(text: '15'),
      settings: const _PrayerRowSettings(reminderMinutes: 15),
      timeRule: const _CustomPrayerTimeRule(
        mode: _CustomPrayerTimeMode.manual,
        manualTime: null,
      ),
    );
    setState(() {
      _customPrayerRows.add(row);
      _drawerProgress = 1;
    });
    _scrollPrayerListToBottom();
    unawaited(_persistCustomPrayerRows());
  }

  void _scrollPrayerListToBottom([int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_prayerListScrollController.hasClients) {
        if (attempt < 4) {
          Future<void>.delayed(
            const Duration(milliseconds: 120),
            () => _scrollPrayerListToBottom(attempt + 1),
          );
        }
        return;
      }
      final maxScrollExtent =
          _prayerListScrollController.position.maxScrollExtent;
      _prayerListScrollController.animateTo(
        maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  int _nextAvailableNafileIndex({String? excludingId}) {
    final used = <int>{};
    final pattern = RegExp(r'^Nafile (\d+)$');
    for (final row in _customPrayerRows) {
      if (row.id == excludingId) continue;
      final match = pattern.firstMatch(row.labelController.text.trim());
      if (match != null) {
        used.add(int.parse(match.group(1)!));
      }
    }
    var candidate = 1;
    while (used.contains(candidate)) {
      candidate++;
    }
    return candidate;
  }

  void _setCustomPrayerLabel(_CustomPrayerDraft row, String value) {
    setState(() {});
    unawaited(_persistCustomPrayerRows());
  }

  void _normalizeCustomPrayerLabel(_CustomPrayerDraft row) {
    if (row.labelController.text.trim().isNotEmpty) return;
    final label = 'Nafile ${_nextAvailableNafileIndex(excludingId: row.id)}';
    row.labelController.text = label;
    row.labelController.selection = TextSelection.collapsed(
      offset: row.labelController.text.length,
    );
    setState(() {});
    unawaited(_persistCustomPrayerRows());
  }

  void _setCustomReminderMinutes(_CustomPrayerDraft row, String value) {
    final minutes = int.tryParse(value) ?? 0;
    setState(() {
      row.settings = row.settings.copyWith(reminderMinutes: minutes);
    });
    unawaited(_persistCustomPrayerRows());
  }

  void _toggleCustomVoice(_CustomPrayerDraft row) {
    setState(() {
      row.settings = row.settings.copyWith(
        voiceEnabled: !row.settings.voiceEnabled,
      );
    });
    unawaited(_persistCustomPrayerRows());
  }

  void _toggleCustomVisual(_CustomPrayerDraft row) {
    setState(() {
      row.settings = row.settings.copyWith(
        visualEnabled: !row.settings.visualEnabled,
      );
    });
    unawaited(_persistCustomPrayerRows());
  }

  void _toggleCustomAzan(_CustomPrayerDraft row) {
    setState(() {
      row.settings = row.settings.copyWith(
        azanEnabled: !row.settings.azanEnabled,
      );
    });
    unawaited(_persistCustomPrayerRows());
  }

  void _toggleCustomVibration(_CustomPrayerDraft row) {
    setState(() {
      row.settings = row.settings.copyWith(
        vibrationEnabled: !row.settings.vibrationEnabled,
      );
    });
    unawaited(_persistCustomPrayerRows());
  }

  void _removeCustomPrayerRow(_CustomPrayerDraft row) {
    setState(() {
      _customPrayerRows.removeWhere((entry) => entry.id == row.id);
    });
    row.labelController.dispose();
    row.reminderController.dispose();
    unawaited(_persistCustomPrayerRows());
  }

  DateTime _prayerTimeFor(Prayer prayer, PrayerTimes times) {
    switch (prayer) {
      case Prayer.fajr:
        return _atToday(times.fajr, _now);
      case Prayer.sunrise:
        return _atToday(times.sunrise, _now);
      case Prayer.dhuhr:
        return _atToday(times.dhuhr, _now);
      case Prayer.asr:
        return _atToday(times.asr, _now);
      case Prayer.maghrib:
        return _atToday(times.maghrib, _now);
      case Prayer.isha:
        return _atToday(times.isha, _now);
      case Prayer.none:
        return _now;
    }
  }

  DateTime? _resolveCustomPrayerTime(
    _CustomPrayerTimeRule rule,
    PrayerTimes times,
  ) {
    switch (rule.mode) {
      case _CustomPrayerTimeMode.manual:
        final manualTime = rule.manualTime;
        if (manualTime == null) return null;
        return DateTime(
          _now.year,
          _now.month,
          _now.day,
          manualTime.hour,
          manualTime.minute,
        );
      case _CustomPrayerTimeMode.beforePrayer:
        final anchor = rule.anchorPrayer;
        if (anchor == null) return null;
        return _prayerTimeFor(
          anchor,
          times,
        ).subtract(Duration(minutes: rule.offsetMinutes.abs()));
      case _CustomPrayerTimeMode.afterPrayer:
        final anchor = rule.anchorPrayer;
        if (anchor == null) return null;
        return _prayerTimeFor(
          anchor,
          times,
        ).add(Duration(minutes: rule.offsetMinutes.abs()));
      case _CustomPrayerTimeMode.midpointBetweenPrayers:
        final firstAnchor = rule.anchorPrayer;
        final secondAnchor = rule.secondaryAnchorPrayer;
        if (firstAnchor == null || secondAnchor == null) return null;
        final firstTime = _prayerTimeFor(firstAnchor, times);
        final secondTime = _prayerTimeFor(secondAnchor, times);
        final midpointMillis =
            firstTime.millisecondsSinceEpoch +
            ((secondTime.millisecondsSinceEpoch -
                    firstTime.millisecondsSinceEpoch) ~/
                2);
        return DateTime.fromMillisecondsSinceEpoch(midpointMillis);
    }
  }

  Future<void> _openCustomTimeEditor(
    _CustomPrayerDraft row,
    AppLocalizations l10n,
  ) async {
    var mode = row.timeRule.mode;
    var anchorPrayer = row.timeRule.anchorPrayer ?? Prayer.fajr;
    var secondaryAnchorPrayer =
        row.timeRule.secondaryAnchorPrayer ?? Prayer.sunrise;
    final prayerOptions = <MapEntry<Prayer, String>>[
      MapEntry(Prayer.fajr, l10n.prayerFajr),
      MapEntry(Prayer.sunrise, l10n.prayerSunrise),
      MapEntry(Prayer.dhuhr, l10n.prayerDhuhr),
      MapEntry(Prayer.asr, l10n.prayerAsr),
      MapEntry(Prayer.maghrib, l10n.prayerMaghrib),
      MapEntry(Prayer.isha, l10n.prayerIsha),
    ];
    final offsetController = TextEditingController(
      text: row.timeRule.offsetMinutes.toString(),
    );
    final hourController = TextEditingController(
      text: row.timeRule.manualTime == null
          ? ''
          : row.timeRule.manualTime!.hour.toString().padLeft(2, '0'),
    );
    final minuteController = TextEditingController(
      text: row.timeRule.manualTime == null
          ? ''
          : row.timeRule.manualTime!.minute.toString().padLeft(2, '0'),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vakit zamani',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Sabit saat'),
                        selected: mode == _CustomPrayerTimeMode.manual,
                        onSelected: (_) {
                          setSheetState(() {
                            mode = _CustomPrayerTimeMode.manual;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Vakitten once'),
                        selected: mode == _CustomPrayerTimeMode.beforePrayer,
                        onSelected: (_) {
                          setSheetState(() {
                            mode = _CustomPrayerTimeMode.beforePrayer;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Vakitten sonra'),
                        selected: mode == _CustomPrayerTimeMode.afterPrayer,
                        onSelected: (_) {
                          setSheetState(() {
                            mode = _CustomPrayerTimeMode.afterPrayer;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Iki vaktin ortasi'),
                        selected:
                            mode ==
                            _CustomPrayerTimeMode.midpointBetweenPrayers,
                        onSelected: (_) {
                          setSheetState(() {
                            mode = _CustomPrayerTimeMode.midpointBetweenPrayers;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (mode == _CustomPrayerTimeMode.manual)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hourController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Saat',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: minuteController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Dakika',
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (mode ==
                      _CustomPrayerTimeMode.midpointBetweenPrayers) ...[
                    Text(
                      'Birinci vakit',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in prayerOptions)
                          ChoiceChip(
                            label: Text(option.value),
                            selected: anchorPrayer == option.key,
                            onSelected: (_) {
                              setSheetState(() {
                                anchorPrayer = option.key;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ikinci vakit',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in prayerOptions)
                          ChoiceChip(
                            label: Text(option.value),
                            selected: secondaryAnchorPrayer == option.key,
                            onSelected: (_) {
                              setSheetState(() {
                                secondaryAnchorPrayer = option.key;
                              });
                            },
                          ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'Referans vakit',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in prayerOptions)
                          ChoiceChip(
                            label: Text(option.value),
                            selected: anchorPrayer == option.key,
                            onSelected: (_) {
                              setSheetState(() {
                                anchorPrayer = option.key;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: offsetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Dakika'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: Size(52, 28),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
                      onPressed: () {
                        final hour = int.tryParse(hourController.text.trim());
                        final minute = int.tryParse(
                          minuteController.text.trim(),
                        );
                        final offsetMinutes =
                            int.tryParse(offsetController.text.trim()) ?? 0;
                        setState(() {
                          row.timeRule = _CustomPrayerTimeRule(
                            mode: mode,
                            anchorPrayer: mode == _CustomPrayerTimeMode.manual
                                ? null
                                : anchorPrayer,
                            secondaryAnchorPrayer:
                                mode ==
                                    _CustomPrayerTimeMode.midpointBetweenPrayers
                                ? secondaryAnchorPrayer
                                : null,
                            offsetMinutes: offsetMinutes,
                            manualTime: mode == _CustomPrayerTimeMode.manual
                                ? (hour == null ||
                                          minute == null ||
                                          hour < 0 ||
                                          hour > 23 ||
                                          minute < 0 ||
                                          minute > 59
                                      ? null
                                      : TimeOfDay(hour: hour, minute: minute))
                                : null,
                          );
                        });
                        unawaited(_persistCustomPrayerRows());
                        Navigator.of(context).pop();
                      },
                      child: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    offsetController.dispose();
    hourController.dispose();
    minuteController.dispose();
  }

  List<_PrayerItem> _buildItems(AppLocalizations l10n, PrayerTimes times) {
    _PrayerItem itemFor(Prayer prayer, String label, DateTime time) {
      final settings = _settingsFor(prayer);
      return _PrayerItem(
        id: prayer.name,
        prayer: prayer,
        label: label,
        sortTime: time,
        timeLabel: _formatTime(time),
        reminderController: _controllerFor(prayer),
        onReminderChanged: (value) => _setReminderMinutes(prayer, value),
        onReminderTap: () => _editReminderMinutes(
          controller: _controllerFor(prayer),
          onChanged: (value) => _setReminderMinutes(prayer, value),
        ),
        voiceEnabled: settings.voiceEnabled,
        visualEnabled: settings.visualEnabled,
        azanEnabled: settings.azanEnabled,
        vibrationEnabled: settings.vibrationEnabled,
        onVoiceToggle: () => _toggleVoiceReminder(prayer),
        onVisualToggle: () => _toggleVisualReminder(prayer),
        onAzanToggle: () => _toggleAzanReminder(prayer),
        onVibrationToggle: () => _toggleVibrationReminder(prayer),
      );
    }

    final items = [
      itemFor(Prayer.fajr, l10n.prayerFajr, times.fajr),
      itemFor(Prayer.sunrise, l10n.prayerSunrise, times.sunrise),
      itemFor(Prayer.dhuhr, l10n.prayerDhuhr, times.dhuhr),
      itemFor(Prayer.asr, l10n.prayerAsr, times.asr),
      itemFor(Prayer.maghrib, l10n.prayerMaghrib, times.maghrib),
      itemFor(Prayer.isha, l10n.prayerIsha, times.isha),
    ];

    for (final row in _customPrayerRows) {
      final resolvedTime = _resolveCustomPrayerTime(row.timeRule, times);
      items.add(
        _PrayerItem(
          id: row.id,
          prayer: null,
          label: row.labelController.text.trim(),
          sortTime: resolvedTime,
          labelController: row.labelController,
          onLabelChanged: (value) => _setCustomPrayerLabel(row, value),
          onLabelEditingComplete: () => _normalizeCustomPrayerLabel(row),
          timeLabel: resolvedTime == null ? '--:--' : _formatTime(resolvedTime),
          onTimeTap: () => _openCustomTimeEditor(row, l10n),
          reminderController: row.reminderController,
          onReminderChanged: (value) => _setCustomReminderMinutes(row, value),
          onReminderTap: () => _editReminderMinutes(
            controller: row.reminderController,
            onChanged: (value) => _setCustomReminderMinutes(row, value),
          ),
          voiceEnabled: row.settings.voiceEnabled,
          visualEnabled: row.settings.visualEnabled,
          azanEnabled: row.settings.azanEnabled,
          vibrationEnabled: row.settings.vibrationEnabled,
          onVoiceToggle: () => _toggleCustomVoice(row),
          onVisualToggle: () => _toggleCustomVisual(row),
          onAzanToggle: () => _toggleCustomAzan(row),
          onVibrationToggle: () => _toggleCustomVibration(row),
          onDelete: () => _removeCustomPrayerRow(row),
        ),
      );
    }

    if (!_reminderSettings.sortCustomPrayersByTime) {
      return items;
    }

    final ordered = List<_PrayerItem>.from(items);
    ordered.sort((a, b) {
      final aTime = a.sortTime;
      final bTime = b.sortTime;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      final compare = aTime.compareTo(bTime);
      if (compare != 0) return compare;
      if (a.prayer != null && b.prayer == null) return -1;
      if (a.prayer == null && b.prayer != null) return 1;
      return a.label.compareTo(b.label);
    });
    return ordered;
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
  final String id;
  final Prayer? prayer;
  final String label;
  final DateTime? sortTime;
  final TextEditingController? labelController;
  final ValueChanged<String>? onLabelChanged;
  final VoidCallback? onLabelEditingComplete;
  final String timeLabel;
  final VoidCallback? onTimeTap;
  final TextEditingController reminderController;
  final ValueChanged<String> onReminderChanged;
  final VoidCallback onReminderTap;
  final bool voiceEnabled;
  final bool visualEnabled;
  final bool azanEnabled;
  final bool vibrationEnabled;
  final VoidCallback onVoiceToggle;
  final VoidCallback onVisualToggle;
  final VoidCallback onAzanToggle;
  final VoidCallback onVibrationToggle;
  final VoidCallback? onDelete;

  _PrayerItem({
    required this.id,
    required this.prayer,
    required this.label,
    this.sortTime,
    this.labelController,
    this.onLabelChanged,
    this.onLabelEditingComplete,
    required this.timeLabel,
    this.onTimeTap,
    required this.reminderController,
    required this.onReminderChanged,
    required this.onReminderTap,
    required this.voiceEnabled,
    required this.visualEnabled,
    required this.azanEnabled,
    required this.vibrationEnabled,
    required this.onVoiceToggle,
    required this.onVisualToggle,
    required this.onAzanToggle,
    required this.onVibrationToggle,
    this.onDelete,
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

class _CustomPrayerDraft {
  final String id;
  final TextEditingController labelController;
  final TextEditingController reminderController;
  _PrayerRowSettings settings;
  _CustomPrayerTimeRule timeRule;

  _CustomPrayerDraft({
    required this.id,
    required this.labelController,
    required this.reminderController,
    required this.settings,
    required this.timeRule,
  });
}

enum _CustomPrayerTimeMode {
  manual,
  beforePrayer,
  afterPrayer,
  midpointBetweenPrayers,
}

_CustomPrayerTimeMode _customPrayerTimeModeFromKey(String key) {
  for (final mode in _CustomPrayerTimeMode.values) {
    if (mode.name == key) return mode;
  }
  return _CustomPrayerTimeMode.manual;
}

class _CustomPrayerTimeRule {
  final _CustomPrayerTimeMode mode;
  final Prayer? anchorPrayer;
  final Prayer? secondaryAnchorPrayer;
  final int offsetMinutes;
  final TimeOfDay? manualTime;

  const _CustomPrayerTimeRule({
    required this.mode,
    this.anchorPrayer,
    this.secondaryAnchorPrayer,
    this.offsetMinutes = 0,
    this.manualTime,
  });
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

  const _HijriDate({
    required this.year,
    required this.month,
    required this.day,
  });
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
    final lowerSectionHeight =
        typography.nextTimeSize + typography.nextLabelSize + 20;
    final topRowHeight = settingsIconBoxSize > typography.locationSize + 8
        ? settingsIconBoxSize
        : typography.locationSize + 8;
    final locationTextStyle = theme.textTheme.titleMedium?.copyWith(
      color: cizgiColor,
      fontWeight: FontWeight.w500,
      fontSize: typography.locationSize,
    );
    final dateTextStyle = theme.textTheme.titleSmall?.copyWith(
      color: cizgiColor,
      fontWeight: FontWeight.w600,
      fontSize: (typography.methodSize + 1) * 1.2,
      letterSpacing: -0.2,
    );
    final clockTextStyle = theme.textTheme.titleSmall?.copyWith(
      color: cizgiColor.withValues(alpha: 0.85),
      fontWeight: FontWeight.w300,
      fontSize: typography.nextLabelSize * 1.2,
      letterSpacing: -0.6,
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
                              TextSpan(
                                text: provinceLabel,
                                style: locationTextStyle,
                              ),
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
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: const Offset(13, 0),
                    child: IconButton(
                      onPressed: onSettings,
                      icon: Icon(
                        Icons.settings_outlined,
                        color: cizgiColor.withValues(
                          alpha: settingsIconOpacity,
                        ),
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
          Container(height: 1, color: cizgiColor.withValues(alpha: 0.18)),
          const SizedBox(height: 10),
          SizedBox(
            height: lowerSectionHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompactWidth = constraints.maxWidth < 420;
                final leftSlotWidth = isCompactWidth
                    ? 88.0
                    : math.min(
                        math.max(constraints.maxWidth * 0.27, 108.0),
                        160.0,
                      );
                final rightSlotWidth = isCompactWidth
                    ? 64.0
                    : leftSlotWidth;
                final qiblaOffsetX = isCompactWidth ? 4.0 : 13.0;

                return Row(
                  children: [
                    SizedBox(
                      width: leftSlotWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: leftSlotWidth,
                              child: GestureDetector(
                                onTap: onToggleDate,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$dateDayMonthLabel $dateYearLabel',
                                    style: dateTextStyle,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              timeLabel,
                              style: clockTextStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
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
                    ),
                    SizedBox(
                      width: rightSlotWidth,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Transform.translate(
                          offset: Offset(qiblaOffsetX, 0),
                          child: IconButton(
                            onPressed: onQibla,
                            icon: Icon(
                              Icons.explore_outlined,
                              color: cizgiColor.withValues(alpha: 0.92),
                              size: settingsIconSize * 2.16,
                            ),
                            tooltip: 'Kıble Yönü',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: settingsIconBoxSize * 1.5,
                              minHeight: settingsIconBoxSize * 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerList extends StatelessWidget {
  final ScrollController controller;
  final List<_PrayerItem> items;
  final Prayer active;
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
  final VoidCallback onAddCustomPrayer;

  const _PrayerList({
    required this.controller,
    required this.items,
    required this.active,
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
    required this.onAddCustomPrayer,
  });

  @override
  Widget build(BuildContext context) {
    const rowScale = 0.85;
    final rowTextSize = typography.nextLabelSize * rowScale;
    final scaledChipStyle = InlineChipStyle(
      width: chipStyle.width,
      verticalPadding: chipStyle.verticalPadding * rowScale,
      fontSize: chipStyle.fontSize * rowScale,
      backgroundColor: chipStyle.backgroundColor,
      borderColor: chipStyle.borderColor,
      borderRadius: chipStyle.borderRadius,
    );
    final scaledIconStyle = InlineIconStyle(
      size: iconStyle.size * rowScale,
      iconSize: iconStyle.iconSize * rowScale,
      backgroundColor: iconStyle.backgroundColor,
      borderRadius: iconStyle.borderRadius,
    );
    final baseLabelStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontSize: rowTextSize);
    final maxLabelWidth = items.fold<double>(
      0,
      (currentMax, item) => math.max(
        currentMax,
        _measureTextWidth(
          item.labelController?.text.trim().isNotEmpty == true
              ? item.labelController!.text.trim()
              : item.label,
          baseLabelStyle,
        ),
      ),
    );
    final labelSlotWidth = math.max(maxLabelWidth, 88.0);
    final timeSlotWidth = typography.nextLabelSize * 2.8;
    final iconSlotWidth = iconStyle.size * 1.3;
    final activeIndex = items.indexWhere((entry) => entry.prayer == active);

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            controller: controller,
            padding: listPadding,
            itemBuilder: (context, index) {
              final item = items[index];
              final isPast =
                  item.prayer != null &&
                  activeIndex != -1 &&
                  index < activeIndex;
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
              final labelStyle = Theme.of(context).textTheme.titleSmall
                  ?.copyWith(
                    color: labelColor,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w300,
                    fontSize: rowTextSize,
                  );
              final rowWidgets = <Widget>[
                SizedBox(
                  width: labelSlotWidth,
                  child: item.labelController == null
                      ? Text(
                          item.label,
                          textAlign: TextAlign.right,
                          style: labelStyle,
                        )
                      : TextField(
                          controller: item.labelController,
                          onChanged: item.onLabelChanged,
                          onEditingComplete: () {
                            item.onLabelEditingComplete?.call();
                            FocusScope.of(context).unfocus();
                          },
                          onSubmitted: (_) {
                            item.onLabelEditingComplete?.call();
                          },
                          textAlign: TextAlign.right,
                          textInputAction: TextInputAction.done,
                          style: labelStyle?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                ),
                SizedBox(
                  width: timeSlotWidth,
                  child: item.onTimeTap == null
                      ? Text(
                          item.timeLabel,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: timeColor,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: rowTextSize,
                              ),
                        )
                      : InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: item.onTimeTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              item.timeLabel,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: timeColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: rowTextSize,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  width: chipStyle.width,
                  child: _ReminderChip(
                    controller: item.reminderController,
                    style: scaledChipStyle,
                    cizgiColor: controlColor,
                    backgroundColor: chipBackgroundColor,
                    borderColor: chipBorderColor,
                    onTap: item.onReminderTap,
                  ),
                ),
                if (showVoiceIcon)
                  SizedBox(
                    width: iconSlotWidth,
                    child: _IconToggle(
                      icon: Icons.volume_up_outlined,
                      style: scaledIconStyle,
                      isEnabled: item.voiceEnabled,
                      cizgiColor: controlColor,
                      onTap: item.onVoiceToggle,
                    ),
                  ),
                if (showVisualIcon)
                  SizedBox(
                    width: iconSlotWidth,
                    child: _IconToggle(
                      icon: Icons.desktop_windows_outlined,
                      style: scaledIconStyle,
                      isEnabled: item.visualEnabled,
                      cizgiColor: controlColor,
                      onTap: item.onVisualToggle,
                    ),
                  ),
                if (showAzanIcon)
                  SizedBox(
                    width: iconSlotWidth,
                    child: _IconToggle(
                      icon: Icons.mosque_outlined,
                      style: scaledIconStyle,
                      isEnabled: item.azanEnabled,
                      cizgiColor: controlColor,
                      onTap: item.onAzanToggle,
                    ),
                  ),
                if (showVibrationIcon)
                  SizedBox(
                    width: iconSlotWidth,
                    child: _IconToggle(
                      icon: Icons.vibration_outlined,
                      style: scaledIconStyle,
                      isEnabled: item.vibrationEnabled,
                      cizgiColor: controlColor,
                      onTap: item.onVibrationToggle,
                    ),
                  ),
                SizedBox(
                  width: iconStyle.iconSize * rowScale + 2,
                  child: item.onDelete == null
                      ? const SizedBox.shrink()
                      : _IconToggle(
                          icon: Icons.delete_outline,
                          style: InlineIconStyle(
                            size: scaledIconStyle.iconSize + 2,
                            iconSize: scaledIconStyle.iconSize,
                            backgroundColor: scaledIconStyle.backgroundColor,
                            borderRadius: scaledIconStyle.borderRadius,
                          ),
                          isEnabled: true,
                          cizgiColor: controlColor,
                          onTap: item.onDelete!,
                        ),
                ),
              ];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.transparent,
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
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (var i = 0; i < rowWidgets.length; i++) ...[
                                if (i > 0)
                                  SizedBox(
                                    width: i == 3
                                        ? 8
                                        : i <= 2
                                        ? 10
                                        : 0,
                                  ),
                                rowWidgets[i],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: Color(0x22000000)),
            itemCount: items.length,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 0, 12),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onAddCustomPrayer,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cizgiColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: cizgiColor.withValues(alpha: 0.25)),
                ),
                child: Icon(Icons.add, color: cizgiColor, size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderChip extends StatelessWidget {
  final TextEditingController controller;
  final InlineChipStyle style;
  final Color cizgiColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _ReminderChip({
    required this.controller,
    required this.style,
    required this.cizgiColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: style.width,
      child: InkWell(
        borderRadius: style.borderRadius,
        onTap: onTap,
        child: InputDecorator(
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
          child: Text(
            controller.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cizgiColor,
              fontWeight: FontWeight.w700,
              fontSize: style.fontSize,
            ),
          ),
        ),
      ),
    );
  }
}

double _measureTextWidth(String text, TextStyle? style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: ui.TextDirection.ltr,
  )..layout(minWidth: 0, maxWidth: double.infinity);
  return painter.width;
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
    final iconColor = isEnabled
        ? cizgiColor
        : cizgiColor.withValues(alpha: 0.4);
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
    return value.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasVoice = (voicePrayerLabel ?? '').trim().isNotEmpty;
    final hasVisual = (visualPrayerLabel ?? '').trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasVisual && showVisualCard) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCloseVisual,
            child: FlashingReminderCard(
              prayerLabel: '${_toTurkishUpper(visualPrayerLabel!)} VAKTİ',
              message: visualMessage ?? '',
            ),
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

class _DrawerHandlePainter extends CustomPainter {
  final Color color;
  final bool pointUp;

  const _DrawerHandlePainter({required this.color, required this.pointUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(0, pointUp ? size.height : 0)
      ..lineTo(size.width * 0.5, pointUp ? size.height * 0.54 : size.height * 0.46)
      ..lineTo(size.width, pointUp ? size.height : 0)
      ..lineTo(size.width * 0.5, pointUp ? 0 : size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawerHandlePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.pointUp != pointUp;
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
    final qiblaBearing = hasLocation
        ? _bearingToKaaba(latitude, longitude)
        : null;

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
                      final rotation =
                          ((qiblaBearing! - heading) * math.pi) / 180;
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
                                color: const Color(
                                  0xFF1F7A3E,
                                ).withValues(alpha: 0.22),
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


