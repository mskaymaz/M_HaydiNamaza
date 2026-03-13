import 'calculation_parameters.dart';
import 'rounding.dart';

class CalculationMethod {
  static CalculationParameters muslimWorldLeague() {
    final params = CalculationParameters('MuslimWorldLeague', 18, 17);
    params.methodAdjustments['dhuhr'] = 1;
    return params;
  }

  static CalculationParameters egyptian() {
    final params = CalculationParameters('Egyptian', 19.5, 17.5);
    params.methodAdjustments['dhuhr'] = 1;
    return params;
  }

  static CalculationParameters karachi() {
    final params = CalculationParameters('Karachi', 18, 18);
    params.methodAdjustments['dhuhr'] = 1;
    return params;
  }

  static CalculationParameters ummAlQura() {
    return CalculationParameters('UmmAlQura', 18.5, 0, ishaInterval: 90);
  }

  static CalculationParameters dubai() {
    final params = CalculationParameters('Dubai', 18.2, 18.2);
    params.methodAdjustments = {
      ...params.methodAdjustments,
      'sunrise': -3,
      'dhuhr': 3,
      'asr': 3,
      'maghrib': 3,
    };
    return params;
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

  static CalculationParameters kuwait() {
    return CalculationParameters('Kuwait', 18, 17.5);
  }

  static CalculationParameters qatar() {
    return CalculationParameters('Qatar', 18, 0, ishaInterval: 90);
  }

  static CalculationParameters singapore() {
    final params = CalculationParameters('Singapore', 20, 18);
    params.methodAdjustments['dhuhr'] = 1;
    params.rounding = Rounding.up;
    return params;
  }

  static CalculationParameters tehran() {
    return CalculationParameters('Tehran', 17.7, 14, maghribAngle: 4.5);
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

  static CalculationParameters other() {
    return CalculationParameters('Other', 0, 0);
  }
}
