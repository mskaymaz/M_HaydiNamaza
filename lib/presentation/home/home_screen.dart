import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';
import 'package:geocoding/geocoding.dart';

import '../../app/calculation_method_storage.dart';
import '../../app/custom_prayer_storage.dart';
import '../../app/locale_controller.dart';
import '../../app/location_storage.dart';
import '../../app/native_prayer_notification_scheduler.dart';
import 'package:geolocator/geolocator.dart';
import '../../app/reminder_audio_service.dart';
import '../../app/prayer_row_settings_storage.dart';
import '../../app/prayer_service.dart';
import '../../app/reminder_text_settings_storage.dart';
import '../../app/reminder_trigger_storage.dart';
import '../../app/ui_palette_controller.dart';
import '../../core/config/config_registry.dart';
import '../../core/prayer_engine/prayer.dart';
import '../../core/prayer_engine/prayer_times.dart';
import '../../features/daily_content/daily_content_selection_models.dart';
import '../../features/daily_content/daily_content_service.dart';
import '../settings/location_screen.dart';
import '../settings/settings_screen.dart';
import 'home_date_text_helpers.dart';
import 'widgets/home_daily_content_panel.dart';
import 'widgets/home_presentational_widgets.dart';
import 'widgets/home_prayer_list.dart';
import 'widgets/home_qibla_screen.dart';
import 'widgets/home_state_panels.dart';
import 'widgets/home_top_panel.dart';

part 'home_models.dart';
part 'home_prayer_time_helpers.dart';
part 'home_custom_time_helpers.dart';
part 'home_drawer_layout_helpers.dart';
part 'home_custom_time_editor_sheet.dart';

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
  final _nativeNotificationScheduler = NativePrayerNotificationScheduler();
  final _prayerService = PrayerService();
  final _dailyContentService = DailyContentService();
  final Map<Prayer, _PrayerRowSettings> _rowSettings = {};
  final Map<Prayer, TextEditingController> _reminderControllers = {};
  final Map<String, String> _triggerLog = {};
  final List<_CustomPrayerDraft> _customPrayerRows = [];
  final ScrollController _prayerListScrollController = ScrollController();

  late Future<_HomeData> _future;
  late Future<DailyContentSelectionResult> _dailyContentFuture;
  int _dailyContentAyahOffset = 0;
  int _dailyContentHadithOffset = 0;
  int _dailyContentEsmaOffset = 0;
  int _dailyContentSifatOffset = 0;
  Timer? _ticker;
  Timer? _voiceRepeatTimer;
  Timer? _visualCycleTimer;
  Timer? _vibrationRepeatTimer;
  DateTime _now = DateTime.now();
  DateTime _lastRefreshDay = DateTime.now();
  double _prayerPanelDragDx = 0;
  bool _isLandscapePanelsExpanded = false;
  bool _showPanelAddButton = false;
  bool _showPrayerControlPanel = false;
  bool _showHijriDate = true;
  bool _reminderCheckInProgress = false;
  bool _nativeScheduleRefreshInProgress = false;
  bool _nativeScheduleRefreshPending = false;
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
    _dailyContentFuture = _dailyContentService.loadToday();
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
          _resetDailyContentPreviewOffsets();
          _dailyContentFuture = _dailyContentService.loadToday();
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
    final useCurrent = await _locationStorage.readUseCurrentLocation();
    if (useCurrent) {
      await _refreshStoredCurrentLocation();
    }
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

    final timeZone = location.timeZoneOffset;
    final times = await _prayerService.calculateToday(
      location: location,
      latitude: lat ?? 0,
      longitude: lon ?? 0,
      timeZone: timeZone,
      methodCode: methodCode,
    );

    return _HomeData(location: location, methodCode: methodCode, times: times);
  }

  Future<void> _refreshStoredCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _locationStorage.writeUseCurrentLocation(false);
        return;
      }
      final position = await _readFastCurrentPosition();
      if (position == null) return;
      final stored = await _locationStorage.read();
      if (stored == null) return;
      final storedLat = double.tryParse(stored.latitude) ?? 0.0;
      final storedLon = double.tryParse(stored.longitude) ?? 0.0;
      final dLat = (storedLat - position.latitude).abs();
      final dLon = (storedLon - position.longitude).abs();
      if (dLat <= 0.01 && dLon <= 0.01) return;
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 3), onTimeout: () => <Placemark>[]);
      final placemark = placemarks.isEmpty ? null : placemarks.first;
      final province = (placemark?.administrativeArea ?? '').trim();
      final district = (placemark?.subAdministrativeArea ?? '').trim();
      await _locationStorage.write(
        LocationData(
          countryId: null,
          countryName: placemark?.country ?? '',
          province: province.isEmpty ? stored.province : province,
          district: district.isEmpty ? stored.district : district,
          latitude: position.latitude.toString(),
          longitude: position.longitude.toString(),
        ),
      );
      await _locationStorage.writeUseCurrentLocation(true);
    } catch (_) {}
  }

  Future<Position?> _readFastCurrentPosition() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition().timeout(
        const Duration(milliseconds: 1200),
      );
      if (lastKnown != null) return lastKnown;
    } catch (_) {}
    try {
      return await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 4),
      );
    } catch (_) {
      return null;
    }
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
    unawaited(_refreshNativeReminderSchedule());
  }

  void _resetDailyContentPreviewOffsets() {
    _dailyContentAyahOffset = 0;
    _dailyContentHadithOffset = 0;
    _dailyContentEsmaOffset = 0;
    _dailyContentSifatOffset = 0;
  }

  Future<void> _cycleDailyContent(DailyContentPanelKind kind) async {
    setState(() {
      switch (kind) {
        case DailyContentPanelKind.ayah:
          _dailyContentAyahOffset += 1;
          break;
        case DailyContentPanelKind.hadith:
          _dailyContentHadithOffset += 1;
          break;
        case DailyContentPanelKind.esma:
          _dailyContentEsmaOffset += 1;
          break;
        case DailyContentPanelKind.sifat:
          _dailyContentSifatOffset += 1;
          break;
      }
      _dailyContentFuture = _dailyContentService.loadPreview(
        ayahOffset: _dailyContentAyahOffset,
        hadithOffset: _dailyContentHadithOffset,
        esmaOffset: _dailyContentEsmaOffset,
        sifatOffset: _dailyContentSifatOffset,
      );
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
    unawaited(_refreshNativeReminderSchedule());
  }

  Future<void> _openQibla(LocationData? location) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HomeQiblaScreen(location: location)),
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
            return HomeMissingLocationPanel(
              message: l10n.locationNotSet,
              settingsLabel: l10n.settingsTitle,
              onOpenSettings: _openSettings,
            );
          }

          if (data.error == 'invalid_location') {
            return HomeInvalidLocationPanel(
              message: l10n.locationFillAll,
              settingsLabel: l10n.settingsTitle,
              onOpenSettings: _openSettings,
            );
          }

          final times = data.times;
          if (times == null) {
            return HomePrayerTimesUnavailablePanel(message: l10n.comingSoon);
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_checkAndTriggerReminders(times, l10n));
          });

          final items = _buildItems(l10n, times);
          final active = _activePrayer(times, _now);
          final next = _nextPrayer(times, _now, l10n);
          final countdown = _formatCountdown(_now, next.time);
          final nextTime = homeFormatTime(next.time);
          final location = data.location!;
          final provinceLabel = homeTitleCase(
            location.province,
            l10n.localeName,
          );
          final districtLabel = homeTitleCase(
            location.district,
            l10n.localeName,
          );
          final hijriDateLabel =
              '${homeFormatHijriDayMonth(_now, l10n)} '
              '${homeFormatHijriYear(_now)}';
          final gregorianDateLabel =
              '${homeFormatGregorianDayMonth(_now, l10n)} '
              '${homeFormatGregorianYear(_now, l10n)}';
          final dateLabel = _showHijriDate
              ? hijriDateLabel
              : gregorianDateLabel;
          final palette = widget.uiPaletteController.value;
          final ui = ConfigRegistry.mainUiFor(palette);
          final mediaPadding = MediaQuery.of(context).padding;
          final statusBarHeight = mediaPadding.top;
          final bottomSafePadding = mediaPadding.bottom;
          final statusBarColor =
              Color.lerp(palette.zeminColor, Colors.white, 0.5) ??
              palette.zeminColor;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: ColoredBox(
              color: palette.backgroundZeminColor,
              child: Stack(
                children: [
                  if (statusBarHeight > 0)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: statusBarHeight,
                      child: ColoredBox(color: statusBarColor),
                    ),
                  SafeArea(
                    child: Padding(
                      padding: ui.screenPadding,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final drawerLayout = _computeDrawerLayout(
                            locationTextSize: ui.typography.locationSize,
                            nextTimeTextSize: ui.typography.nextTimeSize,
                            nextLabelTextSize: ui.typography.nextLabelSize,
                            topPanelVerticalPadding:
                                ui.topPanelPadding.vertical,
                            constraintsMaxHeight: constraints.maxHeight,
                            drawerProgress: 1.0,
                          );
                          const infoPanelGap = 3.0;
                          const infoPanelBottomPadding = 8.0;
                          final infoPanelBottomOverflow = bottomSafePadding;
                          final drawerBottom =
                              drawerLayout.drawerTop +
                              drawerLayout.drawerHeight;
                          final infoPanelTop = drawerBottom + infoPanelGap;
                          final infoPanelMaxHeight = math.max(
                            140.0,
                            constraints.maxHeight -
                                infoPanelTop -
                                infoPanelBottomPadding +
                                infoPanelBottomOverflow,
                          );
                          final isLandscape =
                              MediaQuery.of(context).orientation ==
                              Orientation.landscape;
                          final panelWidthFactor = isLandscape
                              ? (_isLandscapePanelsExpanded ? 0.9 : 0.72)
                              : 1.0;
                          final scrollContentHeight = math.max(
                            constraints.maxHeight,
                            infoPanelTop +
                                infoPanelMaxHeight +
                                infoPanelBottomPadding,
                          );

                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: scrollContentHeight,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    top: drawerLayout.drawerTop,
                                    left: 0,
                                    right: 0,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: FractionallySizedBox(
                                        widthFactor: panelWidthFactor,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          height: drawerLayout.drawerHeight,
                                          decoration: BoxDecoration(
                                            color: ui.listPanel.color,
                                            borderRadius:
                                                BorderRadius.circular(20),
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
                                              SizedBox(
                                                height:
                                                    drawerLayout.panelOverlap +
                                                    12,
                                              ),
                                              Expanded(
                                                child: GestureDetector(
                                                  behavior: HitTestBehavior
                                                      .translucent,
                                                  onTap: () {
                                                    if (!_showPrayerControlPanel) {
                                                      return;
                                                    }
                                                    setState(
                                                      () => _showPanelAddButton =
                                                          !_showPanelAddButton,
                                                    );
                                                  },
                                                  onHorizontalDragEnd:
                                                      _onPrayerPanelHorizontalDragEnd,
                                                  onHorizontalDragStart:
                                                      _onPrayerPanelHorizontalDragStart,
                                                  onHorizontalDragUpdate:
                                                      _onPrayerPanelHorizontalDragUpdate,
                                                  onDoubleTap: () {
                                                    if (!isLandscape) return;
                                                    setState(() {
                                                      _isLandscapePanelsExpanded =
                                                          !_isLandscapePanelsExpanded;
                                                    });
                                                  },
                                                  child: Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: AnimatedSwitcher(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    220,
                                                              ),
                                                          transitionBuilder: (child, animation) {
                                                            return SlideTransition(
                                                              position:
                                                                  Tween<Offset>(
                                                                    begin:
                                                                        const Offset(
                                                                          0.12,
                                                                          0,
                                                                        ),
                                                                    end: Offset
                                                                        .zero,
                                                                  ).animate(
                                                                    animation,
                                                                  ),
                                                              child: child,
                                                            );
                                                          },
                                                          child:
                                                              _showPrayerControlPanel
                                                              ? HomePrayerList(
                                                                  key: const ValueKey(
                                                                    'prayer_controls',
                                                                  ),
                                                                  controller:
                                                                      _prayerListScrollController,
                                                                  items: items,
                                                                  active:
                                                                      active,
                                                                  style: ui
                                                                      .listPanel,
                                                                  listPadding: ui
                                                                      .listPadding,
                                                                  rowGap:
                                                                      ui.rowGap,
                                                                  iconStyle: ui
                                                                      .iconToggle,
                                                                  chipStyle: ui
                                                                      .reminderChip,
                                                                  typography: ui
                                                                      .typography,
                                                                  cizgiColor:
                                                                      palette
                                                                          .cizgiColor,
                                                                  activeColor:
                                                                      palette
                                                                          .zeminColor,
                                                                  customPrayerLabelColor:
                                                                      palette
                                                                          .customPrayerLabelColor,
                                                                  showVoiceIcon:
                                                                      _reminderSettings
                                                                          .showVoiceIcon,
                                                                  showVisualIcon:
                                                                      _reminderSettings
                                                                          .showVisualIcon,
                                                                  showAzanIcon:
                                                                      _reminderSettings
                                                                          .showAzanIcon,
                                                                  showVibrationIcon:
                                                                      _reminderSettings
                                                                          .showVibrationIcon,
                                                                )
                                                              : HomePrayerSummaryList(
                                                                  key: const ValueKey(
                                                                    'prayer_summary',
                                                                  ),
                                                                  controller:
                                                                      _prayerListScrollController,
                                                                  items: items,
                                                                  active:
                                                                      active,
                                                                  listPadding: ui
                                                                      .listPadding,
                                                                  cizgiColor:
                                                                      palette
                                                                          .cizgiColor,
                                                                  activeColor:
                                                                      palette
                                                                          .zeminColor,
                                                                  customPrayerLabelColor:
                                                                      palette
                                                                          .customPrayerLabelColor,
                                                                  onOpenControls:
                                                                      _showPrayerControls,
                                                                ),
                                                        ),
                                                      ),
                                                      if (_showPrayerControlPanel &&
                                                          _showPanelAddButton)
                                                        Positioned(
                                                          left: 12,
                                                          bottom: 12,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            onTap:
                                                                _addCustomPrayerRow,
                                                            child: Container(
                                                              width: 36,
                                                              height: 36,
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    const Color(
                                                                      0xFFFFEB3B,
                                                                    ),
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                  color: palette
                                                                      .cizgiColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.25,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: const Icon(
                                                                Icons.add,
                                                                color: Color(
                                                                  0xFF1B5E20,
                                                                ),
                                                                size: 19.5,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: HomeTopPanel(
                                      provinceLabel: provinceLabel,
                                      districtLabel: districtLabel,
                                      nextLabel: next.label,
                                      nextTime: nextTime,
                                      countdown: countdown,
                                      dateLabel: dateLabel,
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
                                      settingsIconBoxSize:
                                          ui.settingsIconBoxSize,
                                      settingsIconOpacity:
                                          ui.settingsIconOpacity,
                                      typography: ui.typography,
                                      cizgiColor: palette.cizgiColor,
                                    ),
                                  ),
                                  Positioned(
                                    top: infoPanelTop,
                                    left: 0,
                                    right: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        0,
                                        0,
                                        infoPanelBottomPadding,
                                      ),
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onDoubleTap: () {
                                          if (!isLandscape) return;
                                          setState(() {
                                            _isLandscapePanelsExpanded =
                                                !_isLandscapePanelsExpanded;
                                          });
                                        },
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: FractionallySizedBox(
                                            widthFactor: panelWidthFactor,
                                            child:
                                                FutureBuilder<
                                                  DailyContentSelectionResult
                                                >(
                                                  future: _dailyContentFuture,
                                                  builder: (context, snapshot) {
                                                    return HomeDailyContentPanel(
                                                      result: snapshot.data,
                                                      isLoading:
                                                          snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting,
                                                      hasError:
                                                          snapshot.hasError,
                                                      cizgiColor:
                                                          palette.cizgiColor,
                                                      panelColor:
                                                          palette.zeminColor,
                                                      maxHeight:
                                                          infoPanelMaxHeight,
                                                      onCycleContentTap:
                                                          _cycleDailyContent,
                                                    );
                                                  },
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                        child: HomeActiveReminderPanel(
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
            ),
          );
        },
      ),
    );
  }

  Future<void> _openLocationSettings(LocationData? location) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LocationScreen(
          initial: location,
          uiPaletteController: widget.uiPaletteController,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _future = _loadData();
    });
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

  Future<void> _refreshNativeReminderSchedule() async {
    if (_nativeScheduleRefreshInProgress) {
      _nativeScheduleRefreshPending = true;
      return;
    }
    _nativeScheduleRefreshInProgress = true;
    try {
      final schedule = await _buildNativeReminderSchedule();
      await _nativeNotificationScheduler.ensurePermissions();
      await _nativeNotificationScheduler.configure(schedule.notifications);
      await _nativeNotificationScheduler.configureWidget(schedule.widgetEvents);
    } catch (_) {
      try {
        await _nativeNotificationScheduler.cancelAll();
      } catch (_) {}
    } finally {
      _nativeScheduleRefreshInProgress = false;
      if (_nativeScheduleRefreshPending) {
        _nativeScheduleRefreshPending = false;
        unawaited(_refreshNativeReminderSchedule());
      }
    }
  }

  Future<_NativeReminderSchedule> _buildNativeReminderSchedule() async {
    final location = await _locationStorage.read();
    if (location == null) {
      return const _NativeReminderSchedule(notifications: [], widgetEvents: []);
    }

    var methodCode = await _methodStorage.readCode();
    methodCode ??= 'turkey';
    final latitude = double.tryParse(location.latitude);
    final longitude = double.tryParse(location.longitude);
    if ((methodCode != 'turkey' && methodCode != 'diyanet_tabanli') &&
        (latitude == null || longitude == null)) {
      return const _NativeReminderSchedule(notifications: [], widgetEvents: []);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifications = <NativePrayerNotificationEvent>[];
    final widgetEvents = <NativePrayerWidgetEvent>[];
    final times = await _prayerService.calculateForDate(
      location: location,
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      timeZone: location.timeZoneOffset,
      methodCode: methodCode,
      date: today,
      allowDiyanet: false,
      allowRemote: false,
    );
    _appendNativeStandardPrayerEvents(
      notifications: notifications,
      widgetEvents: widgetEvents,
      times: times,
      now: now,
    );
    _appendNativeCustomPrayerEvents(notifications, times, now);
    return _NativeReminderSchedule(
      notifications: notifications,
      widgetEvents: widgetEvents,
    );
  }

  void _appendNativeStandardPrayerEvents({
    required List<NativePrayerNotificationEvent> notifications,
    required List<NativePrayerWidgetEvent> widgetEvents,
    required PrayerTimes times,
    required DateTime now,
  }) {
    final prayerTimes = <Prayer, DateTime>{
      Prayer.fajr: times.fajr,
      Prayer.sunrise: times.sunrise,
      Prayer.dhuhr: times.dhuhr,
      Prayer.asr: times.asr,
      Prayer.maghrib: times.maghrib,
      Prayer.isha: times.isha,
    };
    _appendNativeWidgetEvents(widgetEvents, prayerTimes, now);
    for (final entry in prayerTimes.entries) {
      final settings = _settingsFor(entry.key);
      final label = _turkishPrayerLabel(entry.key);
      _appendNativeEventsForRow(
        events: notifications,
        now: now,
        baseId: entry.key.index + 1,
        label: label,
        prayerTime: entry.value,
        settings: settings,
      );
    }
  }

  void _appendNativeWidgetEvents(
    List<NativePrayerWidgetEvent> widgetEvents,
    Map<Prayer, DateTime> prayerTimes,
    DateTime now,
  ) {
    for (final entry in prayerTimes.entries) {
      if (!entry.value.isAfter(now)) continue;
      widgetEvents.add(
        NativePrayerWidgetEvent(
          triggerAt: entry.value,
          prayerLabel: _turkishPrayerLabel(entry.key),
        ),
      );
    }
    if (widgetEvents.isNotEmpty) return;
    widgetEvents.add(
      NativePrayerWidgetEvent(
        triggerAt: prayerTimes[Prayer.fajr]!.add(const Duration(days: 1)),
        prayerLabel: _turkishPrayerLabel(Prayer.fajr),
      ),
    );
  }

  void _appendNativeCustomPrayerEvents(
    List<NativePrayerNotificationEvent> events,
    PrayerTimes times,
    DateTime now,
  ) {
    for (var index = 0; index < _customPrayerRows.length; index++) {
      final row = _customPrayerRows[index];
      final prayerTime = _resolveCustomPrayerTimeForDate(
        row.timeRule,
        times,
        times.fajr,
      );
      if (prayerTime == null) continue;
      final label = row.labelController.text.trim().isEmpty
          ? 'Nafile'
          : row.labelController.text.trim();
      _appendNativeEventsForRow(
        events: events,
        now: now,
        baseId: 100 + index,
        label: label,
        prayerTime: prayerTime,
        settings: row.settings,
      );
    }
  }

  void _appendNativeEventsForRow({
    required List<NativePrayerNotificationEvent> events,
    required DateTime now,
    required int baseId,
    required String label,
    required DateTime prayerTime,
    required _PrayerRowSettings settings,
  }) {
    if (settings.voiceEnabled ||
        settings.visualEnabled ||
        settings.vibrationEnabled) {
      final reminderTime = prayerTime.subtract(
        Duration(minutes: settings.reminderMinutes.clamp(0, 1440)),
      );
      if (reminderTime.isAfter(now)) {
        events.add(
          _nativeEvent(
            baseId: baseId,
            triggerAt: reminderTime,
            prayerLabel: label,
            stage: 'reminder',
            voiceEnabled: settings.voiceEnabled,
            visualEnabled: settings.visualEnabled,
            azanEnabled: false,
            vibrationEnabled: settings.vibrationEnabled,
          ),
        );
      }
    }
    if (settings.azanEnabled || settings.vibrationEnabled) {
      if (prayerTime.isAfter(now)) {
        events.add(
          _nativeEvent(
            baseId: baseId,
            triggerAt: prayerTime,
            prayerLabel: label,
            stage: 'prayer',
            voiceEnabled: false,
            visualEnabled: settings.azanEnabled,
            azanEnabled: settings.azanEnabled,
            vibrationEnabled: settings.vibrationEnabled,
          ),
        );
      }
    }
  }

  NativePrayerNotificationEvent _nativeEvent({
    required int baseId,
    required DateTime triggerAt,
    required String prayerLabel,
    required String stage,
    required bool voiceEnabled,
    required bool visualEnabled,
    required bool azanEnabled,
    required bool vibrationEnabled,
  }) {
    final stageOffset = stage == 'prayer' ? 5000 : 0;
    final dayId =
        DateTime(
          triggerAt.year,
          triggerAt.month,
          triggerAt.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final id = (dayId * 10000) + stageOffset + baseId;
    final isPrayerStage = stage == 'prayer';
    final title = isPrayerStage
        ? '$prayerLabel vakti'
        : '$prayerLabel vakti yakla\u015f\u0131yor';
    final fallbackMessage = isPrayerStage
        ? '$prayerLabel vakti girdi.'
        : _effectiveVisualReminderText(prayerLabel);
    return NativePrayerNotificationEvent(
      id: id,
      triggerAt: triggerAt,
      prayerLabel: prayerLabel,
      stage: stage,
      title: title,
      message: fallbackMessage,
      voiceEnabled: voiceEnabled,
      visualEnabled: visualEnabled,
      azanEnabled: azanEnabled,
      vibrationEnabled: vibrationEnabled,
      vibrationDurationMs: _reminderSettings.vibrationDurationSeconds * 1000,
    );
  }

  String _turkishPrayerLabel(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return '\u0130msak';
      case Prayer.sunrise:
        return 'G\u00fcne\u015f';
      case Prayer.dhuhr:
        return '\u00d6\u011fle';
      case Prayer.asr:
        return '\u0130kindi';
      case Prayer.maghrib:
        return 'Ak\u015fam';
      case Prayer.isha:
        return 'Yats\u0131';
      case Prayer.none:
        return 'Vakit';
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
    unawaited(_refreshNativeReminderSchedule());
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
    unawaited(_refreshNativeReminderSchedule());
  }

  Future<void> _persistCustomPrayerRows() async {
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
    await _customPrayerStorage.write(payload);
    unawaited(_refreshNativeReminderSchedule());
  }

  Future<void> _persistPrayerRowSettings() async {
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
    await _rowSettingsStorage.write(payload);
    unawaited(_refreshNativeReminderSchedule());
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
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () =>
                          Navigator.of(context).pop(editController.text),
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

  void _onPrayerPanelHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final draggedDistance = _prayerPanelDragDx;
    _prayerPanelDragDx = 0;
    if (velocity.abs() < 220.0 && draggedDistance.abs() < 24.0) return;

    setState(() {
      _showPrayerControlPanel = !_showPrayerControlPanel;
      if (!_showPrayerControlPanel) {
        _showPanelAddButton = false;
      }
    });
  }

  void _onPrayerPanelHorizontalDragStart(DragStartDetails details) {
    _prayerPanelDragDx = 0;
  }

  void _onPrayerPanelHorizontalDragUpdate(DragUpdateDetails details) {
    _prayerPanelDragDx += details.primaryDelta ?? details.delta.dx;
  }

  void _showPrayerControls() {
    if (_showPrayerControlPanel) return;
    setState(() {
      _showPrayerControlPanel = true;
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

  Future<void> _openCustomTimeEditor(
    _CustomPrayerDraft row,
    AppLocalizations l10n,
  ) async {
    final savedRule = await showModalBottomSheet<_CustomPrayerTimeRule>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _HomeCustomTimeEditorSheet(
          l10n: l10n,
          initialRule: row.timeRule,
        );
      },
    );
    if (savedRule == null) return;
    setState(() {
      row.timeRule = savedRule;
    });
    unawaited(_persistCustomPrayerRows());
  }

  List<HomePrayerListItem> _buildItems(
    AppLocalizations l10n,
    PrayerTimes times,
  ) {
    HomePrayerListItem itemFor(Prayer prayer, String label, DateTime time) {
      final settings = _settingsFor(prayer);
      return HomePrayerListItem(
        id: prayer.name,
        prayer: prayer,
        label: label,
        sortTime: time,
        timeLabel: homeFormatTime(time),
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
        HomePrayerListItem(
          id: row.id,
          prayer: null,
          label: row.labelController.text.trim(),
          sortTime: resolvedTime,
          labelController: row.labelController,
          onLabelChanged: (value) => _setCustomPrayerLabel(row, value),
          onLabelEditingComplete: () => _normalizeCustomPrayerLabel(row),
          timeLabel: resolvedTime == null
              ? '--:--'
              : homeFormatTime(resolvedTime),
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

    final ordered = List<HomePrayerListItem>.from(items);
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
