import 'package:shared_preferences/shared_preferences.dart';

class CalculationAdvancedSettings {
  final String madhabCode;
  final String highLatitudeRuleCode;
  final String shafaqCode;
  final String roundingCode;
  final int fajrOffsetMinutes;
  final int sunriseOffsetMinutes;
  final int dhuhrOffsetMinutes;
  final int asrOffsetMinutes;
  final int maghribOffsetMinutes;
  final int ishaOffsetMinutes;

  const CalculationAdvancedSettings({
    this.madhabCode = 'shafi',
    this.highLatitudeRuleCode = 'middle_of_the_night',
    this.shafaqCode = 'general',
    this.roundingCode = 'nearest',
    this.fajrOffsetMinutes = 0,
    this.sunriseOffsetMinutes = 0,
    this.dhuhrOffsetMinutes = 0,
    this.asrOffsetMinutes = 0,
    this.maghribOffsetMinutes = 0,
    this.ishaOffsetMinutes = 0,
  });
}

class CalculationAdvancedSettingsStorage {
  static const String _madhabKey = 'calc_adv_madhab';
  static const String _highLatitudeRuleKey = 'calc_adv_high_latitude_rule';
  static const String _shafaqKey = 'calc_adv_shafaq';
  static const String _roundingKey = 'calc_adv_rounding';
  static const String _fajrOffsetKey = 'calc_adv_offset_fajr';
  static const String _sunriseOffsetKey = 'calc_adv_offset_sunrise';
  static const String _dhuhrOffsetKey = 'calc_adv_offset_dhuhr';
  static const String _asrOffsetKey = 'calc_adv_offset_asr';
  static const String _maghribOffsetKey = 'calc_adv_offset_maghrib';
  static const String _ishaOffsetKey = 'calc_adv_offset_isha';

  Future<CalculationAdvancedSettings> read() async {
    final prefs = await SharedPreferences.getInstance();
    return CalculationAdvancedSettings(
      madhabCode: _safeMadhab(prefs.getString(_madhabKey)),
      highLatitudeRuleCode: _safeHighLatitudeRule(
        prefs.getString(_highLatitudeRuleKey),
      ),
      shafaqCode: _safeShafaq(prefs.getString(_shafaqKey)),
      roundingCode: _safeRounding(prefs.getString(_roundingKey)),
      fajrOffsetMinutes: _clampOffset(prefs.getInt(_fajrOffsetKey)),
      sunriseOffsetMinutes: _clampOffset(prefs.getInt(_sunriseOffsetKey)),
      dhuhrOffsetMinutes: _clampOffset(prefs.getInt(_dhuhrOffsetKey)),
      asrOffsetMinutes: _clampOffset(prefs.getInt(_asrOffsetKey)),
      maghribOffsetMinutes: _clampOffset(prefs.getInt(_maghribOffsetKey)),
      ishaOffsetMinutes: _clampOffset(prefs.getInt(_ishaOffsetKey)),
    );
  }

  Future<void> write(CalculationAdvancedSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_madhabKey, _safeMadhab(settings.madhabCode));
    await prefs.setString(
      _highLatitudeRuleKey,
      _safeHighLatitudeRule(settings.highLatitudeRuleCode),
    );
    await prefs.setString(_shafaqKey, _safeShafaq(settings.shafaqCode));
    await prefs.setString(_roundingKey, _safeRounding(settings.roundingCode));
    await prefs.setInt(_fajrOffsetKey, _clampOffset(settings.fajrOffsetMinutes));
    await prefs.setInt(
      _sunriseOffsetKey,
      _clampOffset(settings.sunriseOffsetMinutes),
    );
    await prefs.setInt(_dhuhrOffsetKey, _clampOffset(settings.dhuhrOffsetMinutes));
    await prefs.setInt(_asrOffsetKey, _clampOffset(settings.asrOffsetMinutes));
    await prefs.setInt(
      _maghribOffsetKey,
      _clampOffset(settings.maghribOffsetMinutes),
    );
    await prefs.setInt(_ishaOffsetKey, _clampOffset(settings.ishaOffsetMinutes));
  }

  String _safeMadhab(String? input) {
    return input == 'hanafi' ? 'hanafi' : 'shafi';
  }

  String _safeHighLatitudeRule(String? input) {
    switch (input) {
      case 'seventh_of_the_night':
      case 'twilight_angle':
        return input!;
      case 'middle_of_the_night':
      default:
        return 'middle_of_the_night';
    }
  }

  String _safeShafaq(String? input) {
    switch (input) {
      case 'ahmer':
      case 'abyad':
        return input!;
      case 'general':
      default:
        return 'general';
    }
  }

  String _safeRounding(String? input) {
    switch (input) {
      case 'up':
      case 'none':
        return input!;
      case 'nearest':
      default:
        return 'nearest';
    }
  }

  int _clampOffset(int? value) {
    return (value ?? 0).clamp(-120, 120);
  }
}
