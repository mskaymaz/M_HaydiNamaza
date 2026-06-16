import '../core/prayer_engine/calculation_method.dart';
import '../core/prayer_engine/calculation_parameters.dart';
import '../core/prayer_engine/high_latitude_rule.dart';
import '../core/prayer_engine/madhab.dart';
import '../core/prayer_engine/rounding.dart';
import '../core/prayer_engine/shafaq.dart';
import 'calculation_advanced_settings_storage.dart';

class PrayerCalculationParametersFactory {
  static CalculationParameters build({
    required String methodCode,
    required CalculationAdvancedSettings advancedSettings,
  }) {
    final params = _paramsFor(methodCode);
    return _applyAdvancedSettings(params, advancedSettings);
  }

  static CalculationParameters _paramsFor(String code) {
    switch (code) {
      case 'turkey':
      case 'diyanet':
      case 'diyanet_tabanli':
      case 'aladhan':
        return CalculationMethod.turkey();
      case 'muslim_world_league':
        return CalculationMethod.muslimWorldLeague();
      case 'umm_al_qura':
        return CalculationMethod.ummAlQura();
      case 'moonsighting':
        return CalculationMethod.moonsightingCommittee();
      case 'north_america':
        return CalculationMethod.northAmerica();
      default:
        return CalculationMethod.turkey();
    }
  }

  static CalculationParameters _applyAdvancedSettings(
    CalculationParameters params,
    CalculationAdvancedSettings settings,
  ) {
    params.madhab = settings.madhabCode == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    switch (settings.highLatitudeRuleCode) {
      case 'seventh_of_the_night':
        params.highLatitudeRule = HighLatitudeRule.seventhOfTheNight;
        break;
      case 'twilight_angle':
        params.highLatitudeRule = HighLatitudeRule.twilightAngle;
        break;
      case 'middle_of_the_night':
      default:
        params.highLatitudeRule = HighLatitudeRule.middleOfTheNight;
        break;
    }
    switch (settings.shafaqCode) {
      case 'ahmer':
        params.shafaq = Shafaq.ahmer;
        break;
      case 'abyad':
        params.shafaq = Shafaq.abyad;
        break;
      case 'general':
      default:
        params.shafaq = Shafaq.general;
        break;
    }
    switch (settings.roundingCode) {
      case 'up':
        params.rounding = Rounding.up;
        break;
      case 'none':
        params.rounding = Rounding.none;
        break;
      case 'nearest':
      default:
        params.rounding = Rounding.nearest;
        break;
    }
    params.adjustments = <String, int>{
      'fajr': settings.fajrOffsetMinutes,
      'sunrise': settings.sunriseOffsetMinutes,
      'dhuhr': settings.dhuhrOffsetMinutes,
      'asr': settings.asrOffsetMinutes,
      'maghrib': settings.maghribOffsetMinutes,
      'isha': settings.ishaOffsetMinutes,
    };
    return params;
  }
}
