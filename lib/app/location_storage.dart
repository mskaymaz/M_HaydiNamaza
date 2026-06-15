import 'package:shared_preferences/shared_preferences.dart';

class LocationData {
  final String? countryId;
  final String? countryName;
  final String province;
  final String district;
  final String latitude;
  final String longitude;
  final String timeZoneName;
  final String timeZoneOffset;

  const LocationData({
    this.countryId,
    this.countryName,
    required this.province,
    required this.district,
    required this.latitude,
    required this.longitude,
    this.timeZoneName = '',
    this.timeZoneOffset = '',
  });

  String get displayName {
    if (district.isEmpty) {
      return province;
    }
    return '$province / $district';
  }
}

class LocationStorage {
  static const String _cityKey = 'location_city';
  static const String _countryIdKey = 'location_country_id';
  static const String _countryNameKey = 'location_country_name';
  static const String _provinceKey = 'location_province';
  static const String _districtKey = 'location_district';
  static const String _latKey = 'location_latitude';
  static const String _lonKey = 'location_longitude';
  static const String _timeZoneNameKey = 'location_time_zone_name';
  static const String _timeZoneOffsetKey = 'location_time_zone_offset';
  static const LocationData _defaultLocation = LocationData(
    countryId: '2',
    countryName: 'Turkiye',
    province: 'Amasya',
    district: 'Merzifon',
    latitude: '40.8744',
    longitude: '35.4635',
    timeZoneName: 'Europe/Istanbul',
    timeZoneOffset: '+03:00',
  );

  Future<LocationData?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final countryId = prefs.getString(_countryIdKey);
    final countryName = prefs.getString(_countryNameKey);
    final province = prefs.getString(_provinceKey);
    final district = prefs.getString(_districtKey);
    final lat = prefs.getString(_latKey);
    final lon = prefs.getString(_lonKey);
    final storedTimeZoneName = prefs.getString(_timeZoneNameKey);
    final storedTimeZoneOffset = prefs.getString(_timeZoneOffsetKey);
    final timeZoneName = _resolveTimeZoneName(storedTimeZoneName);
    final timeZoneOffset = _resolveTimeZoneOffset(storedTimeZoneOffset);
    if (province == null) {
      final legacyCity = prefs.getString(_cityKey);
      if (legacyCity == null || lat == null || lon == null) {
        return _defaultLocation;
      }
      return LocationData(
        countryId: countryId,
        countryName: countryName,
        province: legacyCity,
        district: '',
        latitude: lat,
        longitude: lon,
        timeZoneName: timeZoneName,
        timeZoneOffset: timeZoneOffset,
      );
    }
    if (lat == null || lon == null) {
      return _defaultLocation;
    }
    return LocationData(
      countryId: countryId,
      countryName: countryName,
      province: province,
      district: district ?? '',
      latitude: lat,
      longitude: lon,
      timeZoneName: timeZoneName,
      timeZoneOffset: timeZoneOffset,
    );
  }

  static const String _useCurrentLocationKey = 'location_use_current';

  Future<bool> readUseCurrentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useCurrentLocationKey) ?? true;
  }

  Future<void> writeUseCurrentLocation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useCurrentLocationKey, value);
  }

  Future<void> write(LocationData data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data.countryId != null) {
      await prefs.setString(_countryIdKey, data.countryId!);
    }
    if (data.countryName != null) {
      await prefs.setString(_countryNameKey, data.countryName!);
    }
    await prefs.setString(_provinceKey, data.province);
    await prefs.setString(_districtKey, data.district);
    await prefs.setString(_latKey, data.latitude);
    await prefs.setString(_lonKey, data.longitude);
    await prefs.setString(_cityKey, data.province);
    await prefs.setString(_timeZoneNameKey, _resolveTimeZoneName(data.timeZoneName));
    await prefs.setString(
      _timeZoneOffsetKey,
      _resolveTimeZoneOffset(data.timeZoneOffset),
    );
  }

  String _resolveTimeZoneName(String? input) {
    final value = (input ?? '').trim();
    if (value.isNotEmpty) return value;
    return DateTime.now().timeZoneName;
  }

  String _resolveTimeZoneOffset(String? input) {
    final value = (input ?? '').trim();
    final re = RegExp(r'^([+-])(\d{2}):(\d{2})$');
    if (re.hasMatch(value)) return value;
    return _offsetToTz(DateTime.now().timeZoneOffset);
  }

  String _offsetToTz(Duration offset) {
    final totalMinutes = offset.inMinutes;
    final sign = totalMinutes < 0 ? '-' : '+';
    final total = totalMinutes.abs();
    final hours = (total ~/ 60).toString().padLeft(2, '0');
    final mins = (total % 60).toString().padLeft(2, '0');
    return '$sign$hours:$mins';
  }
}
