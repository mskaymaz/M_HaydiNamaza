part of 'location_screen.dart';

extension _LocationScreenStorage on _LocationScreenState {
  Future<void> _persistManualSelection() async {
    final countryId = _selectedCountryId;
    final countryName = _selectedCountryName.trim();
    final province = _provinceController.text.trim();
    final district = _districtController.text.trim();
    if (countryId == null ||
        countryName.isEmpty ||
        province.isEmpty ||
        district.isEmpty) {
      return;
    }
    await _storage.writeUseCurrentLocation(false);
    await _storage.write(_selectedLocationData());
  }

  LocationData _selectedLocationData() {
    return LocationData(
      countryId: _selectedCountryId,
      countryName: _selectedCountryName,
      stateId: _selectedStateId,
      districtId: _selectedDistrictId,
      province: _provinceController.text.trim(),
      district: _districtController.text.trim(),
      latitude: _latController.text.trim(),
      longitude: _lonController.text.trim(),
    );
  }
}
