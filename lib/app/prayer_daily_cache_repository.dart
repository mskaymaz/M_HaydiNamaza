import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/prayer_engine/calculation_parameters.dart';
import '../core/prayer_engine/coordinates.dart';
import '../core/prayer_engine/prayer_times.dart';
import 'runtime_monitor.dart';

class PrayerDailyCacheRepository {
  static const String _dailyCacheKey = 'prayer_daily_cache_v1';

  Future<PrayerTimes?> read({
    required String fingerprint,
    required Coordinates coordinates,
    required DateTime date,
    required CalculationParameters calculationParameters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyCacheKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final payload = jsonDecode(raw);
      if (payload is! Map<String, dynamic>) {
        await _recoverCorruptCache(
          prefs,
          reasonCode: 'invalid_payload_shape',
        );
        return null;
      }
      if (payload['fingerprint'] != fingerprint) return null;
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
      await prefs.setString(_dailyCacheKey, jsonEncode(payload));
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
    } catch (_) {
      // Ignore secondary remove failures.
    }
    RuntimeMonitor.instance.reportNonFatalCode(
      source: 'prayer_daily_cache_read',
      code: reasonCode,
    );
  }
}
