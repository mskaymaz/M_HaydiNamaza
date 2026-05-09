import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import 'location_compact_dropdown.dart';
import 'location_section_card.dart';

class LocationSelectionSection extends StatelessWidget {
  final SettingsPanelsConfig ui;
  final UiPaletteConfig palette;
  final String title;
  final String countryLabel;
  final String cityLabel;
  final String districtLabel;
  final String? selectedCountryId;
  final String? selectedStateId;
  final String? selectedDistrictId;
  final List<DropdownMenuItem<String>> countryItems;
  final List<DropdownMenuItem<String>> stateItems;
  final List<DropdownMenuItem<String>> districtItems;
  final ValueChanged<String?>? onCountryChanged;
  final ValueChanged<String?>? onStateChanged;
  final ValueChanged<String?>? onDistrictChanged;
  final String? listLoadError;
  final VoidCallback onRetry;

  const LocationSelectionSection({
    super.key,
    required this.ui,
    required this.palette,
    required this.title,
    required this.countryLabel,
    required this.cityLabel,
    required this.districtLabel,
    required this.selectedCountryId,
    required this.selectedStateId,
    required this.selectedDistrictId,
    required this.countryItems,
    required this.stateItems,
    required this.districtItems,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onDistrictChanged,
    required this.listLoadError,
    required this.onRetry,
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
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: ui.sectionTitleSize,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: ui.fieldGap),
          LocationCompactDropdown<String>(
            value: selectedCountryId,
            palette: palette,
            label: countryLabel,
            items: countryItems,
            onChanged: onCountryChanged,
          ),
          SizedBox(height: ui.fieldGap),
          LocationCompactDropdown<String>(
            value: selectedStateId,
            palette: palette,
            label: cityLabel,
            items: stateItems,
            onChanged: onStateChanged,
          ),
          SizedBox(height: ui.fieldGap),
          LocationCompactDropdown<String>(
            value: selectedDistrictId,
            palette: palette,
            label: districtLabel,
            items: districtItems,
            onChanged: onDistrictChanged,
          ),
          if (listLoadError != null) ...[
            SizedBox(height: ui.fieldGap),
            Text(
              listLoadError!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                child: const Text('Tekrar dene'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
