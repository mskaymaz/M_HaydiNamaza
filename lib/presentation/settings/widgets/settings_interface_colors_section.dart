import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import 'settings_section_panel.dart';

class SettingsInterfaceColorsSection extends StatelessWidget {
  final EdgeInsets outerPadding;
  final SurfaceStyle panelStyle;
  final Widget header;
  final Widget panelColorTile;
  final Widget textColorTile;
  final Widget resetButton;

  const SettingsInterfaceColorsSection({
    super.key,
    required this.outerPadding,
    required this.panelStyle,
    required this.header,
    required this.panelColorTile,
    required this.textColorTile,
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
                Expanded(child: panelColorTile),
                const SizedBox(width: 4),
                Expanded(child: textColorTile),
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
