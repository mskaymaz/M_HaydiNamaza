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
  final double? latitude;
  final double? longitude;

  const AladhanDailyTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.latitude,
    this.longitude,
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
    if (methodId == null) return null;

    final uri = Uri.parse('${config.baseUrl}/timings/${_datePath(date)}')
        .replace(
          queryParameters: _timingQuery(
            methodId: methodId,
            school: school,
            extras: <String, String>{
              'latitude': latitude.toString(),
              'longitude': longitude.toString(),
            },
          ),
        );
    return _fetchAndParse(
      uri: uri,
      date: date,
      timeout: timeout,
      headers: headers,
      fallbackLatitude: latitude,
      fallbackLongitude: longitude,
    );
  }

  Future<AladhanDailyTimings?> fetchDailyByCity({
    required DateTime date,
    required String city,
    required String country,
    required String methodCode,
    required int school,
    required Duration timeout,
    required Map<String, String> headers,
  }) async {
    final normalizedCity = city.trim();
    final normalizedCountry = country.trim();
    if (normalizedCity.isEmpty || normalizedCountry.isEmpty) return null;

    final config = ConfigRegistry.dataSources.aladhan;
    final methodId = config.methodIds[methodCode];
    if (methodId == null) return null;

    final uri = Uri.parse('${config.baseUrl}/timingsByCity/${_datePath(date)}')
        .replace(
          queryParameters: _timingQuery(
            methodId: methodId,
            school: school,
            extras: <String, String>{
              'city': normalizedCity,
              'country': normalizedCountry,
            },
          ),
        );
    return _fetchAndParse(
      uri: uri,
      date: date,
      timeout: timeout,
      headers: headers,
    );
  }

  Future<AladhanDailyTimings?> _fetchAndParse({
    required Uri uri,
    required DateTime date,
    required Duration timeout,
    required Map<String, String> headers,
    double? fallbackLatitude,
    double? fallbackLongitude,
  }) async {
    try {
      final response = await http.get(uri, headers: headers).timeout(timeout);
      if (response.statusCode != 200) return null;
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) return null;
      final data = payload['data'];
      if (data is! Map<String, dynamic>) return null;
      final timings = data['timings'];
      if (timings is! Map<String, dynamic>) return null;

      final fajr = parsePrayerClockTime(raw: timings['Fajr'], baseDate: date);
      final sunrise = parsePrayerClockTime(
        raw: timings['Sunrise'],
        baseDate: date,
      );
      final dhuhr = parsePrayerClockTime(raw: timings['Dhuhr'], baseDate: date);
      final asr = parsePrayerClockTime(raw: timings['Asr'], baseDate: date);
      final maghrib = parsePrayerClockTime(
        raw: timings['Maghrib'],
        baseDate: date,
      );
      final isha = parsePrayerClockTime(raw: timings['Isha'], baseDate: date);
      if ([fajr, sunrise, dhuhr, asr, maghrib, isha].contains(null)) {
        return null;
      }
      final meta = data['meta'];
      final latitude = meta is Map<String, dynamic>
          ? _readDouble(meta['latitude']) ?? fallbackLatitude
          : fallbackLatitude;
      final longitude = meta is Map<String, dynamic>
          ? _readDouble(meta['longitude']) ?? fallbackLongitude
          : fallbackLongitude;

      return AladhanDailyTimings(
        fajr: fajr!,
        sunrise: sunrise!,
        dhuhr: dhuhr!,
        asr: asr!,
        maghrib: maghrib!,
        isha: isha!,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _timingQuery({
    required int methodId,
    required int school,
    required Map<String, String> extras,
  }) {
    final config = ConfigRegistry.dataSources.aladhan;
    final query = <String, String>{
      ...extras,
      'method': methodId.toString(),
      'school': school.toString(),
      'timezonestring': config.timeZone,
    };
    if (config.tune.trim().isNotEmpty) query['tune'] = config.tune;
    if (config.shafaq.trim().isNotEmpty) query['shafaq'] = config.shafaq;
    return query;
  }

  String _datePath(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  double? _readDouble(Object? value) {
    if (value == null) return null;
    return double.tryParse(value.toString().trim());
  }
}
