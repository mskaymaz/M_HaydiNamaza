import 'dart:convert';

import 'shared_settings_models.dart';

class SharedSettingsParser {
  const SharedSettingsParser._();

  static List<OtherAppItem> parseCatalogPayload(String payload) {
    final decoded = _decode(payload);
    final rows = _rawRows(decoded);
    final items = <OtherAppItem>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final appId = (map['app_id'] as String?)?.trim() ?? '';
      final name = (map['name'] as String?)?.trim() ?? '';
      final description = (map['description'] as String?)?.trim() ?? '';
      final url = (map['url'] as String?)?.trim() ?? '';
      final iconAsset = _readString(map, 'icon_asset', 'iconAsset');
      final iconUrl = _readString(map, 'icon_url', 'iconUrl');
      final active = map['active'] is bool ? map['active'] as bool : true;
      final order = map['order'] is num ? (map['order'] as num).toInt() : 9999;
      final targets = (map['target_apps'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .map((value) => value.trim().toLowerCase())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);

      if (appId.isEmpty || name.isEmpty || url.isEmpty) continue;
      if (Uri.tryParse(url) == null) continue;

      items.add(
        OtherAppItem(
          appId: appId,
          name: name,
          description: description,
          url: url,
          iconAsset: iconAsset,
          iconUrl: iconUrl,
          active: active,
          order: order,
          targetApps: targets,
        ),
      );
    }
    items.sort((left, right) => left.order.compareTo(right.order));
    return items;
  }

  static String _readString(Map<String, dynamic> map, String first, String second) {
    return ((map[first] ?? map[second]) as String?)?.trim() ?? '';
  }

  static UpdateManifest? parseUpdatePayload(String payload) {
    final decoded = _decode(payload);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    final version = (map['version'] as String?)?.trim() ?? '';
    final buildNumber = map['build_number'] is num
        ? (map['build_number'] as num).toInt()
        : -1;
    final url = (map['url'] as String?)?.trim() ?? '';
    final forceUpdate = map['force_update'] is bool
        ? map['force_update'] as bool
        : false;
    final notes = (map['notes'] as String?)?.trim() ?? '';

    if (version.isEmpty || buildNumber < 1 || url.isEmpty) return null;
    if (Uri.tryParse(url) == null) return null;

    return UpdateManifest(
      version: version,
      buildNumber: buildNumber,
      url: url,
      forceUpdate: forceUpdate,
      notes: notes,
    );
  }

  static dynamic _decode(String payload) {
    try {
      return jsonDecode(payload);
    } catch (_) {
      return null;
    }
  }

  static List<dynamic> _rawRows(dynamic decoded) {
    if (decoded is List<dynamic>) return decoded;
    if (decoded is! Map) return const <dynamic>[];
    final map = Map<String, dynamic>.from(decoded);
    final apps = map['apps'];
    if (apps is List<dynamic>) return apps;
    final items = map['items'];
    if (items is List<dynamic>) return items;
    return const <dynamic>[];
  }
}
