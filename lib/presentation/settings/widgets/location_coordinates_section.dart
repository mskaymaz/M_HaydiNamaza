import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import 'location_section_card.dart';

class LocationCoordinatesSection extends StatelessWidget {
  final SettingsPanelsConfig ui;
  final UiPaletteConfig palette;
  final String latitudeLabel;
  final String longitudeLabel;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final VoidCallback onSave;

  const LocationCoordinatesSection({
    super.key,
    required this.ui,
    required this.palette,
    required this.latitudeLabel,
    required this.longitudeLabel,
    required this.latitudeController,
    required this.longitudeController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return LocationSectionCard(
      style: ui.panel,
      padding: ui.sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$latitudeLabel / $longitudeLabel',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: ui.sectionTitleSize,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: ui.fieldGap),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: latitudeController,
                  decoration: _coordinateDecoration(ui, palette, latitudeLabel),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              SizedBox(width: ui.coordinateGap),
              Expanded(
                child: TextField(
                  controller: longitudeController,
                  decoration: _coordinateDecoration(ui, palette, longitudeLabel),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSave(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _coordinateDecoration(
    SettingsPanelsConfig ui,
    UiPaletteConfig palette,
    String label,
  ) {
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
}
