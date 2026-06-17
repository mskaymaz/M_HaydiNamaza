import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'adhan_catalog.dart';

class AdhanSelectionStorage {
  static const String _key = 'adhan_selections_by_prayer';
  static const String _downloadsKey = 'downloaded_adhan_options';

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

  Future<Map<String, String>> readDownloadedLocalPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_downloadsKey);
    if (raw == null || raw.trim().isEmpty) return <String, String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, String>{};
      final result = <String, String>{};
      decoded.forEach((key, value) {
        final optionId = key.trim();
        final localPath = value?.toString().trim() ?? '';
        if (optionId.isNotEmpty && localPath.isNotEmpty) {
          result[optionId] = localPath;
        }
      });
      return result;
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> writeDownloadedLocalPaths(
    Map<String, String> downloadedLocalPaths,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadsKey, jsonEncode(downloadedLocalPaths));
  }

  Future<void> writeDownloadedOption({
    required String optionId,
    required String localPath,
  }) async {
    final current = await readDownloadedLocalPaths();
    current[optionId] = localPath;
    await writeDownloadedLocalPaths(current);
  }

  Future<void> removeDownloadedOption(String optionId) async {
    final current = await readDownloadedLocalPaths();
    current.remove(optionId);
    await writeDownloadedLocalPaths(current);
  }
}

