import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/calculation_method_storage.dart';
import '../../app/locale_controller.dart';
import '../../app/location_storage.dart';
import '../../app/prayer_service.dart';
import '../../core/config/config_registry.dart';
import '../../core/prayer_engine/prayer.dart';
import '../../core/prayer_engine/prayer_times.dart';
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
  bool _showList = true;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
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
    if (lat == null || lon == null) {
      return _HomeData(
        location: location,
        methodCode: methodCode,
        error: 'invalid_location',
      );
    }

    final timeZone = _offsetToTz(DateTime.now().timeZoneOffset);
    final times = _prayerService.calculateToday(
      latitude: lat,
      longitude: lon,
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

  String _methodLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'turkey':
        return l10n.methodTurkey;
      case 'muslim_world_league':
        return l10n.methodMuslimWorldLeague;
      case 'umm_al_qura':
        return l10n.methodUmmAlQura;
      case 'dubai':
        return l10n.methodDubai;
      case 'kuwait':
        return l10n.methodKuwait;
      case 'qatar':
        return l10n.methodQatar;
      case 'singapore':
        return l10n.methodSingapore;
      case 'tehran':
        return l10n.methodTehran;
      case 'moonsighting':
        return l10n.methodMoonsighting;
      case 'north_america':
        return l10n.methodNorthAmerica;
      case 'egyptian':
        return l10n.methodEgyptian;
      case 'karachi':
        return l10n.methodKarachi;
      case 'other':
        return l10n.methodOther;
      default:
        return l10n.methodNotSet;
    }
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
              child: Text(
                l10n.locationNotSet,
                textAlign: TextAlign.center,
              ),
            );
          }

          if (data.error == 'invalid_location') {
            return Center(
              child: Text(
                l10n.locationFillAll,
                textAlign: TextAlign.center,
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
                        location: data.location!.city,
                        method: _methodLabel(l10n, data.methodCode ?? 'turkey'),
                        nextLabel: next.label,
                        countdown: countdown,
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
                          value: data.location!.city,
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
    if (!now.isBefore(times.isha)) {
      return Prayer.isha;
    }
    if (!now.isBefore(times.maghrib)) {
      return Prayer.maghrib;
    }
    if (!now.isBefore(times.asr)) {
      return Prayer.asr;
    }
    if (!now.isBefore(times.dhuhr)) {
      return Prayer.dhuhr;
    }
    if (!now.isBefore(times.sunrise)) {
      return Prayer.sunrise;
    }
    if (!now.isBefore(times.fajr)) {
      return Prayer.fajr;
    }
    return Prayer.fajr;
  }

  _PrayerNext _nextPrayer(PrayerTimes times, DateTime now, AppLocalizations l10n) {
    if (now.isBefore(times.fajr)) {
      return _PrayerNext(label: l10n.prayerFajr, time: times.fajr);
    }
    if (now.isBefore(times.sunrise)) {
      return _PrayerNext(label: l10n.prayerSunrise, time: times.sunrise);
    }
    if (now.isBefore(times.dhuhr)) {
      return _PrayerNext(label: l10n.prayerDhuhr, time: times.dhuhr);
    }
    if (now.isBefore(times.asr)) {
      return _PrayerNext(label: l10n.prayerAsr, time: times.asr);
    }
    if (now.isBefore(times.maghrib)) {
      return _PrayerNext(label: l10n.prayerMaghrib, time: times.maghrib);
    }
    if (now.isBefore(times.isha)) {
      return _PrayerNext(label: l10n.prayerIsha, time: times.isha);
    }
    return _PrayerNext(
      label: l10n.prayerFajr,
      time: times.fajr.add(const Duration(days: 1)),
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

class _TopPanel extends StatelessWidget {
  final String location;
  final String method;
  final String nextLabel;
  final String countdown;
  final VoidCallback onSettings;
  final SurfaceStyle style;
  final EdgeInsets padding;
  final double settingsIconSize;
  final double settingsIconBoxSize;
  final double settingsIconOpacity;
  final HomeTypography typography;

  const _TopPanel({
    required this.location,
    required this.method,
    required this.nextLabel,
    required this.countdown,
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: style.borderRadius,
        boxShadow: style.shadows,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: typography.nextLabelSize,
                      ),
                ),
                Text(
                  countdown,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontSize: typography.nextTimeSize,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onSettings,
                icon: Icon(
                  Icons.settings_outlined,
                  color: Colors.white.withOpacity(settingsIconOpacity),
                  size: settingsIconSize,
                ),
                tooltip: AppLocalizations.of(context)!.settingsTitle,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: settingsIconBoxSize,
                  minHeight: settingsIconBoxSize,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onLongPress: onSettings,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          location,
                          textAlign: TextAlign.right,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: typography.locationSize,
                                  ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xCCFFFFFF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: typography.methodSize,
                          ),
                    ),
                  ],
                ),
              ),
            ],
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
                        color: Colors.white.withOpacity(0.9),
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
        separatorBuilder: (_, __) => const Divider(
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
