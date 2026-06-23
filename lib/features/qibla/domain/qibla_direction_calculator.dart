import 'dart:math' as math;

class QiblaDirectionCalculator {
  const QiblaDirectionCalculator._();

  static const double defaultAlignmentToleranceDegrees = 5.0;

  static double normalizeDegrees(double value) {
    final result = value % 360;
    return result < 0 ? result + 360 : result;
  }

  static double rotationDegrees({
    required double targetDegrees,
    required double headingDegrees,
  }) {
    return normalizeDegrees(targetDegrees - headingDegrees);
  }

  static double rotationRadians({
    required double targetDegrees,
    required double headingDegrees,
  }) {
    return rotationDegrees(
          targetDegrees: targetDegrees,
          headingDegrees: headingDegrees,
        ) *
        math.pi /
        180.0;
  }

  static double absoluteDeltaDegrees({
    required double targetDegrees,
    required double headingDegrees,
  }) {
    final rotation = rotationDegrees(
      targetDegrees: targetDegrees,
      headingDegrees: headingDegrees,
    );
    return rotation > 180 ? 360 - rotation : rotation;
  }

  static bool isAligned({
    required double targetDegrees,
    required double headingDegrees,
    double toleranceDegrees = defaultAlignmentToleranceDegrees,
  }) {
    return absoluteDeltaDegrees(
          targetDegrees: targetDegrees,
          headingDegrees: headingDegrees,
        ) <=
        toleranceDegrees;
  }
}
