import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/prayer_engine/prayer.dart';

class PrayerRowSettingsRecord {
  final int reminderMinutes;
  final bool voiceEnabled;
  final bool visualEnabled;
  final bool azanEnabled;
  final bool vibrationEnabled;

  const PrayerRowSettingsRecord({
    required this.reminderMinutes,
    required this.voiceEnabled,
    required this.visualEnabled,
    required this.azanEnabled,
    required this.vibrationEnabled,
  });

  Map<String, dynamic> toJson() {
    return {
      'reminderMinutes': reminderMinutes,
      'voiceEnabled': voiceEnabled,
      'visualEnabled': visualEnabled,
      'azanEnabled': azanEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  static PrayerRowSettingsRecord fromJson(Map<String, dynamic> json) {
    return PrayerRowSettingsRecord(
      reminderMinutes: (json['reminderMinutes'] as num?)?.toInt() ?? 0,
      voiceEnabled: json['voiceEnabled'] == true,
      visualEnabled: json['visualEnabled'] == true,
      azanEnabled: json['azanEnabled'] == true,
      vibrationEnabled: json['vibrationEnabled'] == true,
    );
  }
}

class PrayerRowSettingsStorage {
  static const String _key = 'prayer_row_settings';

  Future<Map<Prayer, PrayerRowSettingsRecord>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return {};
    }
    final result = <Prayer, PrayerRowSettingsRecord>{};
    for (final entry in decoded.entries) {
      Prayer? prayer;
      for (final value in Prayer.values) {
        if (value.name == entry.key) {
          prayer = value;
          break;
        }
      }
      final payload = entry.value;
      if (prayer == null || payload is! Map) {
        continue;
      }
      result[prayer] = PrayerRowSettingsRecord.fromJson(
        Map<String, dynamic>.from(payload),
      );
    }
    return result;
  }

  Future<void> write(Map<Prayer, PrayerRowSettingsRecord> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{};
    for (final entry in settings.entries) {
      payload[entry.key.name] = entry.value.toJson();
    }
    await prefs.setString(_key, jsonEncode(payload));
  }
}
