import 'dart:math' as math;

import 'astronomical.dart';
import 'coordinates.dart';
import 'math_utils.dart';
import 'solar_coordinates.dart';

class SolarTime {
  final Coordinates observer;
  late final SolarCoordinates solar;
  late final SolarCoordinates prevSolar;
  late final SolarCoordinates nextSolar;
  late final double approxTransit;
  late final double transit;
  late final double sunrise;
  late final double sunset;

  SolarTime(DateTime date, Coordinates coordinates) : observer = coordinates {
    final julianDay = Astronomical.julianDay(
      date.year,
      date.month,
      date.day,
      0,
    );

    solar = SolarCoordinates(julianDay);
    prevSolar = SolarCoordinates(julianDay - 1);
    nextSolar = SolarCoordinates(julianDay + 1);

    final m0 = Astronomical.approximateTransit(
      coordinates.longitude,
      solar.apparentSiderealTime,
      solar.rightAscension,
    );
    final solarAltitude = -50.0 / 60.0;

    approxTransit = m0;
    transit = Astronomical.correctedTransit(
      m0,
      coordinates.longitude,
      solar.apparentSiderealTime,
      solar.rightAscension,
      prevSolar.rightAscension,
      nextSolar.rightAscension,
    );

    sunrise = Astronomical.correctedHourAngle(
      m0,
      solarAltitude,
      coordinates,
      false,
      solar.apparentSiderealTime,
      solar.rightAscension,
      prevSolar.rightAscension,
      nextSolar.rightAscension,
      solar.declination,
      prevSolar.declination,
      nextSolar.declination,
    );

    sunset = Astronomical.correctedHourAngle(
      m0,
      solarAltitude,
      coordinates,
      true,
      solar.apparentSiderealTime,
      solar.rightAscension,
      prevSolar.rightAscension,
      nextSolar.rightAscension,
      solar.declination,
      prevSolar.declination,
      nextSolar.declination,
    );
  }

  double hourAngle(double angle, bool afterTransit) {
    return Astronomical.correctedHourAngle(
      approxTransit,
      angle,
      observer,
      afterTransit,
      solar.apparentSiderealTime,
      solar.rightAscension,
      prevSolar.rightAscension,
      nextSolar.rightAscension,
      solar.declination,
      prevSolar.declination,
      nextSolar.declination,
    );
  }

  double afternoon(int shadowLength) {
    final tangent = (observer.latitude - solar.declination).abs();
    final inverse = shadowLength + math.tan(degreesToRadians(tangent));
    final angle = radiansToDegrees(math.atan(1.0 / inverse));
    return hourAngle(angle, true);
  }
}
