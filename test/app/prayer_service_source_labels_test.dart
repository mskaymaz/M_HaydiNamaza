import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mhaydinamaza/app/aladhan_prayer_times_client.dart';
import 'package:mhaydinamaza/app/calculation_advanced_settings_storage.dart';
import 'package:mhaydinamaza/app/diyanet_location_id_resolver.dart';
import 'package:mhaydinamaza/app/diyanet_local_prayer_times_repository.dart';
import 'package:mhaydinamaza/app/diyanet_prayer_times_client.dart';
import 'package:mhaydinamaza/app/location_storage.dart';
import 'package:mhaydinamaza/app/prayer_daily_cache_repository.dart';
import 'package:mhaydinamaza/app/prayer_service.dart';
import 'package:mhaydinamaza/app/prayer_service_pure_helpers.dart';
import 'package:mhaydinamaza/core/prayer_engine/calculation_parameters.dart';
import 'package:mhaydinamaza/core/prayer_engine/coordinates.dart';
import 'package:mhaydinamaza/core/prayer_engine/prayer_times.dart';

void main() {
  group('PrayerService source labels', () {

    test('uses local Diyanet data when Diyanet method is selected', () async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      try {
        final resolver = _FakeDiyanetLocationIdResolver();
        final aladhanClient = _FakeAladhanPrayerTimesClient(
          shouldReturnData: true,
        );
        final service = PrayerService(
          advancedSettingsStorage: _FakeAdvancedSettingsStorage(),
          dailyCacheRepository: _NoopCacheRepository(),
          diyanetLocationIdResolver: resolver,
          diyanetLocalPrayerTimesRepository:
              _FakeDiyanetLocalPrayerTimesRepository(shouldReturnData: true),
          diyanetPrayerTimesClient: _FakeDiyanetPrayerTimesClient(
            shouldReturnData: false,
          ),
          aladhanPrayerTimesClient: aladhanClient,
        );

        final times = await service.calculateForDate(
          location: const LocationData(
            countryId: '2',
            countryName: 'Turkiye',
            stateId: '552',
            districtId: '17870',
            province: 'Konya',
            district: 'Meram',
            latitude: '37.8714',
            longitude: '32.4846',
            timeZoneName: 'Europe/Istanbul',
            timeZoneOffset: '+03:00',
          ),
          latitude: 37.8714,
          longitude: 32.4846,
          timeZone: 'Europe/Istanbul',
          methodCode: 'diyanet',
          date: DateTime(2026, 6, 18),
          allowRemote: false,
        );

        expect(times.fajr.hour, 3);
        expect(times.fajr.minute, 32);
        expect(logs.any((line) => line.contains('[Diyanet:local]')), isTrue);
        expect(resolver.resolveCount, 0);
        expect(aladhanClient.fetchDailyCount, 0);
        expect(aladhanClient.fetchDailyByCityCount, 0);
      } finally {
        debugPrint = original;
      }
    });
    test('logs Diyanet source label when Diyanet result is used', () async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      try {
        final service = PrayerService(
          advancedSettingsStorage: _FakeAdvancedSettingsStorage(),
          dailyCacheRepository: _NoopCacheRepository(),
          diyanetLocationIdResolver: _FakeDiyanetLocationIdResolver(),
          diyanetLocalPrayerTimesRepository:
              _FakeDiyanetLocalPrayerTimesRepository(shouldReturnData: false),
          diyanetPrayerTimesClient: _FakeDiyanetPrayerTimesClient(
            shouldReturnData: true,
          ),
          aladhanPrayerTimesClient: _FakeAladhanPrayerTimesClient(
            shouldReturnData: false,
          ),
        );

        await service.calculateToday(
          location: const LocationData(
            countryId: '2',
            countryName: 'Turkiye',
            province: 'Ankara',
            district: 'Cankaya',
            latitude: '39.9208',
            longitude: '32.8541',
            timeZoneName: 'Europe/Istanbul',
            timeZoneOffset: '+03:00',
          ),
          latitude: 39.9208,
          longitude: 32.8541,
          timeZone: 'Europe/Istanbul',
          methodCode: 'diyanet',
        );

        expect(logs.any((line) => line.contains('[Diyanet]')), isTrue);
      } finally {
        debugPrint = original;
      }
    });

    test('uses local calculation when Diyanet fails for Turkey method', () async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      try {
        final service = PrayerService(
          advancedSettingsStorage: _FakeAdvancedSettingsStorage(),
          dailyCacheRepository: _NoopCacheRepository(),
          diyanetLocationIdResolver: _FakeDiyanetLocationIdResolver(),
          diyanetPrayerTimesClient: _FakeDiyanetPrayerTimesClient(
            shouldReturnData: false,
          ),
          aladhanPrayerTimesClient: _FakeAladhanPrayerTimesClient(
            shouldReturnData: true,
          ),
        );

        await service.calculateToday(
          location: const LocationData(
            countryId: '2',
            countryName: 'Turkiye',
            province: 'Izmir',
            district: 'Konak',
            latitude: '38.4237',
            longitude: '27.1428',
            timeZoneName: 'Europe/Istanbul',
            timeZoneOffset: '+03:00',
          ),
          latitude: 38.4237,
          longitude: 27.1428,
          timeZone: 'Europe/Istanbul',
          methodCode: 'turkey',
        );

        expect(logs.any((line) => line.contains('[Aladhan:turkey]')), isFalse);
        expect(logs.any((line) => line.contains('[Aladhan:shafii]')), isFalse);
        expect(
          logs.any((line) => line.contains('[Calc] fallback local engine')),
          isTrue,
        );
      } finally {
        debugPrint = original;
      }
    });

    test('uses Aladhan directly when Aladhan method is selected', () async {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      try {
        final aladhanClient = _FakeAladhanPrayerTimesClient(
          shouldReturnData: true,
        );
        final service = PrayerService(
          advancedSettingsStorage: _FakeAdvancedSettingsStorage(),
          dailyCacheRepository: _NoopCacheRepository(),
          diyanetLocationIdResolver: _FakeDiyanetLocationIdResolver(),
          diyanetPrayerTimesClient: _FakeDiyanetPrayerTimesClient(
            shouldReturnData: true,
          ),
          aladhanPrayerTimesClient: aladhanClient,
        );

        await service.calculateToday(
          location: const LocationData(
            countryId: '2',
            countryName: 'Turkiye',
            province: 'Bursa',
            district: 'Osmangazi',
            latitude: '40.1828',
            longitude: '29.0667',
            timeZoneName: 'Europe/Istanbul',
            timeZoneOffset: '+03:00',
          ),
          latitude: 40.1828,
          longitude: 29.0667,
          timeZone: 'Europe/Istanbul',
          methodCode: 'aladhan',
        );

        expect(
          logs.any((line) => line.contains('[Aladhan:aladhan coordinates]')),
          isTrue,
        );
        expect(aladhanClient.lastSchool, 0);
        expect(logs.any((line) => line.contains('[Diyanet] ids')), isFalse);
      } finally {
        debugPrint = original;
      }
    });
  });
}

class _FakeAdvancedSettingsStorage extends CalculationAdvancedSettingsStorage {
  @override
  Future<CalculationAdvancedSettings> read() async {
    return const CalculationAdvancedSettings();
  }
}

class _NoopCacheRepository extends PrayerDailyCacheRepository {
  @override
  Future<PrayerTimes?> read({
    required String fingerprint,
    required Coordinates coordinates,
    required DateTime date,
    required CalculationParameters calculationParameters,
  }) async {
    return null;
  }

  @override
  Future<void> write({
    required String fingerprint,
    required PrayerTimes times,
  }) async {}
}

class _FakeDiyanetLocationIdResolver extends DiyanetLocationIdResolver {
  int resolveCount = 0;

  @override
  Future<DiyanetIds?> resolve({
    required String? countryId,
    required String? stateId,
    required String? districtId,
    required String province,
    required String district,
    required Duration timeout,
    required Map<String, String> headers,
    void Function(String message)? onLog,
  }) async {
    resolveCount += 1;
    return const DiyanetIds(stateId: '6', districtId: '34');
  }
}

class _FakeDiyanetLocalPrayerTimesRepository
    extends DiyanetLocalPrayerTimesRepository {
  final bool shouldReturnData;

  _FakeDiyanetLocalPrayerTimesRepository({required this.shouldReturnData});

  @override
  Future<DiyanetDailyTimings?> readDaily({
    required LocationData location,
    required DateTime date,
    void Function(String message)? onLog,
  }) async {
    if (!shouldReturnData) return null;
    return DiyanetDailyTimings(
      baseDate: date,
      fajr: DateTime(date.year, date.month, date.day, 3, 32),
      sunrise: DateTime(date.year, date.month, date.day, 5, 21),
      dhuhr: DateTime(date.year, date.month, date.day, 12, 56),
      asr: DateTime(date.year, date.month, date.day, 16, 49),
      maghrib: DateTime(date.year, date.month, date.day, 20, 22),
      isha: DateTime(date.year, date.month, date.day, 22, 2),
    );
  }
}

class _FakeDiyanetPrayerTimesClient extends DiyanetPrayerTimesClient {
  final bool shouldReturnData;

  _FakeDiyanetPrayerTimesClient({required this.shouldReturnData});

  @override
  Future<DiyanetDailyTimings?> fetchDaily({
    required String districtId,
    required String province,
    required String district,
    required DateTime date,
    required Duration timeout,
    required Map<String, String> headers,
    void Function(String message)? onLog,
  }) async {
    if (!shouldReturnData) return null;
    return DiyanetDailyTimings(
      baseDate: date,
      fajr: DateTime(date.year, date.month, date.day, 4, 30),
      sunrise: DateTime(date.year, date.month, date.day, 6, 0),
      dhuhr: DateTime(date.year, date.month, date.day, 13, 0),
      asr: DateTime(date.year, date.month, date.day, 16, 30),
      maghrib: DateTime(date.year, date.month, date.day, 20, 0),
      isha: DateTime(date.year, date.month, date.day, 21, 25),
    );
  }
}

class _FakeAladhanPrayerTimesClient extends AladhanPrayerTimesClient {
  final bool shouldReturnData;
  int? lastSchool;
  int fetchDailyCount = 0;
  int fetchDailyByCityCount = 0;

  _FakeAladhanPrayerTimesClient({required this.shouldReturnData});

  @override
  Future<AladhanDailyTimings?> fetchDaily({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String methodCode,
    required int school,
    required Duration timeout,
    required Map<String, String> headers,
  }) async {
    fetchDailyCount += 1;
    lastSchool = school;
    if (!shouldReturnData) return null;
    return AladhanDailyTimings(
      fajr: DateTime(date.year, date.month, date.day, 4, 32),
      sunrise: DateTime(date.year, date.month, date.day, 6, 2),
      dhuhr: DateTime(date.year, date.month, date.day, 13, 1),
      asr: DateTime(date.year, date.month, date.day, 16, 31),
      maghrib: DateTime(date.year, date.month, date.day, 20, 1),
      isha: DateTime(date.year, date.month, date.day, 21, 27),
    );
  }

  @override
  Future<AladhanDailyTimings?> fetchDailyByCity({
    required DateTime date,
    required String city,
    required String country,
    required String methodCode,
    required int school,
    required Duration timeout,
    required Map<String, String> headers,
  }) async {
    fetchDailyByCityCount += 1;
    lastSchool = school;
    if (!shouldReturnData) return null;
    return AladhanDailyTimings(
      fajr: DateTime(date.year, date.month, date.day, 4, 32),
      sunrise: DateTime(date.year, date.month, date.day, 6, 2),
      dhuhr: DateTime(date.year, date.month, date.day, 13, 1),
      asr: DateTime(date.year, date.month, date.day, 16, 31),
      maghrib: DateTime(date.year, date.month, date.day, 20, 1),
      isha: DateTime(date.year, date.month, date.day, 21, 27),
    );
  }
}
