part of 'location_screen.dart';

extension _LocationScreenFavorites on _LocationScreenState {
  Future<void> _loadFavorites() async {
    final favorites = await _favoritesStorage.read();
    favorites.sort(
      (a, b) => normalizeName(a.label).compareTo(normalizeName(b.label)),
    );
    if (!_isMounted) return;
    final selected =
        _selectedFavorite != null && favorites.contains(_selectedFavorite)
        ? _selectedFavorite
        : null;
    setState(() {
      _favorites = favorites;
      _selectedFavorite = selected;
    });
  }

  Future<void> _addFavorite() async {
    final l10n = AppLocalizations.of(context)!;
    final province = _provinceController.text.trim();
    final district = _districtController.text.trim();
    final latitude = _latController.text.trim();
    final longitude = _lonController.text.trim();
    if (_selectedCountryId == null || province.isEmpty || district.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.locationFillAll)));
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
    await this._loadFavorites();
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
    await this._loadFavorites();
    if (!mounted || !removed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.locationFavoriteRemoved),
      ),
    );
  }

  void _applyFavorite(LocationFavorite favorite) {
    setState(() {
      _useCurrentLocation = false;
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
    unawaited(_storage.writeUseCurrentLocation(false));
    if (_selectedCountryId != null) _loadStates(_selectedCountryId!);
  }

  Future<void> _applySelectedFavorite() async {
    final favorite = _selectedFavorite;
    if (favorite == null) return;
    this._applyFavorite(favorite);
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

  void _onFavoriteChanged(LocationFavorite favorite) {
    setState(() {
      _selectedFavorite = favorite;
    });
  }
}
