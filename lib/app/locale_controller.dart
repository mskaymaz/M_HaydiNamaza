import 'package:flutter/widgets.dart';

class LocaleController extends ValueNotifier<Locale?> {
  LocaleController() : super(null);

  void setLocale(Locale? locale) {
    value = locale;
  }
}
