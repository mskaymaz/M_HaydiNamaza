import 'dart:convert';

import 'package:flutter/services.dart';

import 'qibla_location_model.dart';

class QiblaRepository {
  static const String defaultAssetPath =
      'assets/data/qibla/locations.latest.json';

  final AssetBundle _assetBundle;
  final String _assetPath;

  Future<QiblaLocationIndex>? _indexFuture;

  QiblaRepository({
    AssetBundle? assetBundle,
    String assetPath = defaultAssetPath,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _assetPath = assetPath;

  Future<QiblaLocation?> findForSelectedLocation({
    String? locationId,
    String? stateName,
    String? locationName,
  }) async {
    final index = await _loadIndex();
    final id = int.tryParse((locationId ?? '').trim());
    if (id != null) {
      final match = index.byLocationId[id];
      if (match != null) return match;
    }

    final stateKey = _normalizeKey(stateName);
    final locationKey = _normalizeKey(locationName);
    if (stateKey.isEmpty || locationKey.isEmpty) return null;
    return index.byStateAndLocation['$stateKey/$locationKey'];
  }

  Future<QiblaLocationIndex> _loadIndex() {
    return _indexFuture ??= _readIndex();
  }

  Future<QiblaLocationIndex> _readIndex() async {
    try {
      final text = await _assetBundle.loadString(_assetPath);
      final root = jsonDecode(text);
      if (root is! Map<String, dynamic>) {
        return QiblaLocationIndex.empty;
      }
      final rawLocations = root['locations'];
      if (rawLocations is! List) return QiblaLocationIndex.empty;

      final locations = <QiblaLocation>[];
      for (final item in rawLocations) {
        if (item is! Map) continue;
        try {
          locations.add(
            QiblaLocation.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {
          // Ignore malformed records and keep the compass usable with fallback.
        }
      }
      return QiblaLocationIndex.fromLocations(locations);
    } catch (_) {
      return QiblaLocationIndex.empty;
    }
  }

  static String _normalizeKey(String? input) {
    var value = (input ?? '').trim().toUpperCase();
    if (value.isEmpty) return '';
    const replacements = <String, String>{
      'Ç': 'C',
      'Ğ': 'G',
      'İ': 'I',
      'İ': 'I',
      'Ö': 'O',
      'Ş': 'S',
      'Ü': 'U',
      'Â': 'A',
      'Î': 'I',
      'Û': 'U',
    };
    replacements.forEach((from, to) {
      value = value.replaceAll(from, to);
    });
    return value.replaceAll(RegExp(r'[^A-Z0-9]+'), ' ').trim();
  }
}

class QiblaLocationIndex {
  final Map<int, QiblaLocation> byLocationId;
  final Map<String, QiblaLocation> byStateAndLocation;

  const QiblaLocationIndex({
    required this.byLocationId,
    required this.byStateAndLocation,
  });

  static const QiblaLocationIndex empty = QiblaLocationIndex(
    byLocationId: <int, QiblaLocation>{},
    byStateAndLocation: <String, QiblaLocation>{},
  );

  factory QiblaLocationIndex.fromLocations(List<QiblaLocation> locations) {
    final byLocationId = <int, QiblaLocation>{};
    final byStateAndLocation = <String, QiblaLocation>{};
    for (final location in locations) {
      byLocationId[location.locationId] = location;
      final stateKey = QiblaRepository._normalizeKey(location.stateName);
      final locationKey = QiblaRepository._normalizeKey(location.locationName);
      if (stateKey.isNotEmpty && locationKey.isNotEmpty) {
        byStateAndLocation['$stateKey/$locationKey'] = location;
      }
    }
    return QiblaLocationIndex(
      byLocationId: byLocationId,
      byStateAndLocation: byStateAndLocation,
    );
  }
}
