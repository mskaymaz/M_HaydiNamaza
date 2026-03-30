import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../presentation/home/home_screen.dart';
import 'locale_controller.dart';
import 'runtime_monitor.dart';
import 'ui_palette_controller.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final LocaleController _localeController = LocaleController();
  final UiPaletteController _uiPaletteController = UiPaletteController();

  @override
  void initState() {
    super.initState();
    _localeController.load();
    _uiPaletteController.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RuntimeMonitor.instance.markFirstFrameRendered();
    });
  }

  @override
  void dispose() {
    _localeController.dispose();
    _uiPaletteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: _localeController,
      builder: (context, locale, _) {
        return ValueListenableBuilder(
          valueListenable: _uiPaletteController,
          builder: (context, palette, _) {
            final colorScheme = ColorScheme.fromSeed(seedColor: palette.zeminColor);
            return MaterialApp(
              onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
              theme: ThemeData(
                colorScheme: colorScheme,
                useMaterial3: true,
                appBarTheme: AppBarTheme(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.onSurface,
                ),
              ),
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: HomeScreen(
                localeController: _localeController,
                uiPaletteController: _uiPaletteController,
              ),
            );
          },
        );
      },
    );
  }
}
