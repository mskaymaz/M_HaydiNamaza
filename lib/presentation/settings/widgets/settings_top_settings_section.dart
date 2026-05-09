import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import 'settings_calculation_method_row.dart';
import 'settings_language_location_row.dart';

class SettingsTopSettingsSection extends StatelessWidget {
  final String initialLanguageCode;
  final InputDecoration languageDecoration;
  final String languageSystemLabel;
  final String languageTurkishLabel;
  final String languageEnglishLabel;
  final String languageArabicLabel;
  final Future<void> Function(String code) onLanguageChanged;
  final Future<void> Function() onOpenLocation;
  final SurfaceStyle calculationItemPanelStyle;
  final String calculationTitle;
  final String calculationSubtitle;
  final Future<void> Function() onOpenCalculationMethod;

  const SettingsTopSettingsSection({
    super.key,
    required this.initialLanguageCode,
    required this.languageDecoration,
    required this.languageSystemLabel,
    required this.languageTurkishLabel,
    required this.languageEnglishLabel,
    required this.languageArabicLabel,
    required this.onLanguageChanged,
    required this.onOpenLocation,
    required this.calculationItemPanelStyle,
    required this.calculationTitle,
    required this.calculationSubtitle,
    required this.onOpenCalculationMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsLanguageLocationRow(
          initialLanguageCode: initialLanguageCode,
          languageDecoration: languageDecoration,
          languageSystemLabel: languageSystemLabel,
          languageTurkishLabel: languageTurkishLabel,
          languageEnglishLabel: languageEnglishLabel,
          languageArabicLabel: languageArabicLabel,
          onLanguageChanged: onLanguageChanged,
          onOpenLocation: onOpenLocation,
        ),
        SettingsCalculationMethodRow(
          itemPanelStyle: calculationItemPanelStyle,
          title: calculationTitle,
          subtitle: calculationSubtitle,
          onTap: onOpenCalculationMethod,
        ),
        const Divider(height: 32),
      ],
    );
  }
}
