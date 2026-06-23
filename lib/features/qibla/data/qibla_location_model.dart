class QiblaLocation {
  final int locationId;
  final String locationCode;
  final String locationName;
  final String stateCode;
  final String stateName;
  final String countryName;
  final double angleDegrees;
  final double? geographicAngleDegrees;
  final double? distanceToKaabaKm;

  const QiblaLocation({
    required this.locationId,
    required this.locationCode,
    required this.locationName,
    required this.stateCode,
    required this.stateName,
    required this.countryName,
    required this.angleDegrees,
    required this.geographicAngleDegrees,
    required this.distanceToKaabaKm,
  });

  factory QiblaLocation.fromJson(Map<String, dynamic> json) {
    final qibla = _mapValue(json['qibla']);
    final locationId = _intValue(json['locationId'] ?? json['id']);
    final angle = _doubleValue(qibla['angleDegrees'] ?? json['qiblaAngle']);
    if (locationId == null || angle == null) {
      throw const FormatException('Invalid qibla location record.');
    }
    return QiblaLocation(
      locationId: locationId,
      locationCode: _stringValue(json['locationCode'] ?? json['code']),
      locationName: _stringValue(json['locationName'] ?? json['name']),
      stateCode: _stringValue(json['stateCode'] ?? json['city']),
      stateName: _stringValue(json['stateName'] ?? json['city']),
      countryName: _stringValue(json['countryName'] ?? json['country']),
      angleDegrees: angle,
      geographicAngleDegrees: _doubleValue(
        qibla['geographicAngleDegrees'] ?? json['geographicQiblaAngle'],
      ),
      distanceToKaabaKm: _doubleValue(
        qibla['distanceToKaabaKm'] ?? json['distanceToKaaba'],
      ),
    );
  }

  static Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static String _stringValue(Object? value) => (value ?? '').toString().trim();

  static int? _intValue(Object? value) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString().trim());
  }

  static double? _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
      (value ?? '').toString().trim().replaceAll(',', '.'),
    );
  }
}
