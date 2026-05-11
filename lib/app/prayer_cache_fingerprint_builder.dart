import 'calculation_advanced_settings_storage.dart';
import 'location_storage.dart';
import 'prayer_service_pure_helpers.dart';

class PrayerCacheFingerprintBuilder {
  static String build({
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
}
