import 'dart:math' as math;

import 'astronomical.dart';
import 'math_utils.dart';

class SolarCoordinates {
  final double declination;
  final double rightAscension;
  final double apparentSiderealTime;

  SolarCoordinates(double julianDay)
      : declination = _declination(julianDay),
        rightAscension = _rightAscension(julianDay),
        apparentSiderealTime = _apparentSiderealTime(julianDay);

  static double _declination(double julianDay) {
    final t = Astronomical.julianCentury(julianDay);
    final l0 = Astronomical.meanSolarLongitude(t);
    final lambda = degreesToRadians(Astronomical.apparentSolarLongitude(t, l0));
    final epsilon0 = Astronomical.meanObliquityOfTheEcliptic(t);
    final epsilonApparent = degreesToRadians(
      Astronomical.apparentObliquityOfTheEcliptic(t, epsilon0),
    );
    return radiansToDegrees(
      math.asin(math.sin(epsilonApparent) * math.sin(lambda)),
    );
  }

  static double _rightAscension(double julianDay) {
    final t = Astronomical.julianCentury(julianDay);
    final l0 = Astronomical.meanSolarLongitude(t);
    final lambda = degreesToRadians(Astronomical.apparentSolarLongitude(t, l0));
    final epsilon0 = Astronomical.meanObliquityOfTheEcliptic(t);
    final epsilonApparent = degreesToRadians(
      Astronomical.apparentObliquityOfTheEcliptic(t, epsilon0),
    );
    return unwindAngle(
      radiansToDegrees(
        math.atan2(
          math.cos(epsilonApparent) * math.sin(lambda),
          math.cos(lambda),
        ),
      ),
    );
  }

  static double _apparentSiderealTime(double julianDay) {
    final t = Astronomical.julianCentury(julianDay);
    final l0 = Astronomical.meanSolarLongitude(t);
    final lp = Astronomical.meanLunarLongitude(t);
    final omega = Astronomical.ascendingLunarNodeLongitude(t);
    final theta0 = Astronomical.meanSiderealTime(t);
    final dPsi = Astronomical.nutationInLongitude(t, l0, lp, omega);
    final dEpsilon = Astronomical.nutationInObliquity(t, l0, lp, omega);
    final epsilon0 = Astronomical.meanObliquityOfTheEcliptic(t);
    return theta0 + (dPsi * 3600 * math.cos(degreesToRadians(epsilon0 + dEpsilon))) / 3600;
  }
}
