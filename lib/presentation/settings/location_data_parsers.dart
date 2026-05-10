import 'dart:convert';

import 'package:geocoding/geocoding.dart';

import 'location_models.dart';

String normalizeName(String input) {
  final upper = input.trim().toUpperCase();
  final buffer = StringBuffer();
  for (final rune in upper.runes) {
    switch (rune) {
      case 0x00C7:
        buffer.write('C');
        break;
      case 0x011E:
        buffer.write('G');
        break;
      case 0x0130:
        buffer.write('I');
        break;
      case 0x00D6:
        buffer.write('O');
        break;
      case 0x015E:
        buffer.write('S');
        break;
      case 0x00DC:
        buffer.write('U');
        break;
      case 0x00C2:
        buffer.write('A');
        break;
      case 0x00CE:
        buffer.write('I');
        break;
      case 0x00DB:
        buffer.write('U');
        break;
      default:
        buffer.write(String.fromCharCode(rune));
    }
  }
  return buffer.toString().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

String pickDistrictName(Placemark? placemark) {
  final candidates = <String>[
    placemark?.subAdministrativeArea ?? '',
    placemark?.locality ?? '',
    placemark?.subLocality ?? '',
    placemark?.street ?? '',
    placemark?.name ?? '',
  ];
  for (final value in candidates) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '';
}

List<DiyanetItem> parseItems(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return [];
    final data = decoded['data'];
    if (data is! List) return [];
    final items = <DiyanetItem>[];
    for (final entry in data) {
      if (entry is! Map<String, dynamic>) continue;
      final id = entry['_id']?.toString();
      final name = entry['name'] ?? entry['name_en'];
      if (id == null || name is! String) continue;
      items.add(DiyanetItem(id: id, name: name));
    }
    items.sort((a, b) => normalizeName(a.name).compareTo(normalizeName(b.name)));
    return items;
  } catch (_) {
    return [];
  }
}
