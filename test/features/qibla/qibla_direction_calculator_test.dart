import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mhaydinamaza/features/qibla/domain/qibla_direction_calculator.dart';

void main() {
  group('QiblaDirectionCalculator', () {
    test('normalizes negative and overflow degrees', () {
      expect(QiblaDirectionCalculator.normalizeDegrees(-10), 350);
      expect(QiblaDirectionCalculator.normalizeDegrees(370), 10);
    });

    test('calculates target minus heading rotation', () {
      expect(
        QiblaDirectionCalculator.rotationDegrees(
          targetDegrees: 154,
          headingDegrees: 100,
        ),
        54,
      );
      expect(
        QiblaDirectionCalculator.rotationDegrees(
          targetDegrees: 10,
          headingDegrees: 350,
        ),
        20,
      );
    });

    test('converts rotation to radians', () {
      final radians = QiblaDirectionCalculator.rotationRadians(
        targetDegrees: 180,
        headingDegrees: 90,
      );
      expect(radians, closeTo(math.pi / 2, 0.0001));
    });

    test('detects heading alignment within tolerance', () {
      expect(
        QiblaDirectionCalculator.isAligned(
          targetDegrees: 154,
          headingDegrees: 150,
        ),
        isTrue,
      );
      expect(
        QiblaDirectionCalculator.isAligned(
          targetDegrees: 154,
          headingDegrees: 140,
        ),
        isFalse,
      );
    });
  });
}
