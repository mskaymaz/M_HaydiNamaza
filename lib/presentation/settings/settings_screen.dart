import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/calculation_method_storage.dart';
import '../../app/locale_controller.dart';
import '../../app/location_favorites_storage.dart';
import '../../app/location_storage.dart';
import 'calculation_method_screen.dart';
import 'location_screen.dart';

class SettingsScreen extends StatefulWidget {
  final LocaleController localeController;

  const SettingsScreen({super.key, required this.localeController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocationStorage _locationStorage = LocationStorage();
  final LocationFavoritesStorage _favoritesStorage = LocationFavoritesStorage();
  final CalculationMethodStorage _methodStorage = CalculationMethodStorage();
  LocationData? _location;
  List<LocationFavorite> _favorites = [];
  LocationFavorite? _selectedFavorite;
  String? _methodCode;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadFavorites();
    _loadMethod();
  }

  Future<void> _loadLocation() async {
    final data = await _locationStorage.read();
    if (!mounted) return;
    final matched = _matchFavorite(data, _favorites);
    setState(() {
      _location = data;
      _selectedFavorite = matched;
    });
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesStorage.read();
    if (!mounted) return;
    final matched = _matchFavorite(_location, favorites);
    setState(() {
      _favorites = favorites;
      _selectedFavorite = _selectedFavorite != null &&
              favorites.contains(_selectedFavorite)
          ? _selectedFavorite
          : matched;
    });
  }

  Future<void> _loadMethod() async {
    var code = await _methodStorage.readCode();
    if (code == null) {
      code = 'turkey';
      await _methodStorage.writeCode(code);
    }
    if (!mounted) return;
    setState(() {
      _methodCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = widget.localeController.value;

    String locationSubtitle() {
      final data = _location;
      if (data == null) return l10n.locationNotSet;
      final coords = data.latitude.trim().isEmpty || data.longitude.trim().isEmpty
          ? ''
          : '\n${data.latitude}, ${data.longitude}';
      return '${_formatLocationSummary(data)}$coords';
    }

    String methodSubtitle() {
      switch (_methodCode) {
        case 'turkey':
          return l10n.methodTurkey;
        case 'aladhan':
          return l10n.methodAladhan;
        case 'muslim_world_league':
          return l10n.methodMuslimWorldLeague;
        case 'umm_al_qura':
          return l10n.methodUmmAlQura;
        case 'dubai':
          return l10n.methodDubai;
        case 'kuwait':
          return l10n.methodKuwait;
        case 'qatar':
          return l10n.methodQatar;
        case 'singapore':
          return l10n.methodSingapore;
        case 'tehran':
          return l10n.methodTehran;
        case 'moonsighting':
          return l10n.methodMoonsighting;
        case 'north_america':
          return l10n.methodNorthAmerica;
        case 'egyptian':
          return l10n.methodEgyptian;
        case 'karachi':
          return l10n.methodKarachi;
        case 'other':
          return l10n.methodOther;
        default:
          return l10n.methodNotSet;
      }
    }

    String codeFor(Locale? locale) => locale?.languageCode ?? 'system';

    Locale? localeFor(String code) {
      switch (code) {
        case 'tr':
          return const Locale('tr');
        case 'en':
          return const Locale('en');
        case 'ar':
          return const Locale('ar');
        case 'system':
        default:
          return null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<String>(
              value: codeFor(current),
              decoration: _dropdownDecoration(l10n.languageLabel),
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.languageSystem),
                ),
                DropdownMenuItem(value: 'tr', child: Text(l10n.languageTurkish)),
                DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                DropdownMenuItem(value: 'ar', child: Text(l10n.languageArabic)),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await widget.localeController.setLocale(localeFor(value));
              },
            ),
          ),
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<LocationFavorite>(
                    value: _favorites.contains(_selectedFavorite)
                        ? _selectedFavorite
                        : null,
                    decoration:
                        _dropdownDecoration(_currentFavoriteClosedLabel(l10n)),
                    items: _favorites
                        .map(
                          (favorite) => DropdownMenuItem<LocationFavorite>(
                            value: favorite,
                            child: Text(_formatFavoriteLabel(favorite)),
                          ),
                        )
                        .toList(),
                    onChanged: _favorites.isEmpty
                        ? null
                        : (favorite) {
                            if (favorite == null) return;
                            setState(() {
                              _selectedFavorite = favorite;
                            });
                          },
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _selectedFavorite == null
                      ? null
                      : () async {
                          final favorite = _selectedFavorite!;
                          final data = LocationData(
                            countryId: favorite.countryId,
                            countryName: favorite.countryName,
                            province: favorite.province,
                            district: favorite.district,
                            latitude: favorite.latitude,
                            longitude: favorite.longitude,
                          );
                          await _locationStorage.write(data);
                          if (!mounted) return;
                          setState(() {
                            _location = data;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.locationFavoriteApplied),
                            ),
                          );
                        },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(l10n.locationFavoriteApplyLabel),
                ),
                IconButton(
                  onPressed: _selectedFavorite == null
                      ? null
                      : () async {
                          final favorite = _selectedFavorite!;
                          final removed = await _favoritesStorage.remove(favorite);
                          if (!mounted || !removed) return;
                          await _loadFavorites();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.locationFavoriteRemoved),
                            ),
                          );
                        },
                  icon: const Icon(Icons.delete_outline),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.locationFavoriteRemoveLabel,
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.locationSelectLabel),
            subtitle: Text(locationSubtitle()),
            trailing: const Icon(Icons.location_on_outlined),
            subtitleTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                ),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => LocationScreen(initial: _location),
                ),
              );
              if (changed == true) {
                await _loadLocation();
                await _loadFavorites();
              }
            },
          ),
          ListTile(
            title: Text(l10n.calculationMethodLabel),
            subtitle: Text(methodSubtitle()),
            trailing: const Icon(Icons.calculate_outlined),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CalculationMethodScreen(
                    initialCode: _methodCode,
                  ),
                ),
              );
              if (changed == true) {
                await _loadMethod();
              }
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
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
        borderSide: const BorderSide(color: Color(0xFF1F7A3E)),
      ),
    );
  }

  String _formatDisplayName(String input) {
    final trimmed = _normalizeSpacing(input);
    if (trimmed.isEmpty) return trimmed;
    final lower = trimmed
        .replaceAll('I', String.fromCharCode(0x0131))
        .replaceAll(String.fromCharCode(0x0130), 'i')
        .toLowerCase();
    final parts = lower.split(RegExp(r'(\s+|/|-)'));
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part.isEmpty) continue;
      final isSeparator = RegExp(r'^\s+$|^/$|^-$').hasMatch(part);
      if (isSeparator) {
        buffer.write(part);
        continue;
      }
      buffer.write(_capitalizeFirst(part[0]));
      if (part.length > 1) {
        buffer.write(part.substring(1));
      }
    }
    return buffer.toString();
  }

  String _capitalizeFirst(String char) {
    if (char == 'i') return String.fromCharCode(0x0130);
    if (char == String.fromCharCode(0x0131)) return 'I';
    return char.toUpperCase();
  }

  String _formatLocationSummary(LocationData data) {
    final province = _formatDisplayName(data.province);
    final district = _formatDisplayName(data.district);
    if (district.isEmpty) return province;
    return '$province / $district';
  }

  String _formatFavoriteLabel(LocationFavorite favorite) {
    return _formatLocationSummary(
      LocationData(
        countryId: favorite.countryId,
        countryName: favorite.countryName,
        province: favorite.province,
        district: favorite.district,
        latitude: favorite.latitude,
        longitude: favorite.longitude,
      ),
    );
  }

  String _currentFavoriteClosedLabel(AppLocalizations l10n) {
    final data = _location;
    if (data == null) return l10n.locationFavoritesLabel;
    return _formatLocationSummary(data);
  }

  String _normalizeSpacing(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  LocationFavorite? _matchFavorite(
    LocationData? data,
    List<LocationFavorite> favorites,
  ) {
    if (data == null) return null;
    for (final favorite in favorites) {
      final sameCountry = (favorite.countryId ?? '') == (data.countryId ?? '');
      final sameProvince =
          _normalizeSpacing(favorite.province).toUpperCase() ==
          _normalizeSpacing(data.province).toUpperCase();
      final sameDistrict =
          _normalizeSpacing(favorite.district).toUpperCase() ==
          _normalizeSpacing(data.district).toUpperCase();
      if (sameCountry && sameProvince && sameDistrict) {
        return favorite;
      }
    }
    return null;
  }
}
