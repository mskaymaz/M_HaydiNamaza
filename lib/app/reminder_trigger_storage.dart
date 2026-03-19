import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ReminderTriggerStorage {
  static const String _key = 'prayer_reminder_trigger_log';

  Future<Map<String, String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return {};
    }
    final result = <String, String>{};
    for (final entry in decoded.entries) {
      final value = entry.value?.toString() ?? '';
      if (entry.key.trim().isEmpty || value.isEmpty) continue;
      result[entry.key] = value;
    }
    return result;
  }

  Future<void> write(Map<String, String> values) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, String>{};
    for (final entry in values.entries) {
      payload[entry.key] = entry.value;
    }
    await prefs.setString(_key, jsonEncode(payload));
  }
}
