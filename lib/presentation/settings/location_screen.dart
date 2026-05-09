import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/location_favorites_storage.dart';
import '../../app/location_storage.dart';
import '../../app/ui_palette_controller.dart';
import '../../core/config/config_registry.dart';

class LocationScreen extends StatefulWidget {
  final LocationData? initial;
  final UiPaletteController uiPaletteController;

  const LocationScreen({
    super.key,
    this.initial,
    required this.uiPaletteController,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  static const Duration _diyanetTimeout = Duration(seconds: 12);
  static const Map<String, String> _diyanetHeaders = <String, String>{
    'Accept': 'application/json',
    'User-Agent': 'HaydiNamaza/1.0',
  };
  static const String _listLoadErrorMessage =
      'Konum listesi yuklenemedi. Lutfen tekrar deneyin.';

  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _storage = LocationStorage();
  final _favoritesStorage = LocationFavoritesStorage();

  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingDistricts = false;
  List<_DiyanetItem> _countries = [];
  List<_DiyanetItem> _states = [];
  List<_DiyanetItem> _districts = [];
  String? _selectedCountryId;
  String _selectedCountryName = '';
  String? _selectedStateId;
  String? _selectedDistrictId;
  List<LocationFavorite> _favorites = [];
  LocationFavorite? _selectedFavorite;
  String? _listLoadError;
  bool _useCurrentLocation = false;
  bool _locating = false;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _selectedCountryId = initial.countryId;
      _selectedCountryName = initial.countryName ?? '';
      _provinceController.text = initial.province;
      _districtController.text = initial.district;
      _latController.text = initial.latitude;
      _lonController.text = initial.longitude;
    }
    _selectedCountryId ??= ConfigRegistry.dataSources.diyanet.countryId;
    _loadFavorites();
    _loadCountries();
  }

  @override
  void dispose() {
    _isMounted = false;
    _provinceController.dispose();
    _districtController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesStorage.read();
    favorites.sort(
      (a, b) => _normalizeName(a.label).compareTo(_normalizeName(b.label)),
    );
    if (!_isMounted) return;
    final selected = _selectedFavorite != null && favorites.contains(_selectedFavorite)
        ? _selectedFavorite
        : null;
    setState(() {
      _favorites = favorites;
      _selectedFavorite = selected;
    });
  }

  Future<void> _loadCountries() async {
    if (_loadingCountries) return;
    _setListLoadError(null);
    setState(() {
      _loadingCountries = true;
    });
    try {
      final config = ConfigRegistry.dataSources.diyanet;
      final uri = Uri.parse('${config.baseUrl}/api/locations/countries');
      final items = await _fetchItems(uri);
      if (!_isMounted) return;
      setState(() {
        _countries = items;
      });
      _syncCountrySelection();
    } finally {
      if (_isMounted) {
        setState(() {
          _loadingCountries = false;
        });
      }
    }
  }

  Future<void> _loadStates(String countryId) async {
    if (_loadingStates) return;
    _setListLoadError(null);
    setState(() {
      _loadingStates = true;
    });
    try {
      final config = ConfigRegistry.dataSources.diyanet;
      final uri = Uri.parse('${config.baseUrl}/api/locations/states').replace(
        queryParameters: <String, String>{'countryId': countryId},
      );
      final items = await _fetchItems(uri);
      if (!_isMounted) return;
      setState(() {
        _states = items;
      });
      _syncStateSelection();
    } finally {
      if (_isMounted) {
        setState(() {
          _loadingStates = false;
        });
      }
    }
  }

  Future<void> _loadDistricts(String stateId) async {
    if (_loadingDistricts) return;
    _setListLoadError(null);
    setState(() {
      _loadingDistricts = true;
    });
    try {
      final config = ConfigRegistry.dataSources.diyanet;
      final uri =
          Uri.parse('${config.baseUrl}/api/locations/districts').replace(
        queryParameters: <String, String>{'stateId': stateId},
      );
      final items = await _fetchItems(uri);
      if (!_isMounted) return;
      setState(() {
        _districts = items;
      });
      _syncDistrictSelection();
    } finally {
      if (_isMounted) {
        setState(() {
          _loadingDistricts = false;
        });
      }
    }
  }

  Future<List<_DiyanetItem>> _fetchItems(Uri uri) async {
    try {
      final response =
          await http.get(uri, headers: _diyanetHeaders).timeout(_diyanetTimeout);
      if (response.statusCode != 200) {
        _setListLoadError(_listLoadErrorMessage);
        return const <_DiyanetItem>[];
      }
      final items = _parseItems(response.body);
      if (items.isEmpty) {
        _setListLoadError(_listLoadErrorMessage);
        return const <_DiyanetItem>[];
      }
      _setListLoadError(null);
      return items;
    } catch (error) {
      debugPrint('Location list load failed: $error');
      _setListLoadError(_listLoadErrorMessage);
      return const <_DiyanetItem>[];
    }
  }

  void _setListLoadError(String? message) {
    if (!_isMounted) return;
    setState(() {
      _listLoadError = message;
    });
  }

  void _retryLocationLoad() {
    if (_countries.isEmpty) {
      _loadCountries();
      return;
    }
    if (_states.isEmpty && _selectedCountryId != null) {
      _loadStates(_selectedCountryId!);
      return;
    }
    if (_districts.isEmpty && _selectedStateId != null) {
      _loadDistricts(_selectedStateId!);
      return;
    }
    _loadCountries();
  }

  Future<void> _setUseCurrentLocation(bool value) async {
    if (!value) {
      if (!mounted) return;
      setState(() {
        _useCurrentLocation = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _useCurrentLocation = true;
      _locating = true;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception();
      }
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 3), onTimeout: () => <Placemark>[]);
      final placemark = placemarks.isEmpty ? null : placemarks.first;
      final province = (placemark?.administrativeArea ?? '').trim();
      final district = _pickDistrictName(placemark);
      setState(() {
        _selectedFavorite = null;
        _selectedCountryId = ConfigRegistry.dataSources.diyanet.countryId;
        _selectedCountryName = placemark?.country ?? 'Turkiye';
        _selectedStateId = null;
        _selectedDistrictId = null;
        _states = [];
        _districts = [];
        _provinceController.text = province;
        _districtController.text = district;
        _latController.text = position.latitude.toString();
        _lonController.text = position.longitude.toString();
      });
      await _loadStates(_selectedCountryId!);
      if (province.isEmpty || district.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koordinatlar alindi, il / ilce cozulemedi.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _useCurrentLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mevcut konum alinamadi.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  String _pickDistrictName(Placemark? placemark) {
    final candidates = <String>[
      placemark?.subAdministrativeArea ?? '',
      placemark?.locality ?? '',
      placemark?.subLocality ?? '',
      placemark?.street ?? '',
      placemark?.name ?? '',
    ];
    for (final value in candidates) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  List<_DiyanetItem> _parseItems(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return [];
      final data = decoded['data'];
      if (data is! List) return [];
      final items = <_DiyanetItem>[];
      for (final entry in data) {
        if (entry is! Map<String, dynamic>) continue;
        final id = entry['_id']?.toString();
        final name = entry['name'] ?? entry['name_en'];
        if (id == null || name is! String) continue;
        items.add(_DiyanetItem(id: id, name: name));
      }
      items.sort(
        (a, b) => _normalizeName(a.name).compareTo(_normalizeName(b.name)),
      );
      return items;
    } catch (_) {
      return [];
    }
  }

  void _syncCountrySelection() {
    if (_countries.isEmpty) return;
    if (_selectedCountryId != null) {
      final match = _countries.where((item) => item.id == _selectedCountryId);
      if (match.isNotEmpty) {
        if (_selectedCountryName.trim().isEmpty) {
          final item = match.first;
          setState(() {
            _selectedCountryName = item.name;
          });
        }
        if (_states.isEmpty) {
          _loadStates(_selectedCountryId!);
        }
        return;
      }
    }
    final target = _normalizeName(_selectedCountryName);
    if (target.isEmpty) return;
    for (final item in _countries) {
      if (_normalizeName(item.name) == target) {
        setState(() {
          _selectedCountryId = item.id;
          _selectedCountryName = item.name;
          _selectedStateId = null;
          _selectedDistrictId = null;
          _states = [];
          _districts = [];
        });
        _loadStates(item.id);
        break;
      }
    }
  }

  void _syncStateSelection() {
    if (_selectedCountryId == null) return;
    final target = _normalizeName(_provinceController.text);
    if (target.isEmpty) return;
    for (final item in _states) {
      if (_normalizeName(item.name) == target) {
        if (_selectedStateId != item.id) {
          setState(() {
            _selectedStateId = item.id;
            _selectedDistrictId = null;
            _districts = [];
          });
          _loadDistricts(item.id);
        }
        break;
      }
    }
  }

  void _syncDistrictSelection() {
    final target = _normalizeName(_districtController.text);
    if (target.isEmpty) return;
    for (final item in _districts) {
      if (_normalizeName(item.name) == target) {
        setState(() {
          _selectedDistrictId = item.id;
        });
        break;
      }
    }
  }

  Future<void> _addFavorite() async {
    final l10n = AppLocalizations.of(context)!;
    final province = _provinceController.text.trim();
    final district = _districtController.text.trim();
    final latitude = _latController.text.trim();
    final longitude = _lonController.text.trim();
    if (_selectedCountryId == null || province.isEmpty || district.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.locationFillAll)));
      return;
    }
    final added = await _favoritesStorage.add(
      LocationFavorite(
        countryId: _selectedCountryId,
        countryName: _selectedCountryName,
        province: province,
        district: district,
        latitude: latitude,
        longitude: longitude,
      ),
    );
    await _loadFavorites();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? l10n.locationFavoriteAdded : l10n.locationFavoriteExists,
        ),
      ),
    );
  }

  Future<void> _removeFavorite(LocationFavorite favorite) async {
    final isSelected = favorite == _selectedFavorite;
    final removed = await _favoritesStorage.remove(favorite);
    if (!mounted) return;
    if (isSelected) {
      setState(() {
        _selectedFavorite = null;
      });
    }
    await _loadFavorites();
    if (!mounted || !removed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.locationFavoriteRemoved)),
    );
  }

  void _applyFavorite(LocationFavorite favorite) {
    setState(() {
      _selectedFavorite = favorite;
      _selectedCountryId = favorite.countryId ?? _selectedCountryId;
      _selectedCountryName = favorite.countryName ?? _selectedCountryName;
      _selectedStateId = null;
      _selectedDistrictId = null;
      _states = [];
      _districts = [];
      _provinceController.text = favorite.province;
      _districtController.text = favorite.district;
    });
    if (_selectedCountryId != null) {
      _loadStates(_selectedCountryId!);
    }
  }

  Future<void> _applySelectedFavorite() async {
    final favorite = _selectedFavorite;
    if (favorite == null) return;
    _applyFavorite(favorite);
    _latController.text = favorite.latitude;
    _lonController.text = favorite.longitude;
    await _storage.write(
      LocationData(
        countryId: _selectedCountryId,
        countryName: _selectedCountryName,
        province: _provinceController.text.trim(),
        district: _districtController.text.trim(),
        latitude: _latController.text.trim(),
        longitude: _lonController.text.trim(),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final countryId = _selectedCountryId;
    final countryName = _selectedCountryName.trim();
    final province = _provinceController.text.trim();
    final district = _districtController.text.trim();
    final lat = _latController.text.trim();
    final lon = _lonController.text.trim();
    if (countryId == null ||
        countryName.isEmpty ||
        province.isEmpty ||
        district.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.locationFillAll)));
      return;
    }
    await _storage.write(
      LocationData(
        countryId: countryId,
        countryName: countryName,
        province: province,
        district: district,
        latitude: lat,
        longitude: lon,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = widget.uiPaletteController.value;
    final ui = ConfigRegistry.settingsPanelsFor(palette);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locationEditTitle),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.locationSave),
          ),
        ],
      ),
      body: ListView(
        padding: ui.screenPadding,
        children: [
          CheckboxListTile(
            value: _useCurrentLocation,
            onChanged: _locating
                ? null
                : (value) => _setUseCurrentLocation(value ?? false),
            title: const Text('Mevcut Konumu Al'),
            controlAffinity: ListTileControlAffinity.leading,
            secondary: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_outlined),
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: ui.sectionGap),
          _SectionCard(
            style: ui.panel,
            padding: ui.sectionPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.locationSelectLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: ui.sectionTitleSize,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: ui.fieldGap),
                _CompactDropdown<String>(
                  value:
                      _countries.any((item) => item.id == _selectedCountryId)
                          ? _selectedCountryId
                          : null,
                  palette: palette,
                  label: l10n.locationCountryLabel,
                  items: _countries
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(_formatDisplayName(item.name)),
                        ),
                      )
                      .toList(),
                  onChanged: _loadingCountries
                      ? null
                      : (value) async {
                          if (value == null) return;
                          final selected = _countries.firstWhere(
                            (item) => item.id == value,
                          );
                          setState(() {
                            _selectedFavorite = null;
                            _selectedCountryId = value;
                            _selectedCountryName = selected.name;
                            _selectedStateId = null;
                            _selectedDistrictId = null;
                            _states = [];
                            _districts = [];
                            _provinceController.text = '';
                            _districtController.text = '';
                          });
                          await _loadStates(value);
                        },
                ),
                SizedBox(height: ui.fieldGap),
                _CompactDropdown<String>(
                  value:
                      _states.any((item) => item.id == _selectedStateId)
                          ? _selectedStateId
                          : null,
                  palette: palette,
                  label: l10n.locationCityLabel,
                  items: _states
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(_formatDisplayName(item.name)),
                        ),
                      )
                      .toList(),
                  onChanged: _loadingStates
                      ? null
                      : (value) async {
                          if (value == null) return;
                          final selected = _states.firstWhere(
                            (item) => item.id == value,
                          );
                          setState(() {
                            _selectedFavorite = null;
                            _selectedStateId = value;
                            _selectedDistrictId = null;
                            _districts = [];
                            _provinceController.text = selected.name;
                            _districtController.text = '';
                          });
                          await _loadDistricts(value);
                        },
                ),
                SizedBox(height: ui.fieldGap),
                _CompactDropdown<String>(
                  value:
                      _districts.any((item) => item.id == _selectedDistrictId)
                          ? _selectedDistrictId
                          : null,
                  palette: palette,
                  label: l10n.locationDistrictLabel,
                  items: _districts
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(_formatDisplayName(item.name)),
                        ),
                      )
                      .toList(),
                  onChanged: _loadingDistricts
                      ? null
                      : (value) {
                          if (value == null) return;
                          final selected = _districts.firstWhere(
                            (item) => item.id == value,
                          );
                          setState(() {
                            _selectedFavorite = null;
                            _selectedDistrictId = value;
                            _districtController.text = selected.name;
                          });
                        },
                ),
                if (_listLoadError != null) ...[
                  SizedBox(height: ui.fieldGap),
                  Text(
                    _listLoadError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _retryLocationLoad,
                      child: const Text('Tekrar dene'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: ui.sectionGap),
          _SectionCard(
            style: ui.panel,
            padding: ui.sectionPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.locationLatitudeLabel} / ${l10n.locationLongitudeLabel}',
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
                        controller: _latController,
                        decoration: _coordinateDecoration(
                          ui,
                          palette,
                          l10n.locationLatitudeLabel,
                        ),
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
                        controller: _lonController,
                        decoration: _coordinateDecoration(
                          ui,
                          palette,
                          l10n.locationLongitudeLabel,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: ui.sectionGap),
          FilledButton.tonalIcon(
            onPressed: _addFavorite,
            icon: const Icon(Icons.star_border),
            label: Text(l10n.locationAddFavorite),
          ),
          SizedBox(height: ui.sectionGap),
          _SectionCard(
            style: ui.panel,
            padding: ui.sectionPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.locationFavoritesLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                SizedBox(height: ui.fieldGap),
                if (_favorites.isEmpty)
                  Text(l10n.locationNotSet)
                else
                  Row(
                    children: [
                      Expanded(
                        child: _CompactDropdown<LocationFavorite>(
                          value: _favorites.contains(_selectedFavorite)
                              ? _selectedFavorite
                              : null,
                          palette: palette,
                          label: _currentFavoriteClosedLabel(l10n),
                          items: _favorites
                              .map(
                                (favorite) => DropdownMenuItem<LocationFavorite>(
                                  value: favorite,
                                  child: Text(_favoriteLabel(favorite)),
                                ),
                              )
                              .toList(),
                          onChanged: (favorite) {
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
                            : _applySelectedFavorite,
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
                            : () => _removeFavorite(_selectedFavorite!),
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
              ],
            ),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
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

  String _formatDisplayName(String input) {
    final trimmed = input.trim();
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

  String _favoriteLabel(LocationFavorite favorite) {
    return '${_formatDisplayName(favorite.province)} / '
        '${_formatDisplayName(favorite.district)}';
  }

  String _currentFavoriteClosedLabel(AppLocalizations l10n) {
    final province = _formatDisplayName(_provinceController.text);
    final district = _formatDisplayName(_districtController.text);
    if (province.isEmpty) return l10n.locationFavoritesLabel;
    if (district.isEmpty) return province;
    return '$province / $district';
  }

  String _normalizeName(String input) {
    final upper = input.trim().toUpperCase();
    final buffer = StringBuffer();
    for (final rune in upper.runes) {
      switch (rune) {
        case 0x00C7:
          buffer.write('C');
          break;
        case 0x011E:
          buffer.write('G');
          break;
        case 0x0130:
          buffer.write('I');
          break;
        case 0x00D6:
          buffer.write('O');
          break;
        case 0x015E:
          buffer.write('S');
          break;
        case 0x00DC:
          buffer.write('U');
          break;
        case 0x00C2:
          buffer.write('A');
          break;
        case 0x00CE:
          buffer.write('I');
          break;
        case 0x00DB:
          buffer.write('U');
          break;
        default:
          buffer.write(String.fromCharCode(rune));
      }
    }
    return buffer.toString().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}

class _DiyanetItem {
  final String id;
  final String name;

  const _DiyanetItem({required this.id, required this.name});
}

class _CompactDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final UiPaletteConfig palette;

  const _CompactDropdown({
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

class _SectionCard extends StatelessWidget {
  final SurfaceStyle style;
  final EdgeInsets padding;
  final Widget child;

  const _SectionCard({
    required this.style,
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: style.borderRadius,
        boxShadow: style.shadows,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
