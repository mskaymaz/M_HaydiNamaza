import 'coordinates.dart';
import 'date_utils.dart';
import 'solar_time.dart';

enum PolarCircleResolution {
  aqrabBalad,
  aqrabYaum,
  unresolved,
}

const _latitudeVariationStep = 0.5;
const _unsafeLatitude = 65.0;

bool _isValidSolarTime(SolarTime solarTime) {
  return !(solarTime.sunrise.isNaN || solarTime.sunset.isNaN);
}

class PolarResolvedValues {
  final DateTime date;
  final DateTime tomorrow;
  final Coordinates coordinates;
  final SolarTime solarTime;
  final SolarTime tomorrowSolarTime;

  PolarResolvedValues({
    required this.date,
    required this.tomorrow,
    required this.coordinates,
    required this.solarTime,
    required this.tomorrowSolarTime,
  });
}

PolarResolvedValues? _aqrabYaumResolver(
  Coordinates coordinates,
  DateTime date, {
  int daysAdded = 1,
  int direction = 1,
}) {
  if (daysAdded > (365 / 2).ceil()) {
    return null;
  }
  final testDate = DateTime.utc(date.year, date.month, date.day);
  final adjusted = DateTime.utc(
    testDate.year,
    testDate.month,
    testDate.day + direction * daysAdded,
  );
  final tomorrow = dateByAddingDays(adjusted, 1);
  final solarTime = SolarTime(adjusted, coordinates);
  final tomorrowSolarTime = SolarTime(tomorrow, coordinates);

  if (!_isValidSolarTime(solarTime) || !_isValidSolarTime(tomorrowSolarTime)) {
    return _aqrabYaumResolver(
      coordinates,
      date,
      daysAdded: daysAdded + (direction > 0 ? 0 : 1),
      direction: -direction,
    );
  }

  return PolarResolvedValues(
    date: date,
    tomorrow: tomorrow,
    coordinates: coordinates,
    solarTime: solarTime,
    tomorrowSolarTime: tomorrowSolarTime,
  );
}

PolarResolvedValues? _aqrabBaladResolver(
  Coordinates coordinates,
  DateTime date,
  double latitude,
) {
  final solarTime = SolarTime(date, Coordinates(latitude, coordinates.longitude));
  final tomorrow = dateByAddingDays(date, 1);
  final tomorrowSolarTime = SolarTime(tomorrow, Coordinates(latitude, coordinates.longitude));
  if (!_isValidSolarTime(solarTime) || !_isValidSolarTime(tomorrowSolarTime)) {
    if (latitude.abs() >= _unsafeLatitude) {
      return _aqrabBaladResolver(
        coordinates,
        date,
        latitude - latitude.sign * _latitudeVariationStep,
      );
    }
    return null;
  }

  return PolarResolvedValues(
    date: date,
    tomorrow: tomorrow,
    coordinates: Coordinates(latitude, coordinates.longitude),
    solarTime: solarTime,
    tomorrowSolarTime: tomorrowSolarTime,
  );
}

PolarResolvedValues polarCircleResolvedValues(
  PolarCircleResolution resolver,
  DateTime date,
  Coordinates coordinates,
) {
  final defaultReturn = PolarResolvedValues(
    date: date,
    tomorrow: dateByAddingDays(date, 1),
    coordinates: coordinates,
    solarTime: SolarTime(date, coordinates),
    tomorrowSolarTime: SolarTime(dateByAddingDays(date, 1), coordinates),
  );

  switch (resolver) {
    case PolarCircleResolution.aqrabYaum:
      return _aqrabYaumResolver(coordinates, date) ?? defaultReturn;
    case PolarCircleResolution.aqrabBalad:
      return _aqrabBaladResolver(
            coordinates,
            date,
            coordinates.latitude - coordinates.latitude.sign * _latitudeVariationStep,
          ) ??
          defaultReturn;
    case PolarCircleResolution.unresolved:
      return defaultReturn;
  }
}
