import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import 'settings_section_panel.dart';

class SettingsBackgroundColorsSection extends StatelessWidget {
  final EdgeInsets outerPadding;
  final SurfaceStyle panelStyle;
  final Widget header;
  final Widget backgroundColorTile;
  final Widget lineColorTile;
  final Widget resetButton;

  const SettingsBackgroundColorsSection({
    super.key,
    required this.outerPadding,
    required this.panelStyle,
    required this.header,
    required this.backgroundColorTile,
    required this.lineColorTile,
    required this.resetButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: outerPadding,
      child: SettingsSectionPanel(
        style: panelStyle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: backgroundColorTile),
                const SizedBox(width: 4),
                Expanded(child: lineColorTile),
                const SizedBox(width: 4),
                resetButton,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
