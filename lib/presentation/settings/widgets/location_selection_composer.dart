import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import 'location_selection_section.dart';

class LocationSelectionComposer extends StatelessWidget {
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

  const LocationSelectionComposer({
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
    return LocationSelectionSection(
      ui: ui,
      palette: palette,
      title: title,
      countryLabel: countryLabel,
      cityLabel: cityLabel,
      districtLabel: districtLabel,
      searchController: searchController,
      searchHint: searchHint,
      searchButtonLabel: searchButtonLabel,
      searchStatus: searchStatus,
      searching: searching,
      onSearchChanged: onSearchChanged,
      onFindLocation: onFindLocation,
      selectedCountryId: selectedCountryId,
      selectedStateId: selectedStateId,
      selectedDistrictId: selectedDistrictId,
      countryItems: countryItems,
      stateItems: stateItems,
      districtItems: districtItems,
      onCountryChanged: onCountryChanged,
      onStateChanged: onStateChanged,
      onDistrictChanged: onDistrictChanged,
      listLoadError: listLoadError,
      onRetry: onRetry,
    );
  }
}
