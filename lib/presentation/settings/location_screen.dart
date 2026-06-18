import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/location_favorites_storage.dart';
import '../../app/location_storage.dart';
import '../../app/ui_palette_controller.dart';
import '../../core/config/config_registry.dart';
import 'location_current_location_resolver.dart';
import 'location_data_parsers.dart';
import 'location_items_client.dart';
import 'location_models.dart';
import 'widgets/location_screen_content.dart';

part 'location_screen_favorites.dart';
part 'location_screen_search.dart';
part 'location_screen_storage.dart';

class LocationScreen extends StatefulWidget {
  final LocationData? initial;
  final UiPaletteController uiPaletteController;
  final bool showHelpBalloons;

  const LocationScreen({
    super.key,
    this.initial,
    required this.uiPaletteController,
    this.showHelpBalloons = false,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  static const String _listLoadErrorMessage =
      'Konum listesi yüklenemedi. Lütfen tekrar deneyin.';

  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _locationSearchController = TextEditingController();
  final _storage = LocationStorage();
  final _favoritesStorage = LocationFavoritesStorage();
  final _itemsClient = DiyanetLocationItemsClient();
  final _currentLocationResolver = CurrentLocationResolver();

  bool _loadingCountries = false;
  bool _loadingStates = false;
  bool _loadingDistricts = false;
  List<DiyanetItem> _countries = [];
  List<DiyanetItem> _states = [];
  List<DiyanetItem> _districts = [];
  String? _selectedCountryId;
  String _selectedCountryName = '';
  String? _selectedStateId;
  String? _selectedDistrictId;
  List<LocationFavorite> _favorites = [];
  LocationFavorite? _selectedFavorite;
  String? _listLoadError;
  bool _useCurrentLocation = false;
  bool _locating = false;
  bool _searchingLocation = false;
  String? _locationSearchStatus;
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _selectedCountryId = initial.countryId;
      _selectedCountryName = initial.countryName ?? '';
      _selectedStateId = initial.stateId;
      _selectedDistrictId = initial.districtId;
      _provinceController.text = initial.province;
      _districtController.text = initial.district;
      _latController.text = initial.latitude;
      _lonController.text = initial.longitude;
    }
    _selectedCountryId ??= ConfigRegistry.dataSources.diyanet.countryId;
    unawaited(_loadUseCurrentLocation());
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
    _locationSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadUseCurrentLocation() async {
    final useCurrentLocation = await _storage.readUseCurrentLocation();
    if (!_isMounted) return;
    setState(() {
      _useCurrentLocation = useCurrentLocation;
    });
    if (useCurrentLocation) {
      unawaited(_setUseCurrentLocation(true));
    }
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
      final uri = Uri.parse(
        '${config.baseUrl}/api/locations/states',
      ).replace(queryParameters: <String, String>{'countryId': countryId});
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
      final uri = Uri.parse(
        '${config.baseUrl}/api/locations/districts',
      ).replace(queryParameters: <String, String>{'stateId': stateId});
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

  Future<List<DiyanetItem>> _fetchItems(Uri uri) async {
    final items = await _itemsClient.fetchItems(uri);
    _setListLoadError(items.isEmpty ? _listLoadErrorMessage : null);
    return items;
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
      setState(() => _useCurrentLocation = false);
      try {
        await _storage.writeUseCurrentLocation(false);
      } catch (_) {}
      return;
    }
    if (!mounted) return;
    setState(() {
      _useCurrentLocation = true;
      _locating = true;
    });
    try {
      final result = await _currentLocationResolver.resolve();
      if (!mounted) return;
      if (result.status != CurrentLocationStatus.success) {
        await _handleCurrentLocationFailure(result.status);
        return;
      }
      _applyCurrentLocationResult(result);
      await _storage.write(
        LocationData(
          countryId: null,
          countryName: _selectedCountryName,
          province: result.province,
          district: result.district,
          latitude: result.latitude,
          longitude: result.longitude,
        ),
      );
      await _storage.writeUseCurrentLocation(true);
      await _loadStates(_selectedCountryId!);
      if (!result.hasResolvedNames && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Koordinatlar alindi, il / ilce cozulemedi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _handleCurrentLocationFailure(
    CurrentLocationStatus status,
  ) async {
    if (!mounted) return;
    setState(() => _useCurrentLocation = false);
    await _storage.writeUseCurrentLocation(false);
    if (!mounted) return;
    final message = switch (status) {
      CurrentLocationStatus.serviceDisabled =>
        'Konum servisi kapalı. Elle konum seçimi ile devam edebilirsiniz.',
      CurrentLocationStatus.permissionDenied =>
        'Konum izni verilmedi. Elle konum seçimi ile devam edebilirsiniz.',
      _ => 'Mevcut konum alinamadi.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _applyCurrentLocationResult(CurrentLocationResult result) {
    setState(() {
      _selectedFavorite = null;
      _selectedCountryId = ConfigRegistry.dataSources.diyanet.countryId;
      _selectedCountryName = result.countryName.isEmpty
          ? 'Turkiye'
          : result.countryName;
      _selectedStateId = null;
      _selectedDistrictId = null;
      _states = [];
      _districts = [];
      _provinceController.text = result.province;
      _districtController.text = result.district;
      _latController.text = result.latitude;
      _lonController.text = result.longitude;
    });
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
        if (_states.isEmpty) _loadStates(_selectedCountryId!);
        return;
      }
    }
    final target = normalizeName(_selectedCountryName);
    if (target.isEmpty) return;
    for (final item in _countries) {
      if (normalizeName(item.name) == target) {
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
    final target = normalizeName(_provinceController.text);
    if (target.isEmpty) return;
    for (final item in _states) {
      if (normalizeName(item.name) == target) {
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
    final target = normalizeName(_districtController.text);
    if (target.isEmpty) return;
    for (final item in _districts) {
      if (normalizeName(item.name) == target) {
        setState(() {
          _selectedDistrictId = item.id;
        });
        break;
      }
    }
  }

  Future<void> _onCountryChanged(String value) async {
    final selected = _countries.firstWhere((item) => item.id == value);
    setState(() {
      _useCurrentLocation = false;
      _selectedFavorite = null;
      _selectedCountryId = value;
      _selectedCountryName = selected.name;
      _selectedStateId = null;
      _selectedDistrictId = null;
      _states = [];
      _districts = [];
      _provinceController.text = '';
      _districtController.text = '';
      _latController.text = '';
      _lonController.text = '';
    });
    await _storage.writeUseCurrentLocation(false);
    await _loadStates(value);
  }

  Future<void> _onStateChanged(String value) async {
    final selected = _states.firstWhere((item) => item.id == value);
    setState(() {
      _useCurrentLocation = false;
      _selectedFavorite = null;
      _selectedStateId = value;
      _selectedDistrictId = null;
      _districts = [];
      _provinceController.text = selected.name;
      _districtController.text = '';
      _latController.text = selected.latitude ?? '';
      _lonController.text = selected.longitude ?? '';
    });
    await _storage.writeUseCurrentLocation(false);
    await _loadDistricts(value);
  }

  void _onDistrictChanged(String value) {
    final selected = _districts.firstWhere((item) => item.id == value);
    setState(() {
      _useCurrentLocation = false;
      _selectedFavorite = null;
      _selectedDistrictId = value;
      _districtController.text = selected.name;
      _latController.text = selected.latitude ?? '';
      _lonController.text = selected.longitude ?? '';
    });
    unawaited(_persistManualSelection());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = widget.uiPaletteController.value;
    final ui = ConfigRegistry.settingsPanelsFor(palette);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.locationEditTitle)),
      body: LocationScreenContent(
        palette: palette,
        ui: ui,
        showHelpBalloons: widget.showHelpBalloons,
        useCurrentLocation: _useCurrentLocation,
        locating: _locating,
        loadingCountries: _loadingCountries,
        loadingStates: _loadingStates,
        loadingDistricts: _loadingDistricts,
        searchingLocation: _searchingLocation,
        countries: _countries,
        states: _states,
        districts: _districts,
        selectedCountryId: _selectedCountryId,
        selectedStateId: _selectedStateId,
        selectedDistrictId: _selectedDistrictId,
        favorites: _favorites,
        selectedFavorite: _selectedFavorite,
        listLoadError: _listLoadError,
        locationSearchStatus: _locationSearchStatus,
        provinceController: _provinceController,
        districtController: _districtController,
        latController: _latController,
        lonController: _lonController,
        locationSearchController: _locationSearchController,
        onLocationSearchChanged: _onLocationSearchChanged,
        onFindLocation: () => unawaited(_findLocationFromSearch()),
        onUseCurrentLocationChanged: _setUseCurrentLocation,
        onCountryChanged: (value) => unawaited(_onCountryChanged(value)),
        onStateChanged: (value) => unawaited(_onStateChanged(value)),
        onDistrictChanged: _onDistrictChanged,
        onRetry: _retryLocationLoad,
        onSaveCoordinates: () => unawaited(_persistManualSelection()),
        onAddFavorite: _addFavorite,
        onFavoriteChanged: _onFavoriteChanged,
        onApplyFavorite: _selectedFavorite == null
            ? null
            : _applySelectedFavorite,
        onRemoveFavorite: _selectedFavorite == null
            ? null
            : () => _removeFavorite(_selectedFavorite!),
      ),
    );
  }

  void _updateFavoriteState(VoidCallback update) {
    _updateLocationState(update);
  }

  void _updateLocationState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }
}
