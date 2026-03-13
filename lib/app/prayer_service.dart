import '../core/prayer_engine/calculation_method.dart';
import '../core/prayer_engine/calculation_parameters.dart';
import '../core/prayer_engine/coordinates.dart';
import '../core/prayer_engine/prayer_engine.dart';
import '../core/prayer_engine/prayer_times.dart';

class PrayerService {
  final PrayerEngine _engine;

  PrayerService({PrayerEngine? engine}) : _engine = engine ?? const PrayerEngine();

  PrayerTimes calculateToday({
    required double latitude,
    required double longitude,
    required String timeZone,
    required String methodCode,
  }) {
    final params = _paramsFor(methodCode);
    return _engine.calculate(
      date: DateTime.now(),
      coordinates: Coordinates(latitude, longitude),
      timeZone: timeZone,
      params: params,
    );
  }

  CalculationParameters _paramsFor(String code) {
    switch (code) {
      case 'turkey':
        return CalculationMethod.turkey();
      case 'muslim_world_league':
        return CalculationMethod.muslimWorldLeague();
      case 'umm_al_qura':
        return CalculationMethod.ummAlQura();
      case 'dubai':
        return CalculationMethod.dubai();
      case 'kuwait':
        return CalculationMethod.kuwait();
      case 'qatar':
        return CalculationMethod.qatar();
      case 'singapore':
        return CalculationMethod.singapore();
      case 'tehran':
        return CalculationMethod.tehran();
      case 'moonsighting':
        return CalculationMethod.moonsightingCommittee();
      case 'north_america':
        return CalculationMethod.northAmerica();
      case 'egyptian':
        return CalculationMethod.egyptian();
      case 'karachi':
        return CalculationMethod.karachi();
      case 'other':
      default:
        return CalculationMethod.other();
    }
  }
}
