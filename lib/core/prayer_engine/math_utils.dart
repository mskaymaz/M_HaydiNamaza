import 'dart:math' as math;

double degreesToRadians(double degrees) {
  return (degrees * math.pi) / 180.0;
}

double radiansToDegrees(double radians) {
  return (radians * 180.0) / math.pi;
}

double normalizeToScale(double num, double max) {
  return num - max * (num / max).floorToDouble();
}

double unwindAngle(double angle) {
  return normalizeToScale(angle, 360.0);
}

double quadrantShiftAngle(double angle) {
  if (angle >= -180 && angle <= 180) {
    return angle;
  }
  return angle - 360 * (angle / 360).roundToDouble();
}
