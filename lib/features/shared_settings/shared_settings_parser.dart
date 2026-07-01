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
      final appId = _normalizeAppId((map['app_id'] as String?)?.trim() ?? '');
      final name = (map['name'] as String?)?.trim() ?? '';
      final description = (map['description'] as String?)?.trim() ?? '';
      final url = (map['url'] as String?)?.trim() ?? '';
      final downloadUrl = _readFirstString(map, const [
        'download_url',
        'downloadUrl',
        'release_url',
        'releaseUrl',
      ]);
      final iconAsset = _readString(map, 'icon_asset', 'iconAsset');
      final iconUrl = _readString(map, 'icon_url', 'iconUrl');
      final platform = _normalizePlatform(
        _readFirstString(map, const [
          'platform',
          'platform_type',
          'platformType',
        ]),
      );
      final active = map['active'] is bool ? map['active'] as bool : true;
      final order = map['order'] is num ? (map['order'] as num).toInt() : 9999;
      final targets =
          (map['target_apps'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .map((value) => value.trim().toLowerCase())
              .where((value) => value.isNotEmpty)
              .toList(growable: false);

      if (appId.isEmpty || name.isEmpty || url.isEmpty) continue;
      if (Uri.tryParse(url) == null) continue;
      if (downloadUrl.isNotEmpty && Uri.tryParse(downloadUrl) == null) {
        continue;
      }

      items.add(
        OtherAppItem(
          appId: appId,
          name: name,
          description: description,
          url: url,
          iconAsset: iconAsset,
          iconUrl: iconUrl,
          downloadUrl: downloadUrl,
          platform: platform,
          active: active,
          order: order,
          targetApps: targets,
        ),
      );
    }
    items.sort((left, right) => left.order.compareTo(right.order));
    return items;
  }

  static String _normalizeAppId(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'rekat_sayar' || normalized == 'm_rekat_sayar') {
      return 'rekatsay';
    }
    return normalized;
  }

  static String _normalizePlatform(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'desktop' ||
        normalized == 'computer' ||
        normalized == 'pc' ||
        normalized == 'bilgisayar') {
      return 'desktop';
    }
    if (normalized == 'web') return 'web';
    return 'mobile';
  }

  static String _readString(
    Map<String, dynamic> map,
    String first,
    String second,
  ) {
    return _readFirstString(map, [first, second]);
  }

  static String _readFirstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is! String) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
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
      return jsonDecode(_cleanJsonPayload(payload));
    } catch (_) {
      return null;
    }
  }

  static String _cleanJsonPayload(String payload) {
    return payload.replaceFirst(String.fromCharCode(0xFEFF), '').trim();
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
