class DiyanetIds {
  final String stateId;
  final String districtId;

  const DiyanetIds({required this.stateId, required this.districtId});
}

DateTime? parsePrayerClockTime({
  required Object? raw,
  required DateTime baseDate,
}) {
  if (raw is! String) return null;
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw);
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
}

DateTime applyPrayerMinuteOffset(DateTime value, int delta) {
  if (delta == 0) return value;
  return value.add(Duration(minutes: delta));
}

String? findDiyanetEntryIdByNormalizedName(
  List<dynamic> entries,
  String normalizedName,
) {
  for (final entry in entries) {
    if (entry is! Map<String, dynamic>) continue;
    final name = entry['name'] ?? entry['name_en'];
    if (name is! String) continue;
    if (normalizePrayerLocationName(name) != normalizedName) continue;
    final id = entry['_id'];
    if (id is String) return id;
    if (id is int) return id.toString();
  }
  return null;
}

String normalizePrayerLocationName(String input) {
  final upper = input.trim().toUpperCase();
  final buffer = StringBuffer();
  for (final rune in upper.runes) {
    switch (rune) {
      case 0x00C7: // C with cedilla
        buffer.write('C');
        break;
      case 0x011E: // G with breve
        buffer.write('G');
        break;
      case 0x0130: // I with dot
        buffer.write('I');
        break;
      case 0x00D6: // O with diaeresis
        buffer.write('O');
        break;
      case 0x015E: // S with cedilla
        buffer.write('S');
        break;
      case 0x00DC: // U with diaeresis
        buffer.write('U');
        break;
      case 0x00C2: // A with circumflex
        buffer.write('A');
        break;
      case 0x00CE: // I with circumflex
        buffer.write('I');
        break;
      case 0x00DB: // U with circumflex
        buffer.write('U');
        break;
      default:
        buffer.write(String.fromCharCode(rune));
    }
  }
  return buffer.toString().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

String formatPrayerTimeHourMinute(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
