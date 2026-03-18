import 'calculation_parameters.dart';
import 'coordinates.dart';
import 'prayer_times.dart';

class PrayerEngine {
  const PrayerEngine();

  PrayerTimes calculate({
    required DateTime date,
    required Coordinates coordinates,
    required String timeZone,
    required CalculationParameters params,
  }) {
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    final timesUtc = PrayerTimes(coordinates, utcDate, params);

    final offsetMinutes = _parseOffsetMinutes(timeZone);
    if (offsetMinutes == 0) {
      // Named time zones are not resolved here; unsupported values fall back to UTC.
      return timesUtc;
    }

    return timesUtc.withOffset(Duration(minutes: offsetMinutes));
  }

  int _parseOffsetMinutes(String timeZone) {
    final re = RegExp(r'^([+-])(\d{2}):?(\d{2})$');
    final m = re.firstMatch(timeZone.trim());
    if (m == null) return 0;
    final sign = m.group(1) == '-' ? -1 : 1;
    final hours = int.parse(m.group(2)!);
    final minutes = int.parse(m.group(3)!);
    return sign * (hours * 60 + minutes);
  }
}
