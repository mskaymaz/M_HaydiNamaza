import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/runtime_monitor.dart';
import 'location_data_parsers.dart';

class CurrentLocationResult {
  final CurrentLocationStatus status;
  final String countryName;
  final String province;
  final String district;
  final String latitude;
  final String longitude;

  const CurrentLocationResult._({
    required this.status,
    this.countryName = 'Turkiye',
    this.province = '',
    this.district = '',
    this.latitude = '',
    this.longitude = '',
  });

  const CurrentLocationResult.serviceDisabled()
    : this._(status: CurrentLocationStatus.serviceDisabled);

  const CurrentLocationResult.permissionDenied()
    : this._(status: CurrentLocationStatus.permissionDenied);

  const CurrentLocationResult.failure()
    : this._(status: CurrentLocationStatus.failure);

  const CurrentLocationResult.success({
    required String countryName,
    required String province,
    required String district,
    required String latitude,
    required String longitude,
  }) : this._(
         status: CurrentLocationStatus.success,
         countryName: countryName,
         province: province,
         district: district,
         latitude: latitude,
         longitude: longitude,
       );

  bool get hasResolvedNames =>
      province.trim().isNotEmpty && district.trim().isNotEmpty;
}

enum CurrentLocationStatus {
  success,
  serviceDisabled,
  permissionDenied,
  failure,
}

class CurrentLocationResolver {
  Future<CurrentLocationResult> resolve() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return const CurrentLocationResult.serviceDisabled();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const CurrentLocationResult.permissionDenied();
      }
      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 3), onTimeout: () => <Placemark>[]);
      final placemark = placemarks.isEmpty ? null : placemarks.first;
      return CurrentLocationResult.success(
        countryName: (placemark?.country ?? 'Turkiye').trim(),
        province: (placemark?.administrativeArea ?? '').trim(),
        district: pickDistrictName(placemark),
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
      );
    } catch (_) {
      RuntimeMonitor.instance.reportNonFatalCode(
        source: 'location_current_position',
        code: 'current_location_failed',
      );
      return const CurrentLocationResult.failure();
    }
  }
}
