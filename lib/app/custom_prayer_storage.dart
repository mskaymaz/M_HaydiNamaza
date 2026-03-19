import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/prayer_engine/prayer.dart';

class CustomPrayerRecord {
  final String id;
  final String label;
  final int reminderMinutes;
  final bool voiceEnabled;
  final bool visualEnabled;
  final bool azanEnabled;
  final bool vibrationEnabled;
  final String timeMode;
  final Prayer? anchorPrayer;
  final Prayer? secondaryAnchorPrayer;
  final int offsetMinutes;
  final int? manualHour;
  final int? manualMinute;

  const CustomPrayerRecord({
    required this.id,
    required this.label,
    required this.reminderMinutes,
    required this.voiceEnabled,
    required this.visualEnabled,
    required this.azanEnabled,
    required this.vibrationEnabled,
    required this.timeMode,
    required this.anchorPrayer,
    required this.secondaryAnchorPrayer,
    required this.offsetMinutes,
    required this.manualHour,
    required this.manualMinute,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'reminderMinutes': reminderMinutes,
      'voiceEnabled': voiceEnabled,
      'visualEnabled': visualEnabled,
      'azanEnabled': azanEnabled,
      'vibrationEnabled': vibrationEnabled,
      'timeMode': timeMode,
      'anchorPrayer': anchorPrayer?.name,
      'secondaryAnchorPrayer': secondaryAnchorPrayer?.name,
      'offsetMinutes': offsetMinutes,
      'manualHour': manualHour,
      'manualMinute': manualMinute,
    };
  }

  static CustomPrayerRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final payload = Map<String, dynamic>.from(json);
    return CustomPrayerRecord(
      id: (payload['id'] as String? ?? '').trim(),
      label: (payload['label'] as String? ?? '').trim(),
      reminderMinutes: (payload['reminderMinutes'] as num?)?.toInt() ?? 0,
      voiceEnabled: payload['voiceEnabled'] == true,
      visualEnabled: payload['visualEnabled'] == true,
      azanEnabled: payload['azanEnabled'] == true,
      vibrationEnabled: payload['vibrationEnabled'] == true,
      timeMode: (payload['timeMode'] as String? ?? '').trim(),
      anchorPrayer: _prayerFromName(payload['anchorPrayer'] as String?),
      secondaryAnchorPrayer: _prayerFromName(
        payload['secondaryAnchorPrayer'] as String?,
      ),
      offsetMinutes: (payload['offsetMinutes'] as num?)?.toInt() ?? 0,
      manualHour: (payload['manualHour'] as num?)?.toInt(),
      manualMinute: (payload['manualMinute'] as num?)?.toInt(),
    );
  }

  static Prayer? _prayerFromName(String? name) {
    final key = (name ?? '').trim();
    if (key.isEmpty) return null;
    for (final prayer in Prayer.values) {
      if (prayer.name == key) return prayer;
    }
    return null;
  }
}

class CustomPrayerStorage {
  static const String _key = 'custom_prayer_rows';

  Future<List<CustomPrayerRecord>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final result = <CustomPrayerRecord>[];
    for (final entry in decoded) {
      final record = CustomPrayerRecord.fromJson(entry);
      if (record == null || record.id.isEmpty) continue;
      result.add(record);
    }
    return result;
  }

  Future<void> write(List<CustomPrayerRecord> rows) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = rows.map((row) => row.toJson()).toList();
    await prefs.setString(_key, jsonEncode(payload));
  }
}
