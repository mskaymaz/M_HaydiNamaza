import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/location_favorites_storage.dart';
import '../../app/location_storage.dart';
import '../../core/config/config_registry.dart';

class LocationScreen extends StatefulWidget {
  final LocationData? initial;

  const LocationScreen({super.key, this.initial});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _storage = LocationStorage();
  final _favoritesStorage = LocationFavoritesStorage();

  bool _useList = true;
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
    if (!_isMounted) return;
    setState(() {
      _favorites = favorites;
    });
  }

  Future<void> _loadCountries() async {
    if (_loadingCountries) return;
    setState(() {
      _loadingCountries = true;
    });
    try {
      final config = ConfigRegistry.dataSources.diyanet;
      final uri = Uri.parse('${config.baseUrl}/api/locations/countries');
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return;
      }
      final payload = response.body;
      final items = _parseItems(payload);
      if (!_isMounted) return;
      setState(() {
        _countries = items;
      });
      _syncCountrySelection();
    } catch (_) {
      if (!_isMounted) return;
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
    setState(() {
      _loadingStates = true;
    });
    try {
      final config = ConfigRegistry.dataSources.diyanet;
      final uri = Uri.parse('${config.baseUrl}/api/locations/states').replace(
        queryParameters: <String, String>{'countryId': countryId},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return;
      }
      final payload = response.body;
      final items = _parseItems(payload);
      if (!_isMounted) return;
      setState(() {
        _states = items;
      });
      _syncStateSelection();
    } catch (_) {
      if (!_isMounted) return;
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
    setState(() {
      _loadingDistricts = true;
    });
    try {
      final config = ConfigRegistry.dataSources.diyanet;
      final uri = Uri.parse('${config.baseUrl}/api/locations/districts').replace(
        queryParameters: <String, String>{'stateId': stateId},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return;
      }
      final payload = response.body;
      final items = _parseItems(payload);
      if (!_isMounted) return;
      setState(() {
        _districts = items;
      });
      _syncDistrictSelection();
    } catch (_) {
      if (!_isMounted) return;
    } finally {
      if (_isMounted) {
        setState(() {
          _loadingDistricts = false;
        });
      }
    }
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
    if (_selectedCountryId == null || province.isEmpty || district.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.locationFillAll)));
      return;
    }
    await _favoritesStorage.add(
      LocationFavorite(
        countryId: _selectedCountryId,
        countryName: _selectedCountryName,
        province: province,
        district: district,
      ),
    );
    await _loadFavorites();
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
        district.isEmpty ||
        lat.isEmpty ||
        lon.isEmpty) {
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
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _countries.any((item) => item.id == _selectedCountryId)
                ? _selectedCountryId
                : null,
            decoration: InputDecoration(labelText: l10n.locationCountryLabel),
            items: _countries
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                )
                .toList(),
            onChanged: _loadingCountries
                ? null
                : (value) {
                    if (value == null) return;
                    final selected = _countries.firstWhere(
                      (item) => item.id == value,
                    );
                    setState(() {
                      _selectedCountryId = value;
                      _selectedCountryName = selected.name;
                      _selectedStateId = null;
                      _selectedDistrictId = null;
                      _states = [];
                      _districts = [];
                      _provinceController.text = '';
                      _districtController.text = '';
                    });
                    _loadStates(value);
                  },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _useList,
            onChanged: (value) {
              setState(() => _useList = value);
              if (value && _countries.isEmpty) {
                _loadCountries();
              }
              if (value && _states.isEmpty && _selectedCountryId != null) {
                _loadStates(_selectedCountryId!);
              }
            },
            title: Text(l10n.locationUseList),
            contentPadding: EdgeInsets.zero,
          ),
          if (_favorites.isNotEmpty) ...[
            DropdownButtonFormField<LocationFavorite>(
              value: _selectedFavorite,
              decoration: InputDecoration(labelText: l10n.locationFavoritesLabel),
              items: _favorites
                  .map(
                    (fav) => DropdownMenuItem<LocationFavorite>(
                      value: fav,
                      child: Text(fav.label),
                    ),
                  )
                  .toList(),
              onChanged: (fav) {
                if (fav == null) return;
                setState(() {
                  _selectedFavorite = fav;
                  _selectedCountryId = fav.countryId ?? _selectedCountryId;
                  _selectedCountryName =
                      fav.countryName ?? _selectedCountryName;
                  _provinceController.text = fav.province;
                  _districtController.text = fav.district;
                });
                if (_useList) {
                  _syncCountrySelection();
                  _syncStateSelection();
                }
              },
            ),
            const SizedBox(height: 12),
          ],
          if (_useList) ...[
            DropdownButtonFormField<String>(
              value: _states.any((item) => item.id == _selectedStateId)
                  ? _selectedStateId
                  : null,
              decoration: InputDecoration(labelText: l10n.locationCityLabel),
              items: _states
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: _loadingStates
                  ? null
                  : (value) {
                      if (value == null) return;
                      final selected = _states.firstWhere(
                        (item) => item.id == value,
                      );
                      setState(() {
                        _selectedStateId = value;
                        _selectedDistrictId = null;
                        _districts = [];
                        _provinceController.text = selected.name;
                        _districtController.text = '';
                      });
                      _loadDistricts(value);
                    },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _districts.any((item) => item.id == _selectedDistrictId)
                  ? _selectedDistrictId
                  : null,
              decoration: InputDecoration(labelText: l10n.locationDistrictLabel),
              items: _districts
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(item.name),
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
                        _selectedDistrictId = value;
                        _districtController.text = selected.name;
                      });
                    },
            ),
            const SizedBox(height: 12),
          ] else ...[
            TextField(
              controller: _provinceController,
              decoration: InputDecoration(labelText: l10n.locationCityLabel),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _districtController,
              decoration: InputDecoration(labelText: l10n.locationDistrictLabel),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _latController,
            decoration: InputDecoration(labelText: l10n.locationLatitudeLabel),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lonController,
            decoration: InputDecoration(labelText: l10n.locationLongitudeLabel),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addFavorite,
              icon: const Icon(Icons.star_border),
              label: Text(l10n.locationAddFavorite),
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeName(String input) {
    final upper = input.trim().toUpperCase();
    final buffer = StringBuffer();
    for (final rune in upper.runes) {
      switch (rune) {
        case 0x00C7: // Ç
          buffer.write('C');
          break;
        case 0x011E: // Ğ
          buffer.write('G');
          break;
        case 0x0130: // İ
          buffer.write('I');
          break;
        case 0x00D6: // Ö
          buffer.write('O');
          break;
        case 0x015E: // Ş
          buffer.write('S');
          break;
        case 0x00DC: // Ü
          buffer.write('U');
          break;
        case 0x00C2: // Â
          buffer.write('A');
          break;
        case 0x00CE: // Î
          buffer.write('I');
          break;
        case 0x00DB: // Û
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
