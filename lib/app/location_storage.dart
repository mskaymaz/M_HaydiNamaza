import 'package:shared_preferences/shared_preferences.dart';

class LocationData {
  final String? countryId;
  final String? countryName;
  final String province;
  final String district;
  final String latitude;
  final String longitude;

  const LocationData({
    this.countryId,
    this.countryName,
    required this.province,
    required this.district,
    required this.latitude,
    required this.longitude,
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
  static const LocationData _defaultLocation = LocationData(
    countryId: '2',
    countryName: 'Turkiye',
    province: 'Amasya',
    district: 'Merzifon',
    latitude: '40.8744',
    longitude: '35.4635',
  );

  Future<LocationData?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final countryId = prefs.getString(_countryIdKey);
    final countryName = prefs.getString(_countryNameKey);
    final province = prefs.getString(_provinceKey);
    final district = prefs.getString(_districtKey);
    final lat = prefs.getString(_latKey);
    final lon = prefs.getString(_lonKey);
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
    );
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
  }
}
