import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'calculation_advanced_settings_storage.dart';
import 'prayer_calculation_parameters_factory.dart';
import 'prayer_daily_cache_repository.dart';
import '../core/config/config_registry.dart';
import '../core/prayer_engine/calculation_parameters.dart';
import '../core/prayer_engine/coordinates.dart';
import '../core/prayer_engine/prayer_engine.dart';
import '../core/prayer_engine/prayer_times.dart';
import 'location_storage.dart';
import 'prayer_service_pure_helpers.dart';
import 'runtime_monitor.dart';

class PrayerService {
  static const Duration _diyanetTimeout = Duration(seconds: 12);
  static const Duration _aladhanTimeout = Duration(seconds: 12);
  static const Map<String, String> _diyanetHeaders = <String, String>{
    'Accept': 'application/json',
    'User-Agent': 'HaydiNamaza/1.0',
  };

  final PrayerEngine _engine;
  final CalculationAdvancedSettingsStorage _advancedSettingsStorage;
  final PrayerDailyCacheRepository _dailyCacheRepository;

  static final Map<String, String> _stateIdCache = {};
  static final Map<String, String> _districtIdCache = {};
  static String? _memoryCacheFingerprint;
  static PrayerTimes? _memoryCacheTimes;

  PrayerService({
    PrayerEngine? engine,
    CalculationAdvancedSettingsStorage? advancedSettingsStorage,
    PrayerDailyCacheRepository? dailyCacheRepository,
  }) : _engine = engine ?? const PrayerEngine(),
       _advancedSettingsStorage =
           advancedSettingsStorage ?? CalculationAdvancedSettingsStorage(),
       _dailyCacheRepository =
           dailyCacheRepository ?? PrayerDailyCacheRepository();

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
    return RuntimeMonitor.instance.profileAsync('prayer_calculate_today', () async {
      _log('[Calc] method=$methodCode location=${location.province}/${location.district}');
      final now = DateTime.now();
      final advancedSettings = await _advancedSettingsStorage.read();
      final params = PrayerCalculationParametersFactory.build(
        methodCode: methodCode,
        advancedSettings: advancedSettings,
      );
      final fingerprint = _buildCacheFingerprint(
        location: location,
        methodCode: methodCode,
        latitude: latitude,
        longitude: longitude,
        timeZone: timeZone,
        date: now,
        advancedSettings: advancedSettings,
      );
      if (_memoryCacheFingerprint == fingerprint && _memoryCacheTimes != null) {
        _log('[Cache] memory hit for today');
        return _memoryCacheTimes!;
      }
      final cached = await _dailyCacheRepository.read(
        fingerprint: fingerprint,
        coordinates: Coordinates(latitude, longitude),
        date: now,
        calculationParameters: params,
      );
      if (cached != null) {
        _log('[Cache] persistent hit for today');
        _memoryCacheFingerprint = fingerprint;
        _memoryCacheTimes = cached;
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
      await _dailyCacheRepository.write(fingerprint: fingerprint, times: fresh);
      _memoryCacheFingerprint = fingerprint;
      _memoryCacheTimes = fresh;
      return fresh;
    });
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
            'Fajr ${formatPrayerTimeHourMinute(diyanetTimes.fajr)} '
            'Sunrise ${formatPrayerTimeHourMinute(diyanetTimes.sunrise)} '
            'Dhuhr ${formatPrayerTimeHourMinute(diyanetTimes.dhuhr)} '
            'Asr ${formatPrayerTimeHourMinute(diyanetTimes.asr)} '
            'Maghrib ${formatPrayerTimeHourMinute(diyanetTimes.maghrib)} '
            'Isha ${formatPrayerTimeHourMinute(diyanetTimes.isha)}');
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
            'Fajr ${formatPrayerTimeHourMinute(aladhanTurkey.fajr)} '
            'Sunrise ${formatPrayerTimeHourMinute(aladhanTurkey.sunrise)} '
            'Dhuhr ${formatPrayerTimeHourMinute(aladhanTurkey.dhuhr)} '
            'Asr ${formatPrayerTimeHourMinute(aladhanTurkey.asr)} '
            'Maghrib ${formatPrayerTimeHourMinute(aladhanTurkey.maghrib)} '
            'Isha ${formatPrayerTimeHourMinute(aladhanTurkey.isha)}');
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
            'Fajr ${formatPrayerTimeHourMinute(aladhanShafii.fajr)} '
            'Sunrise ${formatPrayerTimeHourMinute(aladhanShafii.sunrise)} '
            'Dhuhr ${formatPrayerTimeHourMinute(aladhanShafii.dhuhr)} '
            'Asr ${formatPrayerTimeHourMinute(aladhanShafii.asr)} '
            'Maghrib ${formatPrayerTimeHourMinute(aladhanShafii.maghrib)} '
            'Isha ${formatPrayerTimeHourMinute(aladhanShafii.isha)}');
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

      final fajr = parsePrayerClockTime(raw: timings['Fajr'], baseDate: date);
      final sunrise = parsePrayerClockTime(raw: timings['Sunrise'], baseDate: date);
      final dhuhr = parsePrayerClockTime(raw: timings['Dhuhr'], baseDate: date);
      final asr = parsePrayerClockTime(raw: timings['Asr'], baseDate: date);
      final maghrib = parsePrayerClockTime(raw: timings['Maghrib'], baseDate: date);
      final isha = parsePrayerClockTime(raw: timings['Isha'], baseDate: date);
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
    required CalculationAdvancedSettings advancedSettings,
  }) {
    final dayKey = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final countryId = (location.countryId ?? '').trim();
    final province = normalizePrayerLocationName(location.province);
    final district = normalizePrayerLocationName(location.district);
    final lat = latitude.toStringAsFixed(4);
    final lon = longitude.toStringAsFixed(4);
    final offsets = [
      advancedSettings.fajrOffsetMinutes,
      advancedSettings.sunriseOffsetMinutes,
      advancedSettings.dhuhrOffsetMinutes,
      advancedSettings.asrOffsetMinutes,
      advancedSettings.maghribOffsetMinutes,
      advancedSettings.ishaOffsetMinutes,
    ].join(',');
    return '$dayKey|$methodCode|$timeZone|$countryId|$province|$district|$lat|$lon'
        '|${advancedSettings.madhabCode}|${advancedSettings.highLatitudeRuleCode}'
        '|${advancedSettings.shafaqCode}|${advancedSettings.roundingCode}|$offsets';
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

  Future<DiyanetIds?> _resolveDiyanetIds({
    required String? countryId,
    required String province,
    required String district,
  }) async {
    final provinceKey = normalizePrayerLocationName(province);
    final districtKey = normalizePrayerLocationName(district);
    final config = ConfigRegistry.dataSources.diyanet;
    final resolvedCountryId =
        (countryId != null && countryId.trim().isNotEmpty)
            ? countryId.trim()
            : config.countryId;
    final cachePrefix = '$resolvedCountryId|$provinceKey';
    final cachedState = _stateIdCache[cachePrefix];
    final cachedDistrict = _districtIdCache['$cachePrefix|$districtKey'];
    if (cachedState != null && cachedDistrict != null) {
      return DiyanetIds(stateId: cachedState, districtId: cachedDistrict);
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
      final stateId = findDiyanetEntryIdByNormalizedName(statesData, provinceKey);
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
      final districtId = findDiyanetEntryIdByNormalizedName(
        districtsData,
        districtKey,
      );
      if (districtId == null) {
        _log('[Diyanet] district not found for $province/$district');
        return null;
      }

      _stateIdCache[cachePrefix] = stateId;
      _districtIdCache['$cachePrefix|$districtKey'] = districtId;
      return DiyanetIds(stateId: stateId, districtId: districtId);
    } catch (_) {
      return null;
    }
  }

}

