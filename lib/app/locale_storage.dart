import 'package:shared_preferences/shared_preferences.dart';

class LocaleStorage {
  static const String _key = 'locale_code';

  Future<String?> readCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> writeCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
