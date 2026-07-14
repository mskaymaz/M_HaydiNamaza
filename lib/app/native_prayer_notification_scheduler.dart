import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/prayer_engine/prayer.dart';
import '../core/prayer_engine/prayer_times.dart';
import 'calculation_method_storage.dart';
import 'location_storage.dart';
import 'prayer_service.dart';

const int prayerTimesPrefetchDays = 30;

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
  final bool silentModeEvent;

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
    this.silentModeEvent = false,
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
      'silentModeEvent': silentModeEvent,
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

  Future<void> requestBackgroundWidgetRefresh() async {
    await _channel.invokeMethod<void>('requestWidgetDataRefresh');
  }

  Future<void> openNotificationPolicySettings() async {
    await _channel.invokeMethod<void>('openNotificationPolicySettings');
  }
}

@pragma('vm:entry-point')
Future<void> prayerWidgetBackgroundRefresh() async {
  WidgetsFlutterBinding.ensureInitialized();
  final scheduler = NativePrayerNotificationScheduler();
  final location = await LocationStorage().read();
  if (location == null) {
    await scheduler.configureWidget(const <NativePrayerWidgetEvent>[]);
    return;
  }

  var methodCode = await CalculationMethodStorage().readCode();
  methodCode ??= CalculationMethodStorage.defaultCode;
  final latitude = double.tryParse(location.latitude);
  final longitude = double.tryParse(location.longitude);
  if ((methodCode != 'turkey' &&
          methodCode != 'diyanet' &&
          methodCode != 'diyanet_tabanli') &&
      (latitude == null || longitude == null)) {
    await scheduler.configureWidget(const <NativePrayerWidgetEvent>[]);
    return;
  }

  final service = PrayerService();
  final now = DateTime.now();
  final firstDate = DateTime(now.year, now.month, now.day);
  final events = <NativePrayerWidgetEvent>[];
  for (var offset = 0; offset < prayerTimesPrefetchDays; offset += 1) {
    final date = firstDate.add(Duration(days: offset));
    try {
      final times = await service.calculateForDate(
        location: location,
        latitude: latitude ?? 0,
        longitude: longitude ?? 0,
        timeZone: location.timeZoneOffset,
        methodCode: methodCode,
        date: date,
        allowDiyanet: methodCode == 'diyanet' || methodCode == 'diyanet_tabanli',
        allowRemote: true,
      );
      _appendBackgroundWidgetEvents(
        events: events,
        times: times,
        date: date,
        now: now,
      );
    } catch (_) {
      // Keep other dates usable when one remote or local data item fails.
    }
  }
  await scheduler.configureWidget(events);
}

void _appendBackgroundWidgetEvents({
  required List<NativePrayerWidgetEvent> events,
  required PrayerTimes times,
  required DateTime date,
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
  final dateLabel = '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';
  for (final entry in prayerTimes.entries) {
    if (!entry.value.isAfter(now)) continue;
    final label = _backgroundPrayerLabel(entry.key);
    events.add(
      NativePrayerWidgetEvent(
        triggerAt: entry.value,
        prayerLabel: label,
        remainingTriggerAt: entry.value,
        remainingPrayerLabel: label,
        dateLabel: dateLabel,
        fajrTime: _backgroundFormatTime(prayerTimes[Prayer.fajr]!),
        sunriseTime: _backgroundFormatTime(prayerTimes[Prayer.sunrise]!),
        dhuhrTime: _backgroundFormatTime(prayerTimes[Prayer.dhuhr]!),
        asrTime: _backgroundFormatTime(prayerTimes[Prayer.asr]!),
        maghribTime: _backgroundFormatTime(prayerTimes[Prayer.maghrib]!),
        ishaTime: _backgroundFormatTime(prayerTimes[Prayer.isha]!),
      ),
    );
  }
}

String _backgroundFormatTime(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String _backgroundPrayerLabel(Prayer prayer) {
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
