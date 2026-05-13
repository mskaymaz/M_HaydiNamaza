import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mhaydinamaza/app/aladhan_prayer_times_client.dart';
import 'package:mhaydinamaza/app/calculation_advanced_settings_storage.dart';
import 'package:mhaydinamaza/app/diyanet_location_id_resolver.dart';
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
          methodCode: 'turkey',
        );

        expect(logs.any((line) => line.contains('[Diyanet]')), isTrue);
      } finally {
        debugPrint = original;
      }
    });

    test('logs Aladhan source label when Diyanet fails and Aladhan is used', () async {
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

        expect(logs.any((line) => line.contains('[Aladhan:turkey]')), isTrue);
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
  @override
  Future<DiyanetIds?> resolve({
    required String? countryId,
    required String province,
    required String district,
    required Duration timeout,
    required Map<String, String> headers,
    void Function(String message)? onLog,
  }) async {
    return const DiyanetIds(stateId: '6', districtId: '34');
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
