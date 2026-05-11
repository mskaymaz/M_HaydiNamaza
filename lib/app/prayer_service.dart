import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'calculation_advanced_settings_storage.dart';
import 'diyanet_location_id_resolver.dart';
import 'diyanet_prayer_times_client.dart';
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
  final DiyanetLocationIdResolver _diyanetLocationIdResolver;
  final DiyanetPrayerTimesClient _diyanetPrayerTimesClient;

  static String? _memoryCacheFingerprint;
  static PrayerTimes? _memoryCacheTimes;

  PrayerService({
    PrayerEngine? engine,
    CalculationAdvancedSettingsStorage? advancedSettingsStorage,
    PrayerDailyCacheRepository? dailyCacheRepository,
    DiyanetLocationIdResolver? diyanetLocationIdResolver,
    DiyanetPrayerTimesClient? diyanetPrayerTimesClient,
  }) : _engine = engine ?? const PrayerEngine(),
       _advancedSettingsStorage =
           advancedSettingsStorage ?? CalculationAdvancedSettingsStorage(),
       _dailyCacheRepository =
           dailyCacheRepository ?? PrayerDailyCacheRepository(),
       _diyanetLocationIdResolver =
           diyanetLocationIdResolver ?? DiyanetLocationIdResolver(),
       _diyanetPrayerTimesClient =
           diyanetPrayerTimesClient ?? DiyanetPrayerTimesClient();

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
    final ids = await _diyanetLocationIdResolver.resolve(
      countryId: location.countryId,
      province: location.province,
      district: location.district,
      timeout: _diyanetTimeout,
      headers: _diyanetHeaders,
      onLog: _log,
    );
    if (ids == null) {
      _log('[Diyanet] id resolve failed for '
          '${location.province}/${location.district}');
      return null;
    }
    _log('[Diyanet] ids state=${ids.stateId} district=${ids.districtId}');

    try {
      final daily = await _diyanetPrayerTimesClient.fetchDaily(
        districtId: ids.districtId,
        province: location.province,
        district: location.district,
        date: date,
        timeout: _diyanetTimeout,
        headers: _diyanetHeaders,
        onLog: _log,
      );
      if (daily == null) {
        return null;
      }

      final lat = double.tryParse(location.latitude) ?? 0;
      final lon = double.tryParse(location.longitude) ?? 0;
      return PrayerTimes.fromTimings(
        coordinates: Coordinates(lat, lon),
        date: daily.baseDate,
        calculationParameters: fallbackParams,
        fajr: daily.fajr,
        sunrise: daily.sunrise,
        dhuhr: daily.dhuhr,
        asr: daily.asr,
        sunset: daily.maghrib,
        maghrib: daily.maghrib,
        isha: daily.isha,
      );
    } catch (_) {
      return null;
    }
  }

}

