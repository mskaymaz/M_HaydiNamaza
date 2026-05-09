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
import 'location_name_formatters.dart';
import 'location_selection_item_builders.dart';
import 'widgets/location_coordinates_section.dart';
import 'widgets/location_current_location_tile.dart';
import 'widgets/location_favorites_section.dart';
import 'widgets/location_add_favorite_button.dart';
import 'widgets/location_selection_composer.dart';

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
    final countryValue = _countries.any((item) => item.id == _selectedCountryId)
        ? _selectedCountryId
        : null;
    final stateValue = _states.any((item) => item.id == _selectedStateId)
        ? _selectedStateId
        : null;
    final districtValue = _districts.any((item) => item.id == _selectedDistrictId)
        ? _selectedDistrictId
        : null;
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
          LocationCurrentLocationTile(
            useCurrentLocation: _useCurrentLocation,
            locating: _locating,
            onChanged: (value) => _setUseCurrentLocation(value ?? false),
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
            countryItems: buildStringDropdownItems<_DiyanetItem>(
              items: _countries,
              valueOf: (item) => item.id,
              labelOf: (item) => formatLocationDisplayName(item.name),
            ),
            stateItems: buildStringDropdownItems<_DiyanetItem>(
              items: _states,
              valueOf: (item) => item.id,
              labelOf: (item) => formatLocationDisplayName(item.name),
            ),
            districtItems: buildStringDropdownItems<_DiyanetItem>(
              items: _districts,
              valueOf: (item) => item.id,
              labelOf: (item) => formatLocationDisplayName(item.name),
            ),
            onCountryChanged: _loadingCountries
                ? null
                : (value) async {
                    if (value == null) return;
                    final selected = _countries.firstWhere((item) => item.id == value);
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
            onStateChanged: _loadingStates
                ? null
                : (value) async {
                    if (value == null) return;
                    final selected = _states.firstWhere((item) => item.id == value);
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
            onDistrictChanged: _loadingDistricts
                ? null
                : (value) {
                    if (value == null) return;
                    final selected = _districts.firstWhere((item) => item.id == value);
                    setState(() {
                      _selectedFavorite = null;
                      _selectedDistrictId = value;
                      _districtController.text = selected.name;
                    });
                  },
            listLoadError: _listLoadError,
            onRetry: _retryLocationLoad,
          ),
          SizedBox(height: ui.sectionGap),
          LocationCoordinatesSection(
            ui: ui,
            palette: palette,
            latitudeLabel: l10n.locationLatitudeLabel,
            longitudeLabel: l10n.locationLongitudeLabel,
            latitudeController: _latController,
            longitudeController: _lonController,
            onSave: _save,
          ),
          SizedBox(height: ui.sectionGap),
          LocationAddFavoriteButton(
            onPressed: _addFavorite,
            label: l10n.locationAddFavorite,
          ),
          SizedBox(height: ui.sectionGap),
          LocationFavoritesSection(
            ui: ui,
            palette: palette,
            title: l10n.locationFavoritesLabel,
            emptyText: l10n.locationNotSet,
            closedLabel: _currentFavoriteClosedLabel(l10n),
            applyLabel: l10n.locationFavoriteApplyLabel,
            removeTooltip: l10n.locationFavoriteRemoveLabel,
            favorites: _favorites,
            selectedFavorite: _selectedFavorite,
            labelBuilder: _favoriteLabel,
            onChanged: (favorite) {
              if (favorite == null) return;
              setState(() {
                _selectedFavorite = favorite;
              });
            },
            onApply: _selectedFavorite == null ? null : _applySelectedFavorite,
            onRemove: _selectedFavorite == null
                ? null
                : () => _removeFavorite(_selectedFavorite!),
          ),
        ],
      ),
    );
  }

  String _favoriteLabel(LocationFavorite favorite) {
    return '${formatLocationDisplayName(favorite.province)} / '
        '${formatLocationDisplayName(favorite.district)}';
  }

  String _currentFavoriteClosedLabel(AppLocalizations l10n) {
    final province = formatLocationDisplayName(_provinceController.text);
    final district = formatLocationDisplayName(_districtController.text);
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
