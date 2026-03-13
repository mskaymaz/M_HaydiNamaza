import 'package:flutter/widgets.dart';

import 'locale_storage.dart';

class LocaleController extends ValueNotifier<Locale?> {
  final LocaleStorage _storage;

  LocaleController({LocaleStorage? storage})
      : _storage = storage ?? LocaleStorage(),
        super(null);

  Future<void> load() async {
    final code = await _storage.readCode();
    value = _localeFromCode(code);
  }

  Future<void> setLocale(Locale? locale) async {
    value = locale;
    await _storage.writeCode(_codeFromLocale(locale));
  }

  Locale? _localeFromCode(String? code) {
    switch (code) {
      case 'tr':
        return const Locale('tr');
      case 'en':
        return const Locale('en');
      case 'ar':
        return const Locale('ar');
      case 'system':
      case null:
      default:
        return null;
    }
  }

  String _codeFromLocale(Locale? locale) {
    return locale?.languageCode ?? 'system';
  }
}
