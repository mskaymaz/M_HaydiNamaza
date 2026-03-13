import 'package:shared_preferences/shared_preferences.dart';

class LocationData {
  final String city;
  final String latitude;
  final String longitude;

  const LocationData({
    required this.city,
    required this.latitude,
    required this.longitude,
  });
}

class LocationStorage {
  static const String _cityKey = 'location_city';
  static const String _latKey = 'location_latitude';
  static const String _lonKey = 'location_longitude';

  Future<LocationData?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_cityKey);
    final lat = prefs.getString(_latKey);
    final lon = prefs.getString(_lonKey);
    if (city == null || lat == null || lon == null) {
      return null;
    }
    return LocationData(city: city, latitude: lat, longitude: lon);
  }

  Future<void> write(LocationData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, data.city);
    await prefs.setString(_latKey, data.latitude);
    await prefs.setString(_lonKey, data.longitude);
  }
}
