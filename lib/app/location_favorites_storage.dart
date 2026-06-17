import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocationFavorite {
  final String? countryId;
  final String? countryName;
  final String? stateId;
  final String? districtId;
  final String province;
  final String district;
  final String latitude;
  final String longitude;

  const LocationFavorite({
    this.countryId,
    this.countryName,
    this.stateId,
    this.districtId,
    required this.province,
    required this.district,
    required this.latitude,
    required this.longitude,
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
        'stateId': stateId,
        'districtId': districtId,
        'province': province,
        'district': district,
        'latitude': latitude,
        'longitude': longitude,
      };

  static LocationFavorite? fromJson(Map<String, dynamic> json) {
    final countryId = json['countryId'];
    final countryName = json['countryName'];
    final stateId = json['stateId'];
    final districtId = json['districtId'];
    final province = json['province'];
    final district = json['district'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    if (province is! String || district is! String) {
      return null;
    }
    return LocationFavorite(
      countryId: countryId is String ? countryId : null,
      countryName: countryName is String ? countryName : null,
      stateId: stateId is String ? stateId : null,
      districtId: districtId is String ? districtId : null,
      province: province,
      district: district,
      latitude: latitude is String ? latitude : '',
      longitude: longitude is String ? longitude : '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationFavorite &&
        other.countryId == countryId &&
        other.stateId == stateId &&
        other.districtId == districtId &&
        other.province == province &&
        other.district == district &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(
    countryId,
    stateId,
    districtId,
    province,
    district,
    latitude,
    longitude,
  );
}

class LocationFavoritesStorage {
  static const String _key = 'location_favorites';

  Future<List<LocationFavorite>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? <String>[];
    final result = <LocationFavorite>[];
    final seen = <String>{};
    var changed = false;
    for (final raw in rawList) {
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          final fav = LocationFavorite.fromJson(json);
          if (fav != null) {
            final key = _favoriteKey(fav);
            if (seen.add(key)) {
              result.add(fav);
            } else {
              changed = true;
            }
          } else {
            changed = true;
          }
        }
      } catch (_) {
        changed = true;
      }
    }
    if (changed) {
      final cleaned = result.map((fav) => jsonEncode(fav.toJson())).toList();
      await prefs.setStringList(_key, cleaned);
    }
    return result;
  }

  Future<bool> add(LocationFavorite favorite) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await read();
    final targetKey = _favoriteKey(favorite);
    final exists = current.any((fav) => _favoriteKey(fav) == targetKey);
    if (exists) return false;
    current.add(favorite);
    final rawList = current.map((fav) => jsonEncode(fav.toJson())).toList();
    await prefs.setStringList(_key, rawList);
    return true;
  }

  Future<bool> remove(LocationFavorite favorite) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await read();
    final before = current.length;
    current.removeWhere((fav) => _favoriteKey(fav) == _favoriteKey(favorite));
    final rawList = current.map((fav) => jsonEncode(fav.toJson())).toList();
    await prefs.setStringList(_key, rawList);
    return current.length != before;
  }

  String _favoriteKey(LocationFavorite favorite) {
    final countryId = favorite.countryId ?? '';
    return '${_normalizeName(countryId)}|'
        '${_normalizeName(favorite.province)}|'
        '${_normalizeName(favorite.district)}';
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
