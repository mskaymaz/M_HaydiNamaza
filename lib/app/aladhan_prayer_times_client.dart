import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/config_registry.dart';
import 'prayer_service_pure_helpers.dart';

class AladhanDailyTimings {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  const AladhanDailyTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
}

class AladhanPrayerTimesClient {
  Future<AladhanDailyTimings?> fetchDaily({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String methodCode,
    required int school,
    required Duration timeout,
    required Map<String, String> headers,
  }) async {
    final config = ConfigRegistry.dataSources.aladhan;
    final methodId = config.methodIds[methodCode];
    if (methodId == null) {
      return null;
    }

    final datePath =
        '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString().padLeft(4, '0')}';
    final query = <String, String>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': methodId.toString(),
      'school': school.toString(),
      'timezonestring': config.timeZone,
    };
    if (config.tune.trim().isNotEmpty) {
      query['tune'] = config.tune;
    }
    if (config.shafaq.trim().isNotEmpty) {
      query['shafaq'] = config.shafaq;
    }
    final uri =
        Uri.parse('${config.baseUrl}/timings/$datePath').replace(queryParameters: query);

    try {
      final response = await http.get(uri, headers: headers).timeout(timeout);
      if (response.statusCode != 200) {
        return null;
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        return null;
      }
      final data = payload['data'];
      if (data is! Map<String, dynamic>) {
        return null;
      }
      final timings = data['timings'];
      if (timings is! Map<String, dynamic>) {
        return null;
      }

      final fajr = parsePrayerClockTime(raw: timings['Fajr'], baseDate: date);
      final sunrise = parsePrayerClockTime(raw: timings['Sunrise'], baseDate: date);
      final dhuhr = parsePrayerClockTime(raw: timings['Dhuhr'], baseDate: date);
      final asr = parsePrayerClockTime(raw: timings['Asr'], baseDate: date);
      final maghrib = parsePrayerClockTime(raw: timings['Maghrib'], baseDate: date);
      final isha = parsePrayerClockTime(raw: timings['Isha'], baseDate: date);
      if ([fajr, sunrise, dhuhr, asr, maghrib, isha].contains(null)) {
        return null;
      }

      return AladhanDailyTimings(
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
