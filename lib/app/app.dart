import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../presentation/home/home_screen.dart';
import 'locale_controller.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final LocaleController _localeController = LocaleController();

  @override
  void initState() {
    super.initState();
    _localeController.load();
  }

  @override
  void dispose() {
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: _localeController,
      builder: (context, locale, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(localeController: _localeController),
        );
      },
    );
  }
}
