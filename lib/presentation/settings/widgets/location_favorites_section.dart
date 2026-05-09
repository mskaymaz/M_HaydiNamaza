import 'package:flutter/material.dart';

import '../../../app/location_favorites_storage.dart';
import '../../../core/config/config_registry.dart';
import 'location_compact_dropdown.dart';
import 'location_section_card.dart';

class LocationFavoritesSection extends StatelessWidget {
  final SettingsPanelsConfig ui;
  final UiPaletteConfig palette;
  final String title;
  final String emptyText;
  final String closedLabel;
  final String applyLabel;
  final String removeTooltip;
  final List<LocationFavorite> favorites;
  final LocationFavorite? selectedFavorite;
  final String Function(LocationFavorite favorite) labelBuilder;
  final ValueChanged<LocationFavorite?> onChanged;
  final VoidCallback? onApply;
  final VoidCallback? onRemove;

  const LocationFavoritesSection({
    super.key,
    required this.ui,
    required this.palette,
    required this.title,
    required this.emptyText,
    required this.closedLabel,
    required this.applyLabel,
    required this.removeTooltip,
    required this.favorites,
    required this.selectedFavorite,
    required this.labelBuilder,
    required this.onChanged,
    required this.onApply,
    required this.onRemove,
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: ui.fieldGap),
          if (favorites.isEmpty)
            Text(emptyText)
          else
            Row(
              children: [
                Expanded(
                  child: LocationCompactDropdown<LocationFavorite>(
                    value: favorites.contains(selectedFavorite) ? selectedFavorite : null,
                    palette: palette,
                    label: closedLabel,
                    items: favorites
                        .map(
                          (favorite) => DropdownMenuItem<LocationFavorite>(
                            value: favorite,
                            child: Text(labelBuilder(favorite)),
                          ),
                        )
                        .toList(),
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onApply,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(applyLabel),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  visualDensity: VisualDensity.compact,
                  tooltip: removeTooltip,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
