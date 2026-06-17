import 'package:flutter/foundation.dart';

import 'aladhan_prayer_times_client.dart';
import 'calculation_advanced_settings_storage.dart';
import 'diyanet_location_id_resolver.dart';
import 'diyanet_prayer_times_client.dart';
import 'prayer_cache_fingerprint_builder.dart';
import 'prayer_calculation_parameters_factory.dart';
import 'prayer_daily_cache_repository.dart';
import 'prayer_times_mapper.dart';
import '../core/config/config_registry.dart';
import '../core/prayer_engine/calculation_parameters.dart';
import '../core/prayer_engine/coordinates.dart';
import '../core/prayer_engine/madhab.dart';
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
  final AladhanPrayerTimesClient _aladhanPrayerTimesClient;

  static String? _memoryCacheFingerprint;
  static PrayerTimes? _memoryCacheTimes;

  PrayerService({
    PrayerEngine? engine,
    CalculationAdvancedSettingsStorage? advancedSettingsStorage,
    PrayerDailyCacheRepository? dailyCacheRepository,
    DiyanetLocationIdResolver? diyanetLocationIdResolver,
    DiyanetPrayerTimesClient? diyanetPrayerTimesClient,
    AladhanPrayerTimesClient? aladhanPrayerTimesClient,
  }) : _engine = engine ?? const PrayerEngine(),
       _advancedSettingsStorage =
           advancedSettingsStorage ?? CalculationAdvancedSettingsStorage(),
       _dailyCacheRepository =
           dailyCacheRepository ?? PrayerDailyCacheRepository(),
       _diyanetLocationIdResolver =
           diyanetLocationIdResolver ?? DiyanetLocationIdResolver(),
       _diyanetPrayerTimesClient =
           diyanetPrayerTimesClient ?? DiyanetPrayerTimesClient(),
       _aladhanPrayerTimesClient =
           aladhanPrayerTimesClient ?? AladhanPrayerTimesClient();

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
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
      final fingerprint = PrayerCacheFingerprintBuilder.build(
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

  Future<PrayerTimes> calculateForDate({
    required LocationData location,
    required double latitude,
    required double longitude,
    required String timeZone,
    required String methodCode,
    required DateTime date,
    bool allowDiyanet = true,
    bool allowRemote = true,
  }) async {
    final today = DateTime.now();
    if (allowRemote && allowDiyanet && _isSameLocalDay(date, today)) {
      return calculateToday(
        location: location,
        latitude: latitude,
        longitude: longitude,
        timeZone: timeZone,
        methodCode: methodCode,
      );
    }

    final advancedSettings = await _advancedSettingsStorage.read();
    final params = PrayerCalculationParametersFactory.build(
      methodCode: methodCode,
      advancedSettings: advancedSettings,
    );
    final fingerprint = PrayerCacheFingerprintBuilder.build(
      location: location,
      methodCode: methodCode,
      latitude: latitude,
      longitude: longitude,
      timeZone: timeZone,
      date: date,
      advancedSettings: advancedSettings,
    );
    final cached = await _dailyCacheRepository.read(
      fingerprint: fingerprint,
      coordinates: Coordinates(latitude, longitude),
      date: date,
      calculationParameters: params,
    );
    if (cached != null) return cached;

    final fresh = await _calculateFresh(
      location: location,
      latitude: latitude,
      longitude: longitude,
      timeZone: timeZone,
      methodCode: methodCode,
      date: date,
      params: params,
      allowDiyanet: allowDiyanet,
      allowRemote: allowRemote,
    );
    await _dailyCacheRepository.write(fingerprint: fingerprint, times: fresh);
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
    bool allowDiyanet = true,
    bool allowRemote = true,
  }) async {
    if (!allowRemote) {
      return _calculateLocally(date, latitude, longitude, timeZone, params);
    }

    if (_isDiyanetMethod(methodCode)) {
      final diyanetTimes = await _tryDiyanetForToday(
        allowDiyanet: allowDiyanet,
        location: location,
        date: date,
        fallbackParams: params,
      );
      if (diyanetTimes != null) return diyanetTimes;
      final cityTimes = await _tryAladhanByLocation(
        date: date,
        location: location,
        methodCode: _aladhanMethodCodeFor(methodCode),
        school: _aladhanSchoolFor(params),
        fallbackParams: params,
      );
      if (cityTimes != null) return cityTimes;
    } else if (_isAladhanBackedMethod(methodCode)) {
      if (location.hasUsableCoordinates) {
        final remoteTimes = await _tryAladhan(
          date: date,
          latitude: latitude,
          longitude: longitude,
          methodCode: methodCode,
          school: _aladhanSchoolFor(params),
          fallbackParams: params,
        );
        if (remoteTimes != null) return remoteTimes;
      }
      final cityTimes = await _tryAladhanByLocation(
        date: date,
        location: location,
        methodCode: methodCode,
        school: _aladhanSchoolFor(params),
        fallbackParams: params,
      );
      if (cityTimes != null) return cityTimes;
    } else if (!location.hasUsableCoordinates && _canUseDiyanetLocation(location)) {
      final diyanetTimes = await _tryDiyanetForToday(
        allowDiyanet: allowDiyanet,
        location: location,
        date: date,
        fallbackParams: params,
      );
      if (diyanetTimes != null) return diyanetTimes;
      final cityTimes = await _tryAladhanByLocation(
        date: date,
        location: location,
        methodCode: _aladhanMethodCodeFor(methodCode),
        school: _aladhanSchoolFor(params),
        fallbackParams: params,
      );
      if (cityTimes != null) return cityTimes;
    }

    if (!location.hasUsableCoordinates) {
      final cityTimes = await _tryAladhanByLocation(
        date: date,
        location: location,
        methodCode: _aladhanMethodCodeFor(methodCode),
        school: _aladhanSchoolFor(params),
        fallbackParams: params,
      );
      if (cityTimes != null) return cityTimes;
    }

    _log('[Calc] fallback local engine');
    return _calculateLocally(date, latitude, longitude, timeZone, params);
  }

  PrayerTimes _calculateLocally(
    DateTime date,
    double latitude,
    double longitude,
    String timeZone,
    CalculationParameters params,
  ) {
    return _engine.calculate(
      date: date,
      coordinates: Coordinates(latitude, longitude),
      timeZone: timeZone,
      params: params,
    );
  }

  Future<PrayerTimes?> _tryDiyanetForToday({
    required bool allowDiyanet,
    required LocationData location,
    required DateTime date,
    required CalculationParameters fallbackParams,
  }) async {
    if (!allowDiyanet || !_isSameLocalDay(date, DateTime.now())) return null;
    final times = await _tryDiyanet(
      location: location,
      date: date,
      fallbackParams: fallbackParams,
    );
    if (times != null) _logTimes('[Diyanet]', location, times);
    return times;
  }

  bool _isDiyanetMethod(String methodCode) {
    return methodCode == 'diyanet' || methodCode == 'diyanet_tabanli';
  }

  bool _isAladhanBackedMethod(String methodCode) {
    return ConfigRegistry.dataSources.aladhan.methodIds.containsKey(methodCode);
  }

  String _aladhanMethodCodeFor(String methodCode) {
    if (_isAladhanBackedMethod(methodCode)) return methodCode;
    return 'aladhan';
  }

  bool _canUseDiyanetLocation(LocationData location) {
    return location.province.trim().isNotEmpty &&
        location.district.trim().isNotEmpty &&
        (location.countryId == null ||
            location.countryId == ConfigRegistry.dataSources.diyanet.countryId);
  }

  bool _isSameLocalDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  int _aladhanSchoolFor(CalculationParameters params) {
    return params.madhab == Madhab.hanafi ? 1 : 0;
  }

  Future<PrayerTimes?> _tryAladhan({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String methodCode,
    required int school,
    required CalculationParameters fallbackParams,
  }) async {
    if (!latitude.isFinite || !longitude.isFinite) return null;
    final daily = await _aladhanPrayerTimesClient.fetchDaily(
      date: date,
      latitude: latitude,
      longitude: longitude,
      methodCode: methodCode,
      school: school,
      timeout: _aladhanTimeout,
      headers: _diyanetHeaders,
    );
    if (daily == null) return null;
    final times = PrayerTimesMapper.fromAladhanDaily(
      daily: daily,
      date: date,
      latitude: latitude,
      longitude: longitude,
      calculationParameters: fallbackParams,
    );
    _logTimes('[Aladhan:$methodCode coordinates]', null, times);
    return times;
  }

  Future<PrayerTimes?> _tryAladhanByLocation({
    required DateTime date,
    required LocationData location,
    required String methodCode,
    required int school,
    required CalculationParameters fallbackParams,
  }) async {
    if (!_isAladhanBackedMethod(methodCode)) return null;
    final country = _aladhanCountryName(location);
    final candidates = <String>[
      location.district.trim(),
      location.province.trim(),
    ].where((value) => value.isNotEmpty).toSet().toList();
    for (final city in candidates) {
      final daily = await _aladhanPrayerTimesClient.fetchDailyByCity(
        date: date,
        city: city,
        country: country,
        methodCode: methodCode,
        school: school,
        timeout: _aladhanTimeout,
        headers: _diyanetHeaders,
      );
      if (daily == null) continue;
      final times = PrayerTimesMapper.fromAladhanDaily(
        daily: daily,
        date: date,
        latitude: double.tryParse(location.latitude) ?? 0,
        longitude: double.tryParse(location.longitude) ?? 0,
        calculationParameters: fallbackParams,
      );
      _logTimes('[Aladhan:$methodCode city=$city]', location, times);
      return times;
    }
    return null;
  }

  String _aladhanCountryName(LocationData location) {
    final countryName = (location.countryName ?? '').trim();
    final normalized = normalizePrayerLocationName(countryName);
    if (location.countryId == ConfigRegistry.dataSources.diyanet.countryId ||
        normalized == 'TURKIYE' ||
        normalized == 'TURKEY') {
      return 'Turkey';
    }
    return countryName.isEmpty ? 'Turkey' : countryName;
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
      stateId: location.stateId,
      districtId: location.districtId,
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
      if (daily == null) return null;
      return PrayerTimesMapper.fromDiyanetDaily(
        daily: daily,
        location: location,
        calculationParameters: fallbackParams,
      );
    } catch (_) {
      return null;
    }
  }

  void _logTimes(String source, LocationData? location, PrayerTimes times) {
    final locationLabel = location == null
        ? ''
        : ' ${location.province}/${location.district}';
    _log('$source$locationLabel '
        'Fajr ${formatPrayerTimeHourMinute(times.fajr)} '
        'Sunrise ${formatPrayerTimeHourMinute(times.sunrise)} '
        'Dhuhr ${formatPrayerTimeHourMinute(times.dhuhr)} '
        'Asr ${formatPrayerTimeHourMinute(times.asr)} '
        'Maghrib ${formatPrayerTimeHourMinute(times.maghrib)} '
        'Isha ${formatPrayerTimeHourMinute(times.isha)}');
  }
}
