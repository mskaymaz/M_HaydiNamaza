import '../../app/location_favorites_storage.dart';
import '../../app/location_storage.dart';

String normalizeFavoriteSpacing(String input) {
  return input.trim().replaceAll(RegExp(r'\s+'), ' ');
}

LocationFavorite? matchFavorite(
  LocationData? data,
  List<LocationFavorite> favorites,
) {
  if (data == null) return null;
  for (final favorite in favorites) {
    final sameCountry = (favorite.countryId ?? '') == (data.countryId ?? '');
    final sameProvince =
        normalizeFavoriteSpacing(favorite.province).toUpperCase() ==
        normalizeFavoriteSpacing(data.province).toUpperCase();
    final sameDistrict =
        normalizeFavoriteSpacing(favorite.district).toUpperCase() ==
        normalizeFavoriteSpacing(data.district).toUpperCase();
    if (sameCountry && sameProvince && sameDistrict) {
      return favorite;
    }
  }
  return null;
}
