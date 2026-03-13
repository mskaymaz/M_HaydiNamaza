import 'coordinates.dart';

enum HighLatitudeRule {
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle,
}

HighLatitudeRule recommendedHighLatitudeRule(Coordinates coordinates) {
  if (coordinates.latitude > 48) {
    return HighLatitudeRule.seventhOfTheNight;
  }
  return HighLatitudeRule.middleOfTheNight;
}
