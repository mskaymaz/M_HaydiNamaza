import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app/locale_controller.dart';

class SettingsScreen extends StatelessWidget {
  final LocaleController localeController;

  const SettingsScreen({super.key, required this.localeController});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = localeController.value;

    String codeFor(Locale? locale) => locale?.languageCode ?? 'system';

    Locale? localeFor(String code) {
      switch (code) {
        case 'tr':
          return const Locale('tr');
        case 'en':
          return const Locale('en');
        case 'ar':
          return const Locale('ar');
        case 'system':
        default:
          return null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.languageLabel),
          ),
          RadioListTile<String>(
            title: Text(l10n.languageSystem),
            value: 'system',
            groupValue: codeFor(current),
            onChanged: (value) async {
              if (value == null) return;
              await localeController.setLocale(localeFor(value));
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.languageTurkish),
            value: 'tr',
            groupValue: codeFor(current),
            onChanged: (value) async {
              if (value == null) return;
              await localeController.setLocale(localeFor(value));
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.languageEnglish),
            value: 'en',
            groupValue: codeFor(current),
            onChanged: (value) async {
              if (value == null) return;
              await localeController.setLocale(localeFor(value));
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.languageArabic),
            value: 'ar',
            groupValue: codeFor(current),
            onChanged: (value) async {
              if (value == null) return;
              await localeController.setLocale(localeFor(value));
            },
          ),
        ],
      ),
    );
  }
}
