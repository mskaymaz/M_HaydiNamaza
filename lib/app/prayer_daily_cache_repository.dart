import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/prayer_engine/calculation_parameters.dart';
import '../core/prayer_engine/coordinates.dart';
import '../core/prayer_engine/prayer_times.dart';
import 'runtime_monitor.dart';

class PrayerDailyCacheRepository {
  static const String _dailyCacheKey = 'prayer_daily_cache_v2';
  static const String _legacyDailyCacheKey = 'prayer_daily_cache_v1';
  static const int _maxCachedDays = 90;

  Future<PrayerTimes?> read({
    required String fingerprint,
    required Coordinates coordinates,
    required DateTime date,
    required CalculationParameters calculationParameters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyCacheKey);
    final legacyRaw = prefs.getString(_legacyDailyCacheKey);
    if ((raw == null || raw.trim().isEmpty) &&
        (legacyRaw == null || legacyRaw.trim().isEmpty)) {
      return null;
    }
    try {
      Map<String, dynamic>? payload;
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          await _recoverCorruptCache(
            prefs,
            reasonCode: 'invalid_payload_shape',
          );
          return null;
        }
        final entries = decoded['entries'];
        final entry = entries is Map ? entries[fingerprint] : null;
        if (entry is Map) {
          payload = Map<String, dynamic>.from(entry);
        }
      }
      if (payload == null && legacyRaw != null && legacyRaw.trim().isNotEmpty) {
        final legacyPayload = jsonDecode(legacyRaw);
        if (legacyPayload is Map<String, dynamic> &&
            legacyPayload['fingerprint'] == fingerprint) {
          payload = legacyPayload;
        }
      }
      if (payload == null) return null;
      final fajr = DateTime.tryParse((payload['fajr'] ?? '').toString());
      final sunrise = DateTime.tryParse((payload['sunrise'] ?? '').toString());
      final dhuhr = DateTime.tryParse((payload['dhuhr'] ?? '').toString());
      final asr = DateTime.tryParse((payload['asr'] ?? '').toString());
      final maghrib = DateTime.tryParse((payload['maghrib'] ?? '').toString());
      final isha = DateTime.tryParse((payload['isha'] ?? '').toString());
      if ([fajr, sunrise, dhuhr, asr, maghrib, isha].contains(null)) {
        await _recoverCorruptCache(
          prefs,
          reasonCode: 'invalid_time_fields',
        );
        return null;
      }
      return PrayerTimes.fromTimings(
        coordinates: coordinates,
        date: date,
        calculationParameters: calculationParameters,
        fajr: fajr!,
        sunrise: sunrise!,
        dhuhr: dhuhr!,
        asr: asr!,
        sunset: maghrib!,
        maghrib: maghrib,
        isha: isha!,
      );
    } catch (_) {
      await _recoverCorruptCache(
        prefs,
        reasonCode: 'json_decode_failed',
      );
      return null;
    }
  }

  Future<void> write({
    required String fingerprint,
    required PrayerTimes times,
  }) async {
    final payload = <String, dynamic>{
      'fingerprint': fingerprint,
      'savedAt': DateTime.now().toIso8601String(),
      'fajr': times.fajr.toIso8601String(),
      'sunrise': times.sunrise.toIso8601String(),
      'dhuhr': times.dhuhr.toIso8601String(),
      'asr': times.asr.toIso8601String(),
      'maghrib': times.maghrib.toIso8601String(),
      'isha': times.isha.toIso8601String(),
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = <String, dynamic>{};
      final raw = prefs.getString(_dailyCacheKey);
      if (raw != null && raw.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          final storedEntries = decoded is Map ? decoded['entries'] : null;
          if (storedEntries is Map) {
            for (final entry in storedEntries.entries) {
              if (entry.key is String && entry.value is Map) {
                entries[entry.key as String] =
                    Map<String, dynamic>.from(entry.value as Map);
              }
            }
          }
        } catch (_) {}
      }
      entries[fingerprint] = payload;
      if (entries.length > _maxCachedDays) {
        final keysByAge = entries.keys.toList()
          ..sort((left, right) {
            final leftSaved = (entries[left] as Map?)?['savedAt']?.toString() ?? '';
            final rightSaved = (entries[right] as Map?)?['savedAt']?.toString() ?? '';
            return leftSaved.compareTo(rightSaved);
          });
        for (final key in keysByAge.take(entries.length - _maxCachedDays)) {
          entries.remove(key);
        }
      }
      await prefs.setString(
        _dailyCacheKey,
        jsonEncode(<String, dynamic>{'entries': entries}),
      );
    } catch (_) {
      RuntimeMonitor.instance.reportNonFatalCode(
        source: 'prayer_daily_cache_write',
        code: 'cache_write_failed',
      );
      // Keep calculation flow intact even if cache write fails.
    }
  }

  Future<void> _recoverCorruptCache(
    SharedPreferences prefs, {
    required String reasonCode,
  }) async {
    try {
      await prefs.remove(_dailyCacheKey);
      await prefs.remove(_legacyDailyCacheKey);
    } catch (_) {
      // Ignore secondary remove failures.
    }
    RuntimeMonitor.instance.reportNonFatalCode(
      source: 'prayer_daily_cache_read',
      code: reasonCode,
    );
  }
}
