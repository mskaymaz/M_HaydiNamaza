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

part 'home_data_controller.dart';
part 'home_content_controller.dart';
part 'home_reminder_runtime_controller.dart';
part 'home_navigation_controller.dart';
part 'home_build_controller.dart';
part 'home_reminder_engine_controller.dart';
part 'home_settings_persistence_controller.dart';
part 'home_prayer_panel_controller.dart';
part 'home_custom_prayer_rows_controller.dart';
part 'home_prayer_date_band.dart';

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
  void _setHomeState(VoidCallback action) {
    if (!mounted) return;
    setState(action);
  }

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
  int _prayerDayOffset = 0;
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

  @override
  Widget build(BuildContext context) => _buildHomeScaffold(context);
}
