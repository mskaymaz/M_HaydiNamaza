import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocationFavorite {
  final String? countryId;
  final String? countryName;
  final String province;
  final String district;

  const LocationFavorite({
    this.countryId,
    this.countryName,
    required this.province,
    required this.district,
  });

  String get label {
    if (countryName == null || countryName!.trim().isEmpty) {
      return '$province / $district';
    }
    return '${countryName!} / $province / $district';
  }

  Map<String, dynamic> toJson() => {
        'countryId': countryId,
        'countryName': countryName,
        'province': province,
        'district': district,
      };

  static LocationFavorite? fromJson(Map<String, dynamic> json) {
    final countryId = json['countryId'];
    final countryName = json['countryName'];
    final province = json['province'];
    final district = json['district'];
    if (province is! String || district is! String) {
      return null;
    }
    return LocationFavorite(
      countryId: countryId is String ? countryId : null,
      countryName: countryName is String ? countryName : null,
      province: province,
      district: district,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationFavorite &&
        other.countryId == countryId &&
        other.province == province &&
        other.district == district;
  }

  @override
  int get hashCode => Object.hash(countryId, province, district);
}

class LocationFavoritesStorage {
  static const String _key = 'location_favorites';

  Future<List<LocationFavorite>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? <String>[];
    final result = <LocationFavorite>[];
    for (final raw in rawList) {
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          final fav = LocationFavorite.fromJson(json);
          if (fav != null) result.add(fav);
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> add(LocationFavorite favorite) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await read();
    final exists = current.any((fav) =>
        fav.province == favorite.province &&
        fav.district == favorite.district &&
        (fav.countryId ?? '') == (favorite.countryId ?? ''));
    if (exists) return;
    current.add(favorite);
    final rawList = current.map((fav) => jsonEncode(fav.toJson())).toList();
    await prefs.setStringList(_key, rawList);
  }
}
