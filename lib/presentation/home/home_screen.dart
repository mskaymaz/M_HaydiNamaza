import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/calculation_method_storage.dart';
import '../../app/locale_controller.dart';
import '../../app/location_storage.dart';
import '../../app/prayer_service.dart';
import '../../core/config/config_registry.dart';
import '../../core/prayer_engine/prayer.dart';
import '../../core/prayer_engine/prayer_times.dart';
import '../settings/location_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final LocaleController localeController;

  const HomeScreen({super.key, required this.localeController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _locationStorage = LocationStorage();
  final _methodStorage = CalculationMethodStorage();
  final _prayerService = PrayerService();

  late Future<_HomeData> _future;
  Timer? _ticker;
  DateTime _now = DateTime.now();
  DateTime _lastRefreshDay = DateTime.now();
  bool _showList = true;
  bool _showHijriDate = false;

  @override
  void initState() {
    super.initState();
    _lastRefreshDay = DateTime(_now.year, _now.month, _now.day);
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
        ),
      ),
    );
    setState(() {
      _future = _loadData();
    });
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
          final ui = ConfigRegistry.mainUi;

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('img/templates_line/bg_motif02.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
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
                        onSettings: _openSettings,
                        style: ui.topPanel,
                        padding: ui.topPanelPadding,
                        settingsIconSize: ui.settingsIconSize,
                        settingsIconBoxSize: ui.settingsIconBoxSize,
                        settingsIconOpacity: ui.settingsIconOpacity,
                        typography: ui.typography,
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
        builder: (_) => LocationScreen(initial: location),
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

  List<_PrayerItem> _buildItems(AppLocalizations l10n, PrayerTimes times) {
    return [
      _PrayerItem(Prayer.fajr, l10n.prayerFajr, times.fajr, 15),
      _PrayerItem(Prayer.sunrise, l10n.prayerSunrise, times.sunrise, 0),
      _PrayerItem(Prayer.dhuhr, l10n.prayerDhuhr, times.dhuhr, 15),
      _PrayerItem(Prayer.asr, l10n.prayerAsr, times.asr, 15),
      _PrayerItem(Prayer.maghrib, l10n.prayerMaghrib, times.maghrib, 15),
      _PrayerItem(Prayer.isha, l10n.prayerIsha, times.isha, 15),
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

  _PrayerItem(this.prayer, this.label, this.time, this.reminderMinutes);
}

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
  final VoidCallback onSettings;
  final SurfaceStyle style;
  final EdgeInsets padding;
  final double settingsIconSize;
  final double settingsIconBoxSize;
  final double settingsIconOpacity;
  final HomeTypography typography;

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
    required this.onSettings,
    required this.style,
    required this.padding,
    required this.settingsIconSize,
    required this.settingsIconBoxSize,
    required this.settingsIconOpacity,
    required this.typography,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowerSectionHeight = typography.nextTimeSize + typography.nextLabelSize + 18;
    final topRowHeight = settingsIconBoxSize > typography.locationSize + 8
        ? settingsIconBoxSize
        : typography.locationSize + 8;
    final locationTextStyle = theme.textTheme.titleMedium?.copyWith(
      color: Colors.white,
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
                          color: Colors.white,
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
                  alignment: Alignment.centerRight,
                  child: Transform.translate(
                    offset: const Offset(13, 0),
                    child: IconButton(
                      onPressed: onSettings,
                      icon: Icon(
                        Icons.settings_outlined,
                        color: Colors.white.withValues(alpha: settingsIconOpacity),
                        size: settingsIconSize * 1.2,
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
            color: Colors.white.withValues(alpha: 0.14),
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
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: (typography.methodSize + 1) * 1.2,
                              ),
                        ),
                      ),
                      Text(
                        timeLabel,
                        style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: typography.nextLabelSize,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            nextTime,
                            style: theme.textTheme.titleSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w300,
                                  fontSize: typography.nextLabelSize,
                                ),
                          ),
                        ],
                      ),
                      Text(
                        countdown,
                        style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
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
          final isActive = item.prayer == active;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF1E8B4A) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: typography.listLabelSize,
                        ),
                  ),
                ),
                Text(
                  timeFormat(item.time),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: typography.listTimeSize,
                      ),
                ),
                SizedBox(width: rowGap),
                _ReminderChip(minutes: item.reminderMinutes, style: chipStyle),
                SizedBox(width: rowGap),
                _IconToggle(icon: Icons.volume_up_outlined, style: iconStyle),
                SizedBox(width: rowGap),
                _IconToggle(icon: Icons.remove_red_eye_outlined, style: iconStyle),
                SizedBox(width: rowGap),
                _IconToggle(icon: Icons.mosque_outlined, style: iconStyle),
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
  final int minutes;
  final InlineChipStyle style;

  const _ReminderChip({required this.minutes, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: style.width,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(vertical: style.verticalPadding),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: style.borderRadius,
        border: Border.all(color: style.borderColor),
      ),
      child: Text(
        minutes.toString(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: style.fontSize,
            ),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  final IconData icon;
  final InlineIconStyle style;

  const _IconToggle({required this.icon, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: style.size,
      height: style.size,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: style.borderRadius,
      ),
      child: Icon(icon, size: style.iconSize, color: Colors.white),
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
