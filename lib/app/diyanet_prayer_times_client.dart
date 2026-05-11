import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/config_registry.dart';
import 'prayer_service_pure_helpers.dart';

class DiyanetDailyTimings {
  final DateTime baseDate;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const DiyanetDailyTimings({
    required this.baseDate,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
}

class DiyanetPrayerTimesClient {
  Future<DiyanetDailyTimings?> fetchDaily({
    required String districtId,
    required String province,
    required String district,
    required DateTime date,
    required Duration timeout,
    required Map<String, String> headers,
    void Function(String message)? onLog,
  }) async {
    final config = ConfigRegistry.dataSources.diyanet;
    final uri = Uri.parse('${config.baseUrl}/api/prayer-times/$districtId/daily');

    try {
      final response = await http.get(uri, headers: headers).timeout(timeout);
      if (response.statusCode != 200) {
        onLog?.call('[Diyanet] prayer-times status=${response.statusCode}');
        return null;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'];
      Map<String, dynamic>? entry;
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map<String, dynamic>) {
          entry = first;
        }
      } else if (data is Map<String, dynamic>) {
        entry = data;
      }
      if (entry == null) {
        onLog?.call('[Diyanet] empty payload');
        return null;
      }
      final times = entry['times'] as Map<String, dynamic>?;
      if (times == null) {
        onLog?.call('[Diyanet] times missing');
        return null;
      }

      final dateValue = entry['date'] as String?;
      final baseDate = DateTime.tryParse(dateValue ?? '')?.toLocal() ?? date;

      final fajrRaw = parsePrayerClockTime(raw: times['imsak'], baseDate: baseDate);
      final sunriseRaw = parsePrayerClockTime(raw: times['gunes'], baseDate: baseDate);
      final dhuhrRaw = parsePrayerClockTime(raw: times['ogle'], baseDate: baseDate);
      final asrRaw = parsePrayerClockTime(raw: times['ikindi'], baseDate: baseDate);
      final maghribRaw = parsePrayerClockTime(raw: times['aksam'], baseDate: baseDate);
      final ishaRaw = parsePrayerClockTime(raw: times['yatsi'], baseDate: baseDate);
      final fajr = fajrRaw == null
          ? null
          : applyPrayerMinuteOffset(fajrRaw, config.minuteOffsets['imsak'] ?? 0);
      final sunrise = sunriseRaw == null
          ? null
          : applyPrayerMinuteOffset(
              sunriseRaw,
              config.minuteOffsets['gunes'] ?? 0,
            );
      final dhuhr = dhuhrRaw == null
          ? null
          : applyPrayerMinuteOffset(dhuhrRaw, config.minuteOffsets['ogle'] ?? 0);
      final asr = asrRaw == null
          ? null
          : applyPrayerMinuteOffset(asrRaw, config.minuteOffsets['ikindi'] ?? 0);
      final maghrib = maghribRaw == null
          ? null
          : applyPrayerMinuteOffset(
              maghribRaw,
              config.minuteOffsets['aksam'] ?? 0,
            );
      final isha = ishaRaw == null
          ? null
          : applyPrayerMinuteOffset(ishaRaw, config.minuteOffsets['yatsi'] ?? 0);
      if ([fajr, sunrise, dhuhr, asr, maghrib, isha].contains(null)) {
        onLog?.call('[Diyanet] missing times for $province/$district');
        return null;
      }

      return DiyanetDailyTimings(
        baseDate: baseDate,
        fajr: fajr!,
        sunrise: sunrise!,
        dhuhr: dhuhr!,
        asr: asr!,
        maghrib: maghrib!,
        isha: isha!,
      );
    } catch (_) {
      return null;
    }
  }
}
