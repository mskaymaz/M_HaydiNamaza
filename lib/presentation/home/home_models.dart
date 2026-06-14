part of 'home_screen.dart';

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

class _NativeReminderSchedule {
  final List<NativePrayerNotificationEvent> notifications;
  final List<NativePrayerWidgetEvent> widgetEvents;

  const _NativeReminderSchedule({
    required this.notifications,
    required this.widgetEvents,
  });
}
