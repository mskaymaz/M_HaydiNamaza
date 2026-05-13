import 'package:flutter_test/flutter_test.dart';
import 'package:mhaydinamaza/features/qibla/qibla_bearing_calculator.dart';

void main() {
  group('QiblaBearingCalculator', () {
    const calculator = QiblaBearingCalculator();

    test('returns expected bearings for multiple cities', () {
      final references = <_CityBearingReference>[
        // Reference bearings are taken from true-north qibla pages (city-center values).
        _CityBearingReference(
          name: 'Istanbul',
          latitude: 41.0138,
          longitude: 28.9497,
          expectedBearing: 151.6,
        ),
        _CityBearingReference(
          name: 'Ankara',
          latitude: 39.9199,
          longitude: 32.8543,
          expectedBearing: 160.1,
        ),
        _CityBearingReference(
          name: 'New York City',
          latitude: 40.7143,
          longitude: -74.0060,
          expectedBearing: 58.5,
        ),
        _CityBearingReference(
          name: 'Jakarta',
          latitude: -6.2146,
          longitude: 106.8451,
          expectedBearing: 295.2,
        ),
      ];

      for (final reference in references) {
        final bearing = calculator.calculateInitialBearing(
          latitude: reference.latitude,
          longitude: reference.longitude,
        );
        expect(
          bearing,
          closeTo(reference.expectedBearing, 0.6),
          reason: '${reference.name} qibla bearing mismatch',
        );
      }
    });
  });
}

class _CityBearingReference {
  final String name;
  final double latitude;
  final double longitude;
  final double expectedBearing;

  const _CityBearingReference({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.expectedBearing,
  });
}
