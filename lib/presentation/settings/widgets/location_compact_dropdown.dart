import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';

class LocationCompactDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final UiPaletteConfig palette;

  const LocationCompactDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: ConfigRegistry.settingsPanelsFor(palette).itemPanel.color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.zeminColor),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      menuMaxHeight: 280,
      items: items,
      onChanged: onChanged,
    );
  }
}
