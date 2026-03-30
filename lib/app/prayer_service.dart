import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/config_registry.dart';
import '../core/prayer_engine/calculation_method.dart';
import '../core/prayer_engine/calculation_parameters.dart';
import '../core/prayer_engine/coordinates.dart';
import '../core/prayer_engine/prayer_engine.dart';
import '../core/prayer_engine/prayer_times.dart';
import 'location_storage.dart';

class _DiyanetIds {
  final String stateId;
  final String districtId;

  const _DiyanetIds({required this.stateId, required this.districtId});
}

class PrayerService {
  static const Duration _diyanetTimeout = Duration(seconds: 12);
  static const Duration _aladhanTimeout = Duration(seconds: 12);
  static const String _dailyCacheKey = 'prayer_daily_cache_v1';
  static const Map<String, String> _diyanetHeaders = <String, String>{
    'Accept': 'application/json',
    'User-Agent': 'HaydiNamaza/1.0',
  };

  final PrayerEngine _engine;

  static final Map<String, String> _stateIdCache = {};
  static final Map<String, String> _districtIdCache = {};

  PrayerService({PrayerEngine? engine}) : _engine = engine ?? const PrayerEngine();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  Future<PrayerTimes> calculateToday({
    required LocationData location,
    required double latitude,
    required double longitude,
    required String timeZone,
    required String methodCode,
  }) async {
    _log('[Calc] method=$methodCode location=${location.province}/${location.district}');
    final now = DateTime.now();
    final params = _paramsFor(methodCode);
    final fingerprint = _buildCacheFingerprint(
      location: location,
      methodCode: methodCode,
      latitude: latitude,
      longitude: longitude,
      timeZone: timeZone,
      date: now,
    );
    final cached = await _readDailyCache(
      fingerprint: fingerprint,
      coordinates: Coordinates(latitude, longitude),
      date: now,
      calculationParameters: params,
    );
    if (cached != null) {
      _log('[Cache] hit for today');
      return cached;
    }

    final fresh = await _calculateFresh(
      location: location,
      latitude: latitude,
      longitude: longitude,
      timeZone: timeZone,
      methodCode: methodCode,
      date: now,
      params: params,
    );
    await _writeDailyCache(fingerprint: fingerprint, times: fresh);
    return fresh;
  }

  Future<PrayerTimes> _calculateFresh({
    required LocationData location,
    required double latitude,
    required double longitude,
    required String timeZone,
    required String methodCode,
    required DateTime date,
    required CalculationParameters params,
  }) async {
    if (methodCode == 'turkey' || methodCode == 'diyanet_tabanli') {
      final diyanetTimes = await _tryDiyanet(
        location: location,
        date: date,
        fallbackParams: params,
      );
      if (diyanetTimes != null) {
        _log('[Diyanet] ${location.province}/${location.district} '
            'Fajr ${_fmt(diyanetTimes.fajr)} '
            'Sunrise ${_fmt(diyanetTimes.sunrise)} '
            'Dhuhr ${_fmt(diyanetTimes.dhuhr)} '
            'Asr ${_fmt(diyanetTimes.asr)} '
            'Maghrib ${_fmt(diyanetTimes.maghrib)} '
            'Isha ${_fmt(diyanetTimes.isha)}');
        return diyanetTimes;
      }

      final aladhanTurkey = await _tryAladhan(
        date: date,
        latitude: latitude,
        longitude: longitude,
        methodCode: 'turkey',
        school: 1,
        fallbackParams: params,
      );
      if (aladhanTurkey != null) {
        _log('[Aladhan:turkey] '
            'Fajr ${_fmt(aladhanTurkey.fajr)} '
            'Sunrise ${_fmt(aladhanTurkey.sunrise)} '
            'Dhuhr ${_fmt(aladhanTurkey.dhuhr)} '
            'Asr ${_fmt(aladhanTurkey.asr)} '
            'Maghrib ${_fmt(aladhanTurkey.maghrib)} '
            'Isha ${_fmt(aladhanTurkey.isha)}');
        return aladhanTurkey;
      }

      final aladhanShafii = await _tryAladhan(
        date: date,
        latitude: latitude,
        longitude: longitude,
        methodCode: 'turkey',
        school: 0,
        fallbackParams: params,
      );
      if (aladhanShafii != null) {
        _log('[Aladhan:shafii] '
            'Fajr ${_fmt(aladhanShafii.fajr)} '
            'Sunrise ${_fmt(aladhanShafii.sunrise)} '
            'Dhuhr ${_fmt(aladhanShafii.dhuhr)} '
            'Asr ${_fmt(aladhanShafii.asr)} '
            'Maghrib ${_fmt(aladhanShafii.maghrib)} '
            'Isha ${_fmt(aladhanShafii.isha)}');
        return aladhanShafii;
      }
    }

    _log('[Calc] fallback local engine');
    return _engine.calculate(
      date: date,
      coordinates: Coordinates(latitude, longitude),
      timeZone: timeZone,
      params: params,
    );
  }

  Future<PrayerTimes?> _tryAladhan({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String methodCode,
    required int school,
    required CalculationParameters fallbackParams,
  }) async {
    if (!latitude.isFinite || !longitude.isFinite) {
      return null;
    }
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
      final response =
          await http.get(uri, headers: _diyanetHeaders).timeout(_aladhanTimeout);
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

      DateTime? parseTime(String key) {
        final raw = timings[key];
        if (raw is! String) return null;
        final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
        if (match == null) return null;
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        return DateTime(date.year, date.month, date.day, hour, minute);
      }

      final fajr = parseTime('Fajr');
      final sunrise = parseTime('Sunrise');
      final dhuhr = parseTime('Dhuhr');
      final asr = parseTime('Asr');
      final maghrib = parseTime('Maghrib');
      final isha = parseTime('Isha');
      if ([fajr, sunrise, dhuhr, asr, maghrib, isha].contains(null)) {
        return null;
      }

      return PrayerTimes.fromTimings(
        coordinates: Coordinates(latitude, longitude),
        date: date,
        calculationParameters: fallbackParams,
        fajr: fajr!,
        sunrise: sunrise!,
        dhuhr: dhuhr!,
        asr: asr!,
        sunset: maghrib!,
        maghrib: maghrib,
        isha: isha!,
      );
    } catch (_) {
      return null;
    }
  }

  String _buildCacheFingerprint({
    required LocationData location,
    required String methodCode,
    required double latitude,
    required double longitude,
    required String timeZone,
    required DateTime date,
  }) {
    final dayKey = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final countryId = (location.countryId ?? '').trim();
    final province = _normalizeName(location.province);
    final district = _normalizeName(location.district);
    final lat = latitude.toStringAsFixed(4);
    final lon = longitude.toStringAsFixed(4);
    return '$dayKey|$methodCode|$timeZone|$countryId|$province|$district|$lat|$lon';
  }

  Future<PrayerTimes?> _readDailyCache({
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
      if (payload is! Map<String, dynamic>) return null;
      if (payload['fingerprint'] != fingerprint) return null;
      final fajr = DateTime.tryParse((payload['fajr'] ?? '').toString());
      final sunrise = DateTime.tryParse((payload['sunrise'] ?? '').toString());
      final dhuhr = DateTime.tryParse((payload['dhuhr'] ?? '').toString());
      final asr = DateTime.tryParse((payload['asr'] ?? '').toString());
      final maghrib = DateTime.tryParse((payload['maghrib'] ?? '').toString());
      final isha = DateTime.tryParse((payload['isha'] ?? '').toString());
      if ([fajr, sunrise, dhuhr, asr, maghrib, isha].contains(null)) return null;
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
      return null;
    }
  }

  Future<void> _writeDailyCache({
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyCacheKey, jsonEncode(payload));
  }

  CalculationParameters _paramsFor(String code) {
    switch (code) {
      case 'turkey':
      case 'diyanet_tabanli':
        return CalculationMethod.turkey();
      case 'muslim_world_league':
        return CalculationMethod.muslimWorldLeague();
      case 'umm_al_qura':
        return CalculationMethod.ummAlQura();
      case 'dubai':
        return CalculationMethod.dubai();
      case 'kuwait':
        return CalculationMethod.kuwait();
      case 'qatar':
        return CalculationMethod.qatar();
      case 'singapore':
        return CalculationMethod.singapore();
      case 'tehran':
        return CalculationMethod.tehran();
      case 'moonsighting':
        return CalculationMethod.moonsightingCommittee();
      case 'north_america':
        return CalculationMethod.northAmerica();
      case 'egyptian':
        return CalculationMethod.egyptian();
      case 'karachi':
        return CalculationMethod.karachi();
      case 'other':
      default:
        return CalculationMethod.other();
    }
  }

  Future<PrayerTimes?> _tryDiyanet({
    required LocationData location,
    required DateTime date,
    required CalculationParameters fallbackParams,
  }) async {
    if (location.province.trim().isEmpty || location.district.trim().isEmpty) {
      return null;
    }
    final ids = await _resolveDiyanetIds(
      countryId: location.countryId,
      province: location.province,
      district: location.district,
    );
    if (ids == null) {
      _log('[Diyanet] id resolve failed for '
          '${location.province}/${location.district}');
      return null;
    }
    _log('[Diyanet] ids state=${ids.stateId} district=${ids.districtId}');

    final config = ConfigRegistry.dataSources.diyanet;
    final uri = Uri.parse('${config.baseUrl}/api/prayer-times/${ids.districtId}/daily');

    try {
      final response =
          await http.get(uri, headers: _diyanetHeaders).timeout(_diyanetTimeout);
      if (response.statusCode != 200) {
        _log('[Diyanet] prayer-times status=${response.statusCode}');
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
        _log('[Diyanet] empty payload');
        return null;
      }
      final times = entry['times'] as Map<String, dynamic>?;
      if (times == null) {
        _log('[Diyanet] times missing');
        return null;
      }

      final dateValue = entry['date'] as String?;
      final baseDate = DateTime.tryParse(dateValue ?? '')?.toLocal() ?? date;

      DateTime? parseTime(String key) {
        final raw = times[key];
        if (raw is! String) return null;
        final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
        if (match == null) return null;
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
      }

      DateTime applyOffset(DateTime value, String key) {
        final delta = config.minuteOffsets[key] ?? 0;
        if (delta == 0) return value;
        return value.add(Duration(minutes: delta));
      }

      final fajrRaw = parseTime('imsak');
      final sunriseRaw = parseTime('gunes');
      final dhuhrRaw = parseTime('ogle');
      final asrRaw = parseTime('ikindi');
      final maghribRaw = parseTime('aksam');
      final ishaRaw = parseTime('yatsi');
      final fajr = fajrRaw == null ? null : applyOffset(fajrRaw, 'imsak');
      final sunrise = sunriseRaw == null ? null : applyOffset(sunriseRaw, 'gunes');
      final dhuhr = dhuhrRaw == null ? null : applyOffset(dhuhrRaw, 'ogle');
      final asr = asrRaw == null ? null : applyOffset(asrRaw, 'ikindi');
      final maghrib = maghribRaw == null ? null : applyOffset(maghribRaw, 'aksam');
      final isha = ishaRaw == null ? null : applyOffset(ishaRaw, 'yatsi');
      if ([fajr, sunrise, dhuhr, asr, maghrib, isha].contains(null)) {
        _log('[Diyanet] missing times for ${location.province}/${location.district}');
        return null;
      }

      final lat = double.tryParse(location.latitude) ?? 0;
      final lon = double.tryParse(location.longitude) ?? 0;
      return PrayerTimes.fromTimings(
        coordinates: Coordinates(lat, lon),
        date: baseDate,
        calculationParameters: fallbackParams,
        fajr: fajr!,
        sunrise: sunrise!,
        dhuhr: dhuhr!,
        asr: asr!,
        sunset: maghrib!,
        maghrib: maghrib,
        isha: isha!,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_DiyanetIds?> _resolveDiyanetIds({
    required String? countryId,
    required String province,
    required String district,
  }) async {
    final provinceKey = _normalizeName(province);
    final districtKey = _normalizeName(district);
    final config = ConfigRegistry.dataSources.diyanet;
    final resolvedCountryId =
        (countryId != null && countryId.trim().isNotEmpty)
            ? countryId.trim()
            : config.countryId;
    final cachePrefix = '$resolvedCountryId|$provinceKey';
    final cachedState = _stateIdCache[cachePrefix];
    final cachedDistrict = _districtIdCache['$cachePrefix|$districtKey'];
    if (cachedState != null && cachedDistrict != null) {
      return _DiyanetIds(stateId: cachedState, districtId: cachedDistrict);
    }

    final statesUri = Uri.parse('${config.baseUrl}/api/locations/states').replace(
      queryParameters: <String, String>{'countryId': resolvedCountryId},
    );

    try {
      final statesResponse = await http
          .get(statesUri, headers: _diyanetHeaders)
          .timeout(_diyanetTimeout);
      if (statesResponse.statusCode != 200) {
        _log('[Diyanet] states status=${statesResponse.statusCode}');
        return null;
      }
      final statesPayload = jsonDecode(statesResponse.body) as Map<String, dynamic>;
      final statesData = statesPayload['data'];
      if (statesData is! List) {
        return null;
      }
      String? stateId;
      for (final entry in statesData) {
        if (entry is! Map<String, dynamic>) continue;
        final name = entry['name'] ?? entry['name_en'];
        if (name is! String) continue;
        if (_normalizeName(name) == provinceKey) {
          final id = entry['_id'];
          if (id is String) {
            stateId = id;
            break;
          }
          if (id is int) {
            stateId = id.toString();
            break;
          }
        }
      }
      if (stateId == null) {
        _log('[Diyanet] state not found for $province');
        return null;
      }

      final districtsUri = Uri.parse('${config.baseUrl}/api/locations/districts').replace(
        queryParameters: <String, String>{'stateId': stateId},
      );
      final districtsResponse = await http
          .get(districtsUri, headers: _diyanetHeaders)
          .timeout(_diyanetTimeout);
      if (districtsResponse.statusCode != 200) {
        _log('[Diyanet] districts status=${districtsResponse.statusCode}');
        return null;
      }
      final districtsPayload = jsonDecode(districtsResponse.body) as Map<String, dynamic>;
      final districtsData = districtsPayload['data'];
      if (districtsData is! List) {
        return null;
      }
      String? districtId;
      for (final entry in districtsData) {
        if (entry is! Map<String, dynamic>) continue;
        final name = entry['name'] ?? entry['name_en'];
        if (name is! String) continue;
        if (_normalizeName(name) == districtKey) {
          final id = entry['_id'];
          if (id is String) {
            districtId = id;
            break;
          }
          if (id is int) {
            districtId = id.toString();
            break;
          }
        }
      }
      if (districtId == null) {
        _log('[Diyanet] district not found for $province/$district');
        return null;
      }

      _stateIdCache[cachePrefix] = stateId;
      _districtIdCache['$cachePrefix|$districtKey'] = districtId;
      return _DiyanetIds(stateId: stateId, districtId: districtId);
    } catch (_) {
      return null;
    }
  }

  String _normalizeName(String input) {
    final upper = input.trim().toUpperCase();
    final buffer = StringBuffer();
    for (final rune in upper.runes) {
      switch (rune) {
        case 0x00C7: // Ç
          buffer.write('C');
          break;
        case 0x011E: // Ğ
          buffer.write('G');
          break;
        case 0x0130: // İ
          buffer.write('I');
          break;
        case 0x00D6: // Ö
          buffer.write('O');
          break;
        case 0x015E: // Ş
          buffer.write('S');
          break;
        case 0x00DC: // Ü
          buffer.write('U');
          break;
        case 0x00C2: // Â
          buffer.write('A');
          break;
        case 0x00CE: // Î
          buffer.write('I');
          break;
        case 0x00DB: // Û
          buffer.write('U');
          break;
        default:
          buffer.write(String.fromCharCode(rune));
      }
    }
    return buffer.toString().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
