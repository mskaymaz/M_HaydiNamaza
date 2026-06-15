import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../../app/location_favorites_storage.dart';
import '../../../core/config/config_registry.dart';
import '../location_label_helpers.dart';
import '../location_models.dart';
import '../location_name_formatters.dart';
import '../location_selection_item_builders.dart';
import 'location_add_favorite_button.dart';
import 'location_coordinates_section.dart';
import 'location_current_location_tile.dart';
import 'location_favorites_section.dart';
import 'location_selection_composer.dart';

class LocationScreenContent extends StatelessWidget {
  final UiPaletteConfig palette;
  final SettingsPanelsConfig ui;
  final bool useCurrentLocation;
  final bool locating;
  final bool loadingCountries;
  final bool loadingStates;
  final bool loadingDistricts;
  final List<DiyanetItem> countries;
  final List<DiyanetItem> states;
  final List<DiyanetItem> districts;
  final String? selectedCountryId;
  final String? selectedStateId;
  final String? selectedDistrictId;
  final List<LocationFavorite> favorites;
  final LocationFavorite? selectedFavorite;
  final String? listLoadError;
  final TextEditingController provinceController;
  final TextEditingController districtController;
  final TextEditingController latController;
  final TextEditingController lonController;
  final ValueChanged<bool> onUseCurrentLocationChanged;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onStateChanged;
  final ValueChanged<String> onDistrictChanged;
  final VoidCallback onRetry;
  final VoidCallback onSaveCoordinates;
  final VoidCallback onAddFavorite;
  final ValueChanged<LocationFavorite> onFavoriteChanged;
  final VoidCallback? onApplyFavorite;
  final VoidCallback? onRemoveFavorite;

  const LocationScreenContent({
    super.key,
    required this.palette,
    required this.ui,
    required this.useCurrentLocation,
    required this.locating,
    required this.loadingCountries,
    required this.loadingStates,
    required this.loadingDistricts,
    required this.countries,
    required this.states,
    required this.districts,
    required this.selectedCountryId,
    required this.selectedStateId,
    required this.selectedDistrictId,
    required this.favorites,
    required this.selectedFavorite,
    required this.listLoadError,
    required this.provinceController,
    required this.districtController,
    required this.latController,
    required this.lonController,
    required this.onUseCurrentLocationChanged,
    required this.onCountryChanged,
    required this.onStateChanged,
    required this.onDistrictChanged,
    required this.onRetry,
    required this.onSaveCoordinates,
    required this.onAddFavorite,
    required this.onFavoriteChanged,
    required this.onApplyFavorite,
    required this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final countryValue = countries.any((item) => item.id == selectedCountryId)
        ? selectedCountryId
        : null;
    final stateValue = states.any((item) => item.id == selectedStateId)
        ? selectedStateId
        : null;
    final districtValue = districts.any((item) => item.id == selectedDistrictId)
        ? selectedDistrictId
        : null;
    return ListView(
      padding: ui.screenPadding,
      children: [
        LocationCurrentLocationTile(
          useCurrentLocation: useCurrentLocation,
          locating: locating,
          onChanged: (value) => onUseCurrentLocationChanged(value ?? false),
        ),
        SizedBox(height: ui.sectionGap),
        LocationSelectionComposer(
          ui: ui,
          palette: palette,
          title: l10n.locationSelectLabel,
          countryLabel: l10n.locationCountryLabel,
          cityLabel: l10n.locationCityLabel,
          districtLabel: l10n.locationDistrictLabel,
          selectedCountryId: countryValue,
          selectedStateId: stateValue,
          selectedDistrictId: districtValue,
          countryItems: buildStringDropdownItems<DiyanetItem>(
            items: countries,
            valueOf: (item) => item.id,
            labelOf: (item) => formatLocationDisplayName(item.name),
          ),
          stateItems: buildStringDropdownItems<DiyanetItem>(
            items: states,
            valueOf: (item) => item.id,
            labelOf: (item) => formatLocationDisplayName(item.name),
          ),
          districtItems: buildStringDropdownItems<DiyanetItem>(
            items: districts,
            valueOf: (item) => item.id,
            labelOf: (item) => formatLocationDisplayName(item.name),
          ),
          onCountryChanged: loadingCountries
              ? null
              : _forward(onCountryChanged),
          onStateChanged: loadingStates ? null : _forward(onStateChanged),
          onDistrictChanged: loadingDistricts
              ? null
              : _forward(onDistrictChanged),
          listLoadError: listLoadError,
          onRetry: onRetry,
        ),
        SizedBox(height: ui.sectionGap),
        LocationCoordinatesSection(
          ui: ui,
          palette: palette,
          latitudeLabel: l10n.locationLatitudeLabel,
          longitudeLabel: l10n.locationLongitudeLabel,
          latitudeController: latController,
          longitudeController: lonController,
          onSave: () => unawaited(Future<void>.microtask(onSaveCoordinates)),
        ),
        SizedBox(height: ui.sectionGap),
        LocationAddFavoriteButton(
          onPressed: onAddFavorite,
          label: l10n.locationAddFavorite,
        ),
        SizedBox(height: ui.sectionGap),
        LocationFavoritesSection(
          ui: ui,
          palette: palette,
          title: l10n.locationFavoritesLabel,
          emptyText: l10n.locationNotSet,
          closedLabel: currentFavoriteClosedLabel(
            favoritesLabel: l10n.locationFavoritesLabel,
            provinceText: provinceController.text,
            districtText: districtController.text,
          ),
          applyLabel: l10n.locationFavoriteApplyLabel,
          removeTooltip: l10n.locationFavoriteRemoveLabel,
          favorites: favorites,
          selectedFavorite: selectedFavorite,
          labelBuilder: favoriteLabel,
          onChanged: (favorite) {
            if (favorite != null) onFavoriteChanged(favorite);
          },
          onApply: onApplyFavorite,
          onRemove: onRemoveFavorite,
        ),
      ],
    );
  }

  ValueChanged<String?> _forward(ValueChanged<String> callback) {
    return (value) {
      if (value != null) callback(value);
    };
  }
}
