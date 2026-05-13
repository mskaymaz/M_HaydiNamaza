import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_monitor.dart';

class ReminderTriggerStorage {
  static const String _key = 'prayer_reminder_trigger_log';

  Future<Map<String, String>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) {
        return {};
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _recoverCorruptState(prefs, 'invalid_payload_shape');
        return {};
      }
      final result = <String, String>{};
      for (final entry in decoded.entries) {
        final value = entry.value?.toString() ?? '';
        if (entry.key.trim().isEmpty || value.isEmpty) continue;
        result[entry.key] = value;
      }
      return result;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await _recoverCorruptState(prefs, 'json_decode_failed');
      return {};
    }
  }

  Future<void> write(Map<String, String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, String>{};
      for (final entry in values.entries) {
        payload[entry.key] = entry.value;
      }
      await prefs.setString(_key, jsonEncode(payload));
    } catch (_) {
      RuntimeMonitor.instance.reportNonFatalCode(
        source: 'reminder_trigger_storage_write',
        code: 'state_write_failed',
      );
    }
  }

  Future<void> _recoverCorruptState(SharedPreferences prefs, String code) async {
    try {
      await prefs.remove(_key);
    } catch (_) {}
    RuntimeMonitor.instance.reportNonFatalCode(
      source: 'reminder_trigger_storage_read',
      code: code,
    );
  }
}
