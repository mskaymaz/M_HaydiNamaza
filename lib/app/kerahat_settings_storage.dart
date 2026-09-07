import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_monitor.dart';

class KerahatSettingsRecord {
  final bool enabled;
  final int sunriseMinutes;
  final int dhuhrMinutes;
  final int maghribMinutes;

  const KerahatSettingsRecord({
    this.enabled = true,
    this.sunriseMinutes = 45,
    this.dhuhrMinutes = 45,
    this.maghribMinutes = 45,
  });

  KerahatSettingsRecord copyWith({
    bool? enabled,
    int? sunriseMinutes,
    int? dhuhrMinutes,
    int? maghribMinutes,
  }) {
    return KerahatSettingsRecord(
      enabled: enabled ?? this.enabled,
      sunriseMinutes: sunriseMinutes ?? this.sunriseMinutes,
      dhuhrMinutes: dhuhrMinutes ?? this.dhuhrMinutes,
      maghribMinutes: maghribMinutes ?? this.maghribMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'sunriseMinutes': sunriseMinutes,
      'dhuhrMinutes': dhuhrMinutes,
      'maghribMinutes': maghribMinutes,
    };
  }

  static KerahatSettingsRecord fromJson(Map<String, dynamic> json) {
    return KerahatSettingsRecord(
      enabled: json['enabled'] != false,
      sunriseMinutes: (json['sunriseMinutes'] as num?)?.toInt() ?? 45,
      dhuhrMinutes: (json['dhuhrMinutes'] as num?)?.toInt() ?? 45,
      maghribMinutes: (json['maghribMinutes'] as num?)?.toInt() ?? 45,
    );
  }
}

class KerahatSettingsStorage {
  static const String _key = 'kerahat_settings';

  Future<KerahatSettingsRecord> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) {
        return const KerahatSettingsRecord();
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const KerahatSettingsRecord();
      }
      return KerahatSettingsRecord.fromJson(decoded);
    } catch (_) {
      return const KerahatSettingsRecord();
    }
  }

  Future<void> write(KerahatSettingsRecord settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(settings.toJson()));
    } catch (_) {
      RuntimeMonitor.instance.reportNonFatalCode(
        source: 'kerahat_settings_storage_write',
        code: 'state_write_failed',
      );
    }
  }
}
