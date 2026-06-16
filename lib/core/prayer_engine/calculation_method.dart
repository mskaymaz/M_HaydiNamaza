import 'calculation_parameters.dart';

class CalculationMethod {
  static CalculationParameters muslimWorldLeague() {
    final params = CalculationParameters('MuslimWorldLeague', 18, 17);
    params.methodAdjustments['dhuhr'] = 1;
    return params;
  }

  static CalculationParameters ummAlQura() {
    return CalculationParameters('UmmAlQura', 18.5, 0, ishaInterval: 90);
  }

  static CalculationParameters moonsightingCommittee() {
    final params = CalculationParameters('MoonsightingCommittee', 18, 18);
    params.methodAdjustments = {
      ...params.methodAdjustments,
      'dhuhr': 5,
      'maghrib': 3,
    };
    return params;
  }

  static CalculationParameters northAmerica() {
    final params = CalculationParameters('NorthAmerica', 15, 15);
    params.methodAdjustments['dhuhr'] = 1;
    return params;
  }

  static CalculationParameters turkey() {
    final params = CalculationParameters('Turkey', 18, 17);
    params.methodAdjustments = {
      ...params.methodAdjustments,
      'sunrise': -7,
      'dhuhr': 5,
      'asr': 4,
      'maghrib': 7,
    };
    return params;
  }
}
