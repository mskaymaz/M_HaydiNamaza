import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'adhan_catalog.dart';

class AdhanSelectionStorage {
  static const String _key = 'adhan_selections_by_prayer';

  Future<Map<String, AdhanSelection>> read() async {
    final defaults = defaultAdhanSelections();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return defaults;
      final result = Map<String, AdhanSelection>.from(defaults);
      for (final slot in kMainAdhanPrayerSlots) {
        final payload = decoded[slot.key];
        if (payload is Map) {
          result[slot.key] = AdhanSelection.fromJson(
            Map<String, dynamic>.from(payload),
          );
        }
      }
      return result;
    } catch (_) {
      return defaults;
    }
  }

  Future<void> write(Map<String, AdhanSelection> selections) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{};
    for (final slot in kMainAdhanPrayerSlots) {
      payload[slot.key] = adhanSelectionForPrayer(
        selections,
        slot.key,
      ).toJson();
    }
    await prefs.setString(_key, jsonEncode(payload));
  }

  Future<void> writeForPrayer({
    required String prayerKey,
    required AdhanSelection selection,
  }) async {
    final current = await read();
    current[prayerKey] = selection;
    await write(current);
  }
}
