import 'package:flutter/services.dart';

int _wallClockMillis(DateTime value) {
  final local = DateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
    value.microsecond,
  );
  return local.millisecondsSinceEpoch;
}

class NativePrayerNotificationEvent {
  final int id;
  final DateTime triggerAt;
  final String prayerLabel;
  final String stage;
  final String title;
  final String message;
  final bool voiceEnabled;
  final bool visualEnabled;
  final bool azanEnabled;
  final String? azanFilePath;
  final bool vibrationEnabled;
  final int vibrationDurationMs;

  const NativePrayerNotificationEvent({
    required this.id,
    required this.triggerAt,
    required this.prayerLabel,
    required this.stage,
    required this.title,
    required this.message,
    required this.voiceEnabled,
    required this.visualEnabled,
    required this.azanEnabled,
    this.azanFilePath,
    required this.vibrationEnabled,
    required this.vibrationDurationMs,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'triggerAtMillis': _wallClockMillis(triggerAt),
      'prayerLabel': prayerLabel,
      'stage': stage,
      'title': title,
      'message': message,
      'voiceEnabled': voiceEnabled,
      'visualEnabled': visualEnabled,
      'azanEnabled': azanEnabled,
      'azanFilePath': azanFilePath,
      'vibrationEnabled': vibrationEnabled,
      'vibrationDurationMs': vibrationDurationMs,
    };
  }
}

class NativePrayerWidgetEvent {
  final DateTime triggerAt;
  final String prayerLabel;
  final DateTime remainingTriggerAt;
  final String remainingPrayerLabel;
  final String dateLabel;
  final String fajrTime;
  final String sunriseTime;
  final String dhuhrTime;
  final String asrTime;
  final String maghribTime;
  final String ishaTime;

  const NativePrayerWidgetEvent({
    required this.triggerAt,
    required this.prayerLabel,
    DateTime? remainingTriggerAt,
    String? remainingPrayerLabel,
    required this.dateLabel,
    required this.fajrTime,
    required this.sunriseTime,
    required this.dhuhrTime,
    required this.asrTime,
    required this.maghribTime,
    required this.ishaTime,
  }) : remainingTriggerAt = remainingTriggerAt ?? triggerAt,
       remainingPrayerLabel = remainingPrayerLabel ?? prayerLabel;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'triggerAtMillis': _wallClockMillis(triggerAt),
      'prayerLabel': prayerLabel,
      'remainingTriggerAtMillis': _wallClockMillis(remainingTriggerAt),
      'remainingPrayerLabel': remainingPrayerLabel,
      'timeLabel':
          '${triggerAt.hour.toString().padLeft(2, '0')}:'
          '${triggerAt.minute.toString().padLeft(2, '0')}',
      'dateLabel': dateLabel,
      'fajrTime': fajrTime,
      'sunriseTime': sunriseTime,
      'dhuhrTime': dhuhrTime,
      'asrTime': asrTime,
      'maghribTime': maghribTime,
      'ishaTime': ishaTime,
    };
  }
}

class NativePrayerNotificationScheduler {
  static const MethodChannel _channel = MethodChannel(
    'mhaydinamaza/prayer_notifications',
  );

  Future<void> ensurePermissions() async {
    try {
      await _channel.invokeMethod<void>('ensurePermissions');
    } on PlatformException {
      // Scheduling still attempts best-effort fallback if a platform permission
      // cannot be requested automatically.
    }
  }

  Future<void> configure(List<NativePrayerNotificationEvent> events) async {
    await _channel.invokeMethod<void>('configure', <String, Object?>{
      'events': events.map((event) => event.toJson()).toList(),
    });
  }

  Future<void> configureWidget(List<NativePrayerWidgetEvent> events) async {
    await _channel.invokeMethod<void>('configureWidget', <String, Object?>{
      'events': events.map((event) => event.toJson()).toList(),
    });
  }

  Future<void> cancelAll() async {
    await _channel.invokeMethod<void>('cancelAll');
  }
}
