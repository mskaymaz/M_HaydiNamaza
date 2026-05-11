import '../core/prayer_engine/calculation_parameters.dart';
import '../core/prayer_engine/coordinates.dart';
import '../core/prayer_engine/prayer_times.dart';
import 'aladhan_prayer_times_client.dart';
import 'diyanet_prayer_times_client.dart';
import 'location_storage.dart';

class PrayerTimesMapper {
  static PrayerTimes fromAladhanDaily({
    required AladhanDailyTimings daily,
    required DateTime date,
    required double latitude,
    required double longitude,
    required CalculationParameters calculationParameters,
  }) {
    return PrayerTimes.fromTimings(
      coordinates: Coordinates(latitude, longitude),
      date: date,
      calculationParameters: calculationParameters,
      fajr: daily.fajr,
      sunrise: daily.sunrise,
      dhuhr: daily.dhuhr,
      asr: daily.asr,
      sunset: daily.maghrib,
      maghrib: daily.maghrib,
      isha: daily.isha,
    );
  }

  static PrayerTimes fromDiyanetDaily({
    required DiyanetDailyTimings daily,
    required LocationData location,
    required CalculationParameters calculationParameters,
  }) {
    final lat = double.tryParse(location.latitude) ?? 0;
    final lon = double.tryParse(location.longitude) ?? 0;
    return PrayerTimes.fromTimings(
      coordinates: Coordinates(lat, lon),
      date: daily.baseDate,
      calculationParameters: calculationParameters,
      fajr: daily.fajr,
      sunrise: daily.sunrise,
      dhuhr: daily.dhuhr,
      asr: daily.asr,
      sunset: daily.maghrib,
      maghrib: daily.maghrib,
      isha: daily.isha,
    );
  }
}
