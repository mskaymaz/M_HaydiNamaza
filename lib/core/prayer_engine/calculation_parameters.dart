import 'high_latitude_rule.dart';
import 'madhab.dart';
import 'polar_circle_resolution.dart';
import 'rounding.dart';
import 'shafaq.dart';

class CalculationParameters {
  final String method;
  final double fajrAngle;
  final double ishaAngle;
  final int ishaInterval;
  final double maghribAngle;

  Madhab madhab = Madhab.shafi;
  HighLatitudeRule highLatitudeRule = HighLatitudeRule.middleOfTheNight;
  PolarCircleResolution polarCircleResolution = PolarCircleResolution.unresolved;
  Rounding rounding = Rounding.nearest;
  Shafaq shafaq = Shafaq.general;

  Map<String, int> adjustments = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  Map<String, int> methodAdjustments = {
    'fajr': 0,
    'sunrise': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };

  CalculationParameters(
    this.method,
    this.fajrAngle,
    this.ishaAngle, {
    this.ishaInterval = 0,
    this.maghribAngle = 0,
  });

  Map<String, double> nightPortions() {
    switch (highLatitudeRule) {
      case HighLatitudeRule.middleOfTheNight:
        return {'fajr': 1 / 2, 'isha': 1 / 2};
      case HighLatitudeRule.seventhOfTheNight:
        return {'fajr': 1 / 7, 'isha': 1 / 7};
      case HighLatitudeRule.twilightAngle:
        return {'fajr': fajrAngle / 60, 'isha': ishaAngle / 60};
    }
  }
}
