import 'package:shared_preferences/shared_preferences.dart';

class CalculationMethodStorage {
  static const String _key = 'calculation_method_code';
  static const String defaultCode = 'aladhan';

  Future<String?> readCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? defaultCode;
  }

  Future<void> writeCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
