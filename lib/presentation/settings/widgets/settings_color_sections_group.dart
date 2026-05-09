import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import 'settings_background_colors_section.dart';
import 'settings_color_action_widgets.dart';
import 'settings_interface_colors_section.dart';
import 'settings_section_header.dart';

class SettingsColorSectionsGroup extends StatelessWidget {
  final EdgeInsets outerPadding;
  final SurfaceStyle panelStyle;
  final Color panelColor;
  final Color textColor;
  final Color backgroundColor;
  final Color backgroundLineColor;
  final VoidCallback onEditPanelColor;
  final VoidCallback onEditTextColor;
  final VoidCallback onEditBackgroundColor;
  final VoidCallback onEditBackgroundLineColor;
  final Future<void> Function() onResetInterfaceColors;
  final Future<void> Function() onResetBackgroundColors;

  const SettingsColorSectionsGroup({
    super.key,
    required this.outerPadding,
    required this.panelStyle,
    required this.panelColor,
    required this.textColor,
    required this.backgroundColor,
    required this.backgroundLineColor,
    required this.onEditPanelColor,
    required this.onEditTextColor,
    required this.onEditBackgroundColor,
    required this.onEditBackgroundLineColor,
    required this.onResetInterfaceColors,
    required this.onResetBackgroundColors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsInterfaceColorsSection(
          outerPadding: outerPadding,
          panelStyle: panelStyle,
          header: const SettingsSectionHeader(
            title: 'Arayüz Renkleri',
            tooltip: 'Panel ve yazı renklerini değiştir.',
          ),
          panelColorTile: SettingsColorActionTile(
            title: 'Panel Rengi',
            color: panelColor,
            onTap: onEditPanelColor,
          ),
          textColorTile: SettingsColorActionTile(
            title: 'Yazı Rengi',
            color: textColor,
            onTap: onEditTextColor,
          ),
          resetButton: SettingsResetIconButton(
            onTap: onResetInterfaceColors,
          ),
        ),
        SettingsBackgroundColorsSection(
          outerPadding: outerPadding,
          panelStyle: panelStyle,
          header: const SettingsSectionHeader(
            title: 'Arka Plan Renkleri',
            tooltip: 'Geometrik arka planın zemin ve çizgi renklerini değiştir.',
          ),
          backgroundColorTile: SettingsColorActionTile(
            title: 'Zemin Rengi',
            color: backgroundColor,
            onTap: onEditBackgroundColor,
          ),
          lineColorTile: SettingsColorActionTile(
            title: 'Çizgi Rengi',
            color: backgroundLineColor,
            onTap: onEditBackgroundLineColor,
          ),
          resetButton: SettingsResetIconButton(
            onTap: onResetBackgroundColors,
          ),
        ),
      ],
    );
  }
}
