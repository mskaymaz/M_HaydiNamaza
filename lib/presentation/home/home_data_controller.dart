part of 'home_screen.dart';

extension _HomeDataController on _HomeScreenState {
  Future<_HomeData> _loadData() async {
    final useCurrent = await _locationStorage.readUseCurrentLocation();
    if (useCurrent) {
      await _refreshStoredCurrentLocation();
    }
    final location = await _locationStorage.read();
    var methodCode = await _methodStorage.readCode();
    methodCode ??= CalculationMethodStorage.defaultCode;
    if (location == null) {
      return _HomeData(location: null, methodCode: methodCode);
    }

    final lat = double.tryParse(location.latitude);
    final lon = double.tryParse(location.longitude);
    final canUseDiyanetLocation = location.province.trim().isNotEmpty &&
        location.district.trim().isNotEmpty;
    if (methodCode != 'turkey' &&
        methodCode != 'diyanet' &&
        methodCode != 'diyanet_tabanli' &&
        !canUseDiyanetLocation &&
        (lat == null || lon == null)) {
      return _HomeData(
        location: location,
        methodCode: methodCode,
        error: 'invalid_location',
      );
    }

    final timeZone = location.timeZoneOffset;
    final today = DateTime(_now.year, _now.month, _now.day);
    final cacheSignature = [
      methodCode,
      location.countryId,
      location.stateId,
      location.districtId,
      location.province,
      location.district,
      location.latitude,
      location.longitude,
      today.toIso8601String(),
    ].join('|');
    if (_prayerDayCacheSignature != cacheSignature) {
      _prayerDayCache.clear();
      _prayerDayCacheSignature = cacheSignature;
    }
    final todayTimes = await _prayerService.calculateToday(
      location: location,
      latitude: lat ?? 0,
      longitude: lon ?? 0,
      timeZone: timeZone,
      methodCode: methodCode,
    );
    _prayerDayCache[0] = todayTimes;
    final displayDate = today.add(Duration(days: _prayerDayOffset));
    final cachedDisplayTimes = _prayerDayCache[_prayerDayOffset];
    final displayTimes = cachedDisplayTimes ??
        (_prayerDayOffset == 0
            ? todayTimes
            : await _prayerService.calculateForDate(
                location: location,
                latitude: lat ?? 0,
                longitude: lon ?? 0,
                timeZone: timeZone,
                methodCode: methodCode,
                date: displayDate,
                allowDiyanet: false,
                allowRemote: true,
              ));
    _prayerDayCache[_prayerDayOffset] = displayTimes;
    return _HomeData(
      location: location,
      methodCode: methodCode,
      times: todayTimes,
      displayTimes: displayTimes,
      displayDate: displayDate,
    );
  }

  Future<void> _refreshStoredCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _locationStorage.writeUseCurrentLocation(false);
        return;
      }
      final position = await _readFastCurrentPosition();
      if (position == null) return;
      final stored = await _locationStorage.read();
      if (stored == null) return;
      final storedLat = double.tryParse(stored.latitude) ?? 0.0;
      final storedLon = double.tryParse(stored.longitude) ?? 0.0;
      final dLat = (storedLat - position.latitude).abs();
      final dLon = (storedLon - position.longitude).abs();
      if (dLat <= 0.01 && dLon <= 0.01) return;
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 3), onTimeout: () => <Placemark>[]);
      final placemark = placemarks.isEmpty ? null : placemarks.first;
      final province = (placemark?.administrativeArea ?? '').trim();
      final district = (placemark?.subAdministrativeArea ?? '').trim();
      await _locationStorage.write(
        LocationData(
          countryId: null,
          countryName: placemark?.country ?? '',
          province: province.isEmpty ? stored.province : province,
          district: district.isEmpty ? stored.district : district,
          latitude: position.latitude.toString(),
          longitude: position.longitude.toString(),
        ),
      );
      await _locationStorage.writeUseCurrentLocation(true);
    } catch (_) {}
  }

  Future<Position?> _readFastCurrentPosition() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition().timeout(
        const Duration(milliseconds: 1200),
      );
      if (lastKnown != null) return lastKnown;
    } catch (_) {}
    try {
      return await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 4),
      );
    } catch (_) {
      return null;
    }
  }

}
