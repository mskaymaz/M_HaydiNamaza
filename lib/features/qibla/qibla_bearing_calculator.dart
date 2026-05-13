import 'dart:math' as math;

import 'qibla_constants.dart';

class QiblaBearingCalculator {
  const QiblaBearingCalculator();

  double calculateInitialBearing({
    required double latitude,
    required double longitude,
  }) {
    final lat1 = _degToRad(latitude);
    final lon1 = _degToRad(longitude);
    final lat2 = _degToRad(QiblaConstants.kaabaLatitude);
    final lon2 = _degToRad(QiblaConstants.kaabaLongitude);
    final deltaLon = lon2 - lon1;

    final y = math.sin(deltaLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);
    final bearing = _radToDeg(math.atan2(y, x));
    return (bearing + 360) % 360;
  }

  double _degToRad(double degrees) => degrees * math.pi / 180.0;
  double _radToDeg(double radians) => radians * 180.0 / math.pi;
}
