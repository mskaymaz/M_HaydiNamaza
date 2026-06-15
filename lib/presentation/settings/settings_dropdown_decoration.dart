import 'package:flutter/material.dart';

import '../../core/config/config_registry.dart';

InputDecoration settingsDropdownDecoration({
  required UiPaletteConfig palette,
  required String label,
}) {
  final ui = ConfigRegistry.settingsPanelsFor(palette);
  return InputDecoration(
    labelText: label,
    isDense: true,
    filled: true,
    fillColor: ui.itemPanel.color,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: ui.itemPanel.borderRadius,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: ui.itemPanel.borderRadius,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: ui.itemPanel.borderRadius,
      borderSide: BorderSide(color: palette.zeminColor),
    ),
  );
}
