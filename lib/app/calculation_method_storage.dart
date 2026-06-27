import 'package:shared_preferences/shared_preferences.dart';

class CalculationMethodStorage {
  static const String _key = 'calculation_method_code';
  static const String defaultCode = 'diyanet';
  static const Set<String> _supportedCodes = <String>{
    'aladhan',
    'turkey',
    'diyanet',
    'umm_al_qura',
    'muslim_world_league',
    'moonsighting',
    'north_america',
  };

  Future<String?> readCode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final code = _normalize(raw);
    if (code != raw) await prefs.setString(_key, code);
    return code;
  }

  Future<void> writeCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _normalize(code));
  }

  String _normalize(String? code) {
    if (code == 'diyanet_tabanli') return 'diyanet';
    return _supportedCodes.contains(code) ? code! : defaultCode;
  }
}

