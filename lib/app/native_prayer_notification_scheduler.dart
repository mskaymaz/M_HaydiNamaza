import 'package:flutter/services.dart';

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
    required this.vibrationEnabled,
    required this.vibrationDurationMs,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      'prayerLabel': prayerLabel,
      'stage': stage,
      'title': title,
      'message': message,
      'voiceEnabled': voiceEnabled,
      'visualEnabled': visualEnabled,
      'azanEnabled': azanEnabled,
      'vibrationEnabled': vibrationEnabled,
      'vibrationDurationMs': vibrationDurationMs,
    };
  }
}

class NativePrayerWidgetEvent {
  final DateTime triggerAt;
  final String prayerLabel;

  const NativePrayerWidgetEvent({
    required this.triggerAt,
    required this.prayerLabel,
  });

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'triggerAtMillis': triggerAt.millisecondsSinceEpoch,
      'prayerLabel': prayerLabel,
      'timeLabel':
          '${triggerAt.hour.toString().padLeft(2, '0')}:'
          '${triggerAt.minute.toString().padLeft(2, '0')}',
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
