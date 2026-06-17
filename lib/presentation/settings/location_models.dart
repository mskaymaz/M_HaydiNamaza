class DiyanetItem {
  final String id;
  final String name;
  final String? countryId;
  final String? stateId;
  final String? latitude;
  final String? longitude;

  const DiyanetItem({
    required this.id,
    required this.name,
    this.countryId,
    this.stateId,
    this.latitude,
    this.longitude,
  });
}
