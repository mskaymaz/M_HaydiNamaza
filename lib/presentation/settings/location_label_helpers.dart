import '../../app/location_favorites_storage.dart';
import 'location_name_formatters.dart';

String favoriteLabel(LocationFavorite favorite) {
  return '${formatLocationDisplayName(favorite.province)} / '
      '${formatLocationDisplayName(favorite.district)}';
}

String currentFavoriteClosedLabel({
  required String favoritesLabel,
  required String provinceText,
  required String districtText,
}) {
  final province = formatLocationDisplayName(provinceText);
  final district = formatLocationDisplayName(districtText);
  if (province.isEmpty) return favoritesLabel;
  if (district.isEmpty) return province;
  return '$province / $district';
}
