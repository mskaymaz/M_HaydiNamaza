import 'dart:math' as math;

import 'coordinates.dart';
import 'date_utils.dart';
import 'math_utils.dart';
import 'shafaq.dart';

class Astronomical {
  static double meanSolarLongitude(double julianCentury) {
    final t = julianCentury;
    final term1 = 280.4664567;
    final term2 = 36000.76983 * t;
    final term3 = 0.0003032 * math.pow(t, 2);
    final l0 = term1 + term2 + term3;
    return unwindAngle(l0);
  }

  static double meanLunarLongitude(double julianCentury) {
    final t = julianCentury;
    final term1 = 218.3165;
    final term2 = 481267.8813 * t;
    final lp = term1 + term2;
    return unwindAngle(lp);
  }

  static double ascendingLunarNodeLongitude(double julianCentury) {
    final t = julianCentury;
    final term1 = 125.04452;
    final term2 = 1934.136261 * t;
    final term3 = 0.0020708 * math.pow(t, 2);
    final term4 = math.pow(t, 3) / 450000;
    final omega = term1 - term2 + term3 + term4;
    return unwindAngle(omega);
  }

  static double meanSolarAnomaly(double julianCentury) {
    final t = julianCentury;
    final term1 = 357.52911;
    final term2 = 35999.05029 * t;
    final term3 = 0.0001537 * math.pow(t, 2);
    final m = term1 + term2 - term3;
    return unwindAngle(m);
  }

  static double solarEquationOfTheCenter(
    double julianCentury,
    double meanAnomaly,
  ) {
    final t = julianCentury;
    final mrad = degreesToRadians(meanAnomaly);
    final term1 =
        (1.914602 - 0.004817 * t - 0.000014 * math.pow(t, 2)) *
            math.sin(mrad);
    final term2 = (0.019993 - 0.000101 * t) * math.sin(2 * mrad);
    final term3 = 0.000289 * math.sin(3 * mrad);
    return term1 + term2 + term3;
  }

  static double apparentSolarLongitude(
    double julianCentury,
    double meanLongitude,
  ) {
    final t = julianCentury;
    final l0 = meanLongitude;
    final longitude =
        l0 + solarEquationOfTheCenter(t, meanSolarAnomaly(t));
    final omega = 125.04 - 1934.136 * t;
    final lambda = longitude - 0.00569 - 0.00478 * math.sin(degreesToRadians(omega));
    return unwindAngle(lambda);
  }

  static double meanObliquityOfTheEcliptic(double julianCentury) {
    final t = julianCentury;
    final term1 = 23.439291;
    final term2 = 0.013004167 * t;
    final term3 = 0.0000001639 * math.pow(t, 2);
    final term4 = 0.0000005036 * math.pow(t, 3);
    return term1 - term2 - term3 + term4;
  }

  static double apparentObliquityOfTheEcliptic(
    double julianCentury,
    double meanObliquityOfTheEcliptic,
  ) {
    final t = julianCentury;
    final epsilon0 = meanObliquityOfTheEcliptic;
    final o = 125.04 - 1934.136 * t;
    return epsilon0 + 0.00256 * math.cos(degreesToRadians(o));
  }

  static double meanSiderealTime(double julianCentury) {
    final t = julianCentury;
    final jd = t * 36525 + 2451545.0;
    final term1 = 280.46061837;
    final term2 = 360.98564736629 * (jd - 2451545);
    final term3 = 0.000387933 * math.pow(t, 2);
    final term4 = math.pow(t, 3) / 38710000;
    final theta = term1 + term2 + term3 - term4;
    return unwindAngle(theta);
  }

  static double nutationInLongitude(
    double julianCentury,
    double solarLongitude,
    double lunarLongitude,
    double ascendingNode,
  ) {
    final l0 = solarLongitude;
    final lp = lunarLongitude;
    final omega = ascendingNode;
    final term1 = (-17.2 / 3600) * math.sin(degreesToRadians(omega));
    final term2 = (1.32 / 3600) * math.sin(2 * degreesToRadians(l0));
    final term3 = (0.23 / 3600) * math.sin(2 * degreesToRadians(lp));
    final term4 = (0.21 / 3600) * math.sin(2 * degreesToRadians(omega));
    return term1 - term2 - term3 + term4;
  }

  static double nutationInObliquity(
    double julianCentury,
    double solarLongitude,
    double lunarLongitude,
    double ascendingNode,
  ) {
    final l0 = solarLongitude;
    final lp = lunarLongitude;
    final omega = ascendingNode;
    final term1 = (9.2 / 3600) * math.cos(degreesToRadians(omega));
    final term2 = (0.57 / 3600) * math.cos(2 * degreesToRadians(l0));
    final term3 = (0.1 / 3600) * math.cos(2 * degreesToRadians(lp));
    final term4 = (0.09 / 3600) * math.cos(2 * degreesToRadians(omega));
    return term1 + term2 + term3 - term4;
  }

  static double altitudeOfCelestialBody(
    double observerLatitude,
    double declination,
    double localHourAngle,
  ) {
    final phi = observerLatitude;
    final delta = declination;
    final h = localHourAngle;
    final term1 = math.sin(degreesToRadians(phi)) * math.sin(degreesToRadians(delta));
    final term2 =
        math.cos(degreesToRadians(phi)) *
            math.cos(degreesToRadians(delta)) *
            math.cos(degreesToRadians(h));
    return radiansToDegrees(math.asin(term1 + term2));
  }

  static double approximateTransit(
    double longitude,
    double siderealTime,
    double rightAscension,
  ) {
    final l = longitude;
    final theta0 = siderealTime;
    final a2 = rightAscension;
    final lw = l * -1;
    return normalizeToScale((a2 + lw - theta0) / 360, 1);
  }

  static double correctedTransit(
    double approximateTransit,
    double longitude,
    double siderealTime,
    double rightAscension,
    double previousRightAscension,
    double nextRightAscension,
  ) {
    final m0 = approximateTransit;
    final l = longitude;
    final theta0 = siderealTime;
    final a2 = rightAscension;
    final a1 = previousRightAscension;
    final a3 = nextRightAscension;
    final lw = l * -1;
    final theta = unwindAngle(theta0 + 360.985647 * m0);
    final a = unwindAngle(interpolateAngles(a2, a1, a3, m0));
    final h = quadrantShiftAngle(theta - lw - a);
    final dm = h / -360;
    return (m0 + dm) * 24;
  }

  static double correctedHourAngle(
    double approximateTransit,
    double angle,
    Coordinates coordinates,
    bool afterTransit,
    double siderealTime,
    double rightAscension,
    double previousRightAscension,
    double nextRightAscension,
    double declination,
    double previousDeclination,
    double nextDeclination,
  ) {
    final m0 = approximateTransit;
    final h0 = angle;
    final theta0 = siderealTime;
    final a2 = rightAscension;
    final a1 = previousRightAscension;
    final a3 = nextRightAscension;
    final d2 = declination;
    final d1 = previousDeclination;
    final d3 = nextDeclination;

    final lw = coordinates.longitude * -1;
    final term1 =
        math.sin(degreesToRadians(h0)) -
            math.sin(degreesToRadians(coordinates.latitude)) *
                math.sin(degreesToRadians(d2));
    final term2 =
        math.cos(degreesToRadians(coordinates.latitude)) *
            math.cos(degreesToRadians(d2));
    final h0calc = radiansToDegrees(math.acos(term1 / term2));
    final m = afterTransit ? m0 + h0calc / 360 : m0 - h0calc / 360;
    final theta = unwindAngle(theta0 + 360.985647 * m);
    final a = unwindAngle(interpolateAngles(a2, a1, a3, m));
    final delta = interpolate(d2, d1, d3, m);
    final h = theta - lw - a;
    final alt = altitudeOfCelestialBody(coordinates.latitude, delta, h);
    final term3 = alt - h0;
    final term4 =
        360 *
            math.cos(degreesToRadians(delta)) *
            math.cos(degreesToRadians(coordinates.latitude)) *
            math.sin(degreesToRadians(h));
    final dm = term3 / term4;
    return (m + dm) * 24;
  }

  static double interpolate(double y2, double y1, double y3, double n) {
    final a = y2 - y1;
    final b = y3 - y2;
    final c = b - a;
    return y2 + (n / 2) * (a + b + n * c);
  }

  static double interpolateAngles(double y2, double y1, double y3, double n) {
    final a = unwindAngle(y2 - y1);
    final b = unwindAngle(y3 - y2);
    final c = b - a;
    return y2 + (n / 2) * (a + b + n * c);
  }

  static double julianDay(int year, int month, int day, [double hours = 0]) {
    final y = (month > 2) ? year : year - 1;
    final m = (month > 2) ? month : month + 12;
    final d = day + hours / 24;

    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();

    final i0 = (365.25 * (y + 4716)).floor();
    final i1 = (30.6001 * (m + 1)).floor();

    return i0 + i1 + d + b - 1524.5;
  }

  static double julianCentury(double julianDay) {
    return (julianDay - 2451545.0) / 36525;
  }

  static bool isLeapYear(int year) {
    if (year % 4 != 0) return false;
    if (year % 100 == 0 && year % 400 != 0) return false;
    return true;
  }

  static DateTime seasonAdjustedMorningTwilight(
    double latitude,
    int dayOfYear,
    int year,
    DateTime sunrise,
  ) {
    final a = 75 + (28.65 / 55.0) * latitude.abs();
    final b = 75 + (19.44 / 55.0) * latitude.abs();
    final c = 75 + (32.74 / 55.0) * latitude.abs();
    final d = 75 + (48.1 / 55.0) * latitude.abs();

    final dyy = daysSinceSolstice(dayOfYear, year, latitude);
    double adjustment;
    if (dyy < 91) {
      adjustment = a + ((b - a) / 91.0) * dyy;
    } else if (dyy < 137) {
      adjustment = b + ((c - b) / 46.0) * (dyy - 91);
    } else if (dyy < 183) {
      adjustment = c + ((d - c) / 46.0) * (dyy - 137);
    } else if (dyy < 229) {
      adjustment = d + ((c - d) / 46.0) * (dyy - 183);
    } else if (dyy < 275) {
      adjustment = c + ((b - c) / 46.0) * (dyy - 229);
    } else {
      adjustment = b + ((a - b) / 91.0) * (dyy - 275);
    }

    return dateByAddingSeconds(sunrise, (adjustment * -60.0).round());
  }

  static DateTime seasonAdjustedEveningTwilight(
    double latitude,
    int dayOfYear,
    int year,
    DateTime sunset,
    Shafaq shafaq,
  ) {
    double a, b, c, d;
    if (shafaq == Shafaq.ahmer) {
      a = 62 + (17.4 / 55.0) * latitude.abs();
      b = 62 - (7.16 / 55.0) * latitude.abs();
      c = 62 + (5.12 / 55.0) * latitude.abs();
      d = 62 + (19.44 / 55.0) * latitude.abs();
    } else if (shafaq == Shafaq.abyad) {
      a = 75 + (25.6 / 55.0) * latitude.abs();
      b = 75 + (7.16 / 55.0) * latitude.abs();
      c = 75 + (36.84 / 55.0) * latitude.abs();
      d = 75 + (81.84 / 55.0) * latitude.abs();
    } else {
      a = 75 + (25.6 / 55.0) * latitude.abs();
      b = 75 + (2.05 / 55.0) * latitude.abs();
      c = 75 - (9.21 / 55.0) * latitude.abs();
      d = 75 + (6.14 / 55.0) * latitude.abs();
    }

    final dyy = daysSinceSolstice(dayOfYear, year, latitude);
    double adjustment;
    if (dyy < 91) {
      adjustment = a + ((b - a) / 91.0) * dyy;
    } else if (dyy < 137) {
      adjustment = b + ((c - b) / 46.0) * (dyy - 91);
    } else if (dyy < 183) {
      adjustment = c + ((d - c) / 46.0) * (dyy - 137);
    } else if (dyy < 229) {
      adjustment = d + ((c - d) / 46.0) * (dyy - 183);
    } else if (dyy < 275) {
      adjustment = c + ((b - c) / 46.0) * (dyy - 229);
    } else {
      adjustment = b + ((a - b) / 91.0) * (dyy - 275);
    }

    return dateByAddingSeconds(sunset, (adjustment * 60.0).round());
  }

  static int daysSinceSolstice(int dayOfYear, int year, double latitude) {
    var daysSinceSolstice = 0;
    final northernOffset = 10;
    final southernOffset = isLeapYear(year) ? 173 : 172;
    final daysInYear = isLeapYear(year) ? 366 : 365;

    if (latitude >= 0) {
      daysSinceSolstice = dayOfYear + northernOffset;
      if (daysSinceSolstice >= daysInYear) {
        daysSinceSolstice = daysSinceSolstice - daysInYear;
      }
    } else {
      daysSinceSolstice = dayOfYear - southernOffset;
      if (daysSinceSolstice < 0) {
        daysSinceSolstice = daysSinceSolstice + daysInYear;
      }
    }

    return daysSinceSolstice;
  }
}
