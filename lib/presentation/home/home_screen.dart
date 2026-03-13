import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app/locale_controller.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final LocaleController localeController;

  const HomeScreen({super.key, required this.localeController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    localeController: localeController,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          l10n.homePlaceholder,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}
