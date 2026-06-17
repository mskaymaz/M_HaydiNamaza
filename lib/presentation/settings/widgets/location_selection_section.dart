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
  final TextEditingController searchController;
  final String searchHint;
  final String searchButtonLabel;
  final String? searchStatus;
  final bool searching;
  final String? selectedCountryId;
  final String? selectedStateId;
  final String? selectedDistrictId;
  final List<DropdownMenuItem<String>> countryItems;
  final List<DropdownMenuItem<String>> stateItems;
  final List<DropdownMenuItem<String>> districtItems;
  final ValueChanged<String?>? onCountryChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFindLocation;
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
    required this.searchController,
    required this.searchHint,
    required this.searchButtonLabel,
    required this.searchStatus,
    required this.searching,
    required this.selectedCountryId,
    required this.selectedStateId,
    required this.selectedDistrictId,
    required this.countryItems,
    required this.stateItems,
    required this.districtItems,
    required this.onCountryChanged,
    required this.onSearchChanged,
    required this.onFindLocation,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: onSearchChanged,
                  onSubmitted: (_) {
                    if (!searching) onFindLocation();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: searching ? null : onFindLocation,
                icon: searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.travel_explore_rounded),
                label: Text(searchButtonLabel),
              ),
            ],
          ),
          if (searchStatus != null && searchStatus!.isNotEmpty) ...[
            SizedBox(height: ui.fieldGap / 2),
            Text(
              searchStatus!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
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
