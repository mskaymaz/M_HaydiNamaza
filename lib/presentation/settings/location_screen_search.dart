part of 'location_screen.dart';

class _LocationSearchMatch {
  final DiyanetItem state;
  final DiyanetItem? district;
  final List<DiyanetItem> districts;

  const _LocationSearchMatch({
    required this.state,
    required this.district,
    required this.districts,
  });
}

extension _LocationScreenSearch on _LocationScreenState {
  void _onLocationSearchChanged(String value) {
    _updateLocationState(() {
      _locationSearchStatus = null;
    });
  }

  Future<void> _findLocationFromSearch() async {
    final queryText = _locationSearchController.text.trim();
    final query = normalizeName(queryText);
    if (query.isEmpty) {
      _setLocationSearchStatus('Aranacak il veya ilçe adını yazın.');
      return;
    }
    if (_searchingLocation) return;
    _updateLocationState(() {
      _searchingLocation = true;
      _locationSearchStatus = 'Aranıyor...';
    });
    try {
      await _ensureStateListLoaded();
      if (!_isMounted) return;

      final currentState = _stateById(_selectedStateId);
      if (currentState != null) {
        final districtMatch = await _findDistrictInState(
          currentState,
          queryText,
          query,
        );
        if (districtMatch != null) {
          await _applyDistrictSearchMatch(districtMatch);
          return;
        }
      }

      final stateMatch = await _findStateFromSearch(queryText, query);
      if (stateMatch != null) {
        final districts = await _fetchDistrictsForSearch(stateMatch.id);
        await _applyLocationSearchMatch(
          _LocationSearchMatch(
            state: stateMatch,
            district: null,
            districts: districts,
          ),
        );
        _setLocationSearchStatus(
          'İl bulundu: ${stateMatch.name}. İlçe seçip Ekle ile favorilere ekleyin.',
        );
        return;
      }

      final globalMatch = await _findDistrictGlobally(queryText, query);
      if (globalMatch != null) {
        await _applyDistrictSearchMatch(globalMatch);
        return;
      }
      if ((_locationSearchStatus ?? '').startsWith('Birden fazla')) return;
      _setLocationSearchStatus(
        'Sonuç bulunamadı. İl veya ilçe adını kontrol edip tekrar Bul deyin.',
      );
    } finally {
      if (_isMounted) {
        _updateLocationState(() {
          _searchingLocation = false;
        });
      }
    }
  }

  Future<void> _ensureStateListLoaded() async {
    _selectedCountryId ??= ConfigRegistry.dataSources.diyanet.countryId;
    if (_selectedCountryName.trim().isEmpty) {
      _selectedCountryName = _countryNameFor(_selectedCountryId) ?? 'TÜRKİYE';
    }
    if (_states.isEmpty && _selectedCountryId != null) {
      await _loadStates(_selectedCountryId!);
    }
  }

  Future<_LocationSearchMatch?> _findDistrictInState(
    DiyanetItem state,
    String queryText,
    String query,
  ) async {
    final apiMatch = await _findDistrictWithApi(
      queryText,
      query,
      preferredStateId: state.id,
    );
    if (apiMatch != null) return apiMatch;

    final districts = state.id == _selectedStateId && _districts.isNotEmpty
        ? _districts
        : await _fetchDistrictsForSearch(state.id);
    final match = _bestLocationMatch(districts, query);
    if (match == null) return null;
    return _LocationSearchMatch(
      state: state,
      district: match,
      districts: districts,
    );
  }

  Future<DiyanetItem?> _findStateFromSearch(
    String queryText,
    String query,
  ) async {
    final apiMatches = await _searchStates(queryText);
    final apiMatch = _bestLocationMatch(apiMatches, query);
    if (apiMatch != null) return apiMatch;
    return _bestLocationMatch(_states, query);
  }

  Future<_LocationSearchMatch?> _findDistrictGlobally(
    String queryText,
    String query,
  ) async {
    final apiMatch = await _findDistrictWithApi(queryText, query);
    if (apiMatch != null) return apiMatch;

    final exactMatches = <_LocationSearchMatch>[];
    final partialMatches = <_LocationSearchMatch>[];
    for (final state in _states) {
      final districts = state.id == _selectedStateId && _districts.isNotEmpty
          ? _districts
          : await _fetchDistrictsForSearch(state.id);
      for (final district in districts) {
        final normalized = normalizeName(district.name);
        final match = _LocationSearchMatch(
          state: state,
          district: district,
          districts: districts,
        );
        if (normalized == query) {
          exactMatches.add(match);
        } else if (normalized.contains(query)) {
          partialMatches.add(match);
        }
      }
    }
    if (exactMatches.length == 1) return exactMatches.first;
    if (exactMatches.length > 1) {
      _setLocationSearchStatus(
        'Birden fazla ilçe bulundu. Önce ili seçip tekrar Bul deyin.',
      );
      return null;
    }
    if (partialMatches.length == 1) return partialMatches.first;
    if (partialMatches.length > 1) {
      _setLocationSearchStatus(
        'Birden fazla benzer sonuç bulundu. Önce ili seçip tekrar Bul deyin.',
      );
    }
    return null;
  }

  Future<_LocationSearchMatch?> _findDistrictWithApi(
    String queryText,
    String query, {
    String? preferredStateId,
  }) async {
    final matches = await _searchDistricts(queryText, stateId: preferredStateId);
    if (matches.isEmpty) return null;
    final district = _bestLocationMatch(matches, query);
    if (district == null) {
      _setLocationSearchStatus(
        'Birden fazla benzer sonuç bulundu. Önce ili seçip tekrar Bul deyin.',
      );
      return null;
    }
    final stateId = district.stateId ?? preferredStateId;
    if (stateId == null || stateId.trim().isEmpty) return null;
    final state = _stateById(stateId);
    if (state == null) return null;
    final districts = await _fetchDistrictsForSearch(state.id);
    final normalizedDistrict = normalizeName(district.name);
    final resolvedDistrict = _bestLocationMatch(districts, normalizedDistrict);
    return _LocationSearchMatch(
      state: state,
      district: resolvedDistrict ?? district,
      districts: districts,
    );
  }

  Future<void> _applyDistrictSearchMatch(_LocationSearchMatch match) async {
    await _applyLocationSearchMatch(match);
    _setLocationSearchStatus(
      'İlçe bulundu: ${match.state.name} / ${match.district!.name}. Ekle ile favorilere ekleyin.',
    );
  }

  Future<List<DiyanetItem>> _searchStates(String queryText) async {
    final countryId = _selectedCountryId ?? ConfigRegistry.dataSources.diyanet.countryId;
    final config = ConfigRegistry.dataSources.diyanet;
    final uri = Uri.parse(
      '${config.baseUrl}/api/locations/search/states',
    ).replace(
      queryParameters: <String, String>{
        'countryId': countryId,
        'q': queryText,
      },
    );
    return _itemsClient.fetchItems(uri);
  }

  Future<List<DiyanetItem>> _searchDistricts(
    String queryText, {
    String? stateId,
  }) async {
    final params = <String, String>{'q': queryText};
    if (stateId != null && stateId.trim().isNotEmpty) {
      params['stateId'] = stateId;
    }
    final config = ConfigRegistry.dataSources.diyanet;
    final uri = Uri.parse(
      '${config.baseUrl}/api/locations/search/districts',
    ).replace(queryParameters: params);
    return _itemsClient.fetchItems(uri);
  }

  Future<List<DiyanetItem>> _fetchDistrictsForSearch(String stateId) async {
    final config = ConfigRegistry.dataSources.diyanet;
    final uri = Uri.parse(
      '${config.baseUrl}/api/locations/districts',
    ).replace(queryParameters: <String, String>{'stateId': stateId});
    return _itemsClient.fetchItems(uri);
  }

  Future<void> _applyLocationSearchMatch(_LocationSearchMatch match) async {
    if (!_isMounted) return;
    final countryId =
        _selectedCountryId ?? ConfigRegistry.dataSources.diyanet.countryId;
    final countryName = _selectedCountryName.trim().isNotEmpty
        ? _selectedCountryName
        : (_countryNameFor(countryId) ?? 'TÜRKİYE');
    _updateLocationState(() {
      _useCurrentLocation = false;
      _selectedFavorite = null;
      _selectedCountryId = countryId;
      _selectedCountryName = countryName;
      _selectedStateId = match.state.id;
      _selectedDistrictId = match.district?.id;
      _districts = match.districts;
      _provinceController.text = match.state.name;
      _districtController.text = match.district?.name ?? '';
      _latController.text = match.district?.latitude ?? match.state.latitude ?? '';
      _lonController.text = match.district?.longitude ?? match.state.longitude ?? '';
    });
    await _storage.writeUseCurrentLocation(false);
  }

  DiyanetItem? _bestLocationMatch(List<DiyanetItem> items, String query) {
    final exactMatches = <DiyanetItem>[];
    DiyanetItem? startsWithMatch;
    DiyanetItem? containsMatch;
    for (final item in items) {
      final normalized = normalizeName(item.name);
      if (normalized == query) {
        exactMatches.add(item);
      } else if (startsWithMatch == null && normalized.startsWith(query)) {
        startsWithMatch = item;
      } else if (containsMatch == null && normalized.contains(query)) {
        containsMatch = item;
      }
    }
    if (exactMatches.length == 1) return exactMatches.first;
    if (exactMatches.length > 1) return null;
    return startsWithMatch ?? containsMatch;
  }

  DiyanetItem? _stateById(String? stateId) {
    if (stateId == null) return null;
    for (final state in _states) {
      if (state.id == stateId) return state;
    }
    return null;
  }

  String? _countryNameFor(String? countryId) {
    if (countryId == null) return null;
    for (final country in _countries) {
      if (country.id == countryId) return country.name;
    }
    return null;
  }

  void _setLocationSearchStatus(String message) {
    if (!_isMounted) return;
    _updateLocationState(() {
      _locationSearchStatus = message;
    });
  }
}
