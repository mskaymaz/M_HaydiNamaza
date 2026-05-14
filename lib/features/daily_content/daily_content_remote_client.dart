import 'dart:convert';

import 'package:http/http.dart' as http;

import 'daily_content_paths.dart';

class DailyContentRemoteBundle {
  final Map<String, dynamic> ayahPayload;
  final Map<String, dynamic> hadithPayload;
  final Set<String> ayahIds;
  final Set<String> hadithIds;
  final String monthKey;

  const DailyContentRemoteBundle({
    required this.ayahPayload,
    required this.hadithPayload,
    required this.ayahIds,
    required this.hadithIds,
    required this.monthKey,
  });
}

class DailyContentRemoteClient {
  final String _baseUrl;
  final http.Client _httpClient;

  DailyContentRemoteClient({
    String? baseUrl,
    http.Client? httpClient,
  }) : _baseUrl = (baseUrl ?? DailyContentPaths.remoteBaseUrl).trim(),
       _httpClient = httpClient ?? http.Client();

  Future<DailyContentRemoteBundle?> fetchMonthlyBundle({
    required DateTime date,
    required List<String> warnings,
  }) async {
    if (_baseUrl.isEmpty) {
      warnings.add('daily_content_remote: base url bos, remote atlandi.');
      return null;
    }

    final manifest = await _getJsonObject(
      uri: _resolveUri('manifest.json'),
      label: 'manifest.json',
      warnings: warnings,
    );
    if (manifest == null) return null;

    final monthKey = _monthKey(date);
    final monthlyPath = _readMonthlyPath(manifest, monthKey);
    if (monthlyPath == null) {
      warnings.add('daily_content_remote: monthly path bulunamadi ($monthKey).');
      return null;
    }

    final monthly = await _getJsonObject(
      uri: _resolveUri(monthlyPath),
      label: monthlyPath,
      warnings: warnings,
    );
    if (monthly == null) return null;

    final ayahIds = _readIdSet(monthly['ayah_ids']);
    final hadithIds = _readIdSet(monthly['hadith_ids']);
    if (ayahIds.isEmpty || hadithIds.isEmpty) {
      warnings.add(
        'daily_content_remote: aylik id listesi bos ($monthKey), local fallback.',
      );
      return null;
    }

    final ayahPath = _readPublishPath(manifest, type: 'ayahs');
    final hadithPath = _readPublishPath(manifest, type: 'hadiths');
    if (ayahPath == null || hadithPath == null) {
      warnings.add('daily_content_remote: publish dosya yolu bulunamadi.');
      return null;
    }

    final ayahPayload = await _getJsonObject(
      uri: _resolveUri(ayahPath),
      label: ayahPath,
      warnings: warnings,
    );
    final hadithPayload = await _getJsonObject(
      uri: _resolveUri(hadithPath),
      label: hadithPath,
      warnings: warnings,
    );
    if (ayahPayload == null || hadithPayload == null) {
      return null;
    }

    return DailyContentRemoteBundle(
      ayahPayload: ayahPayload,
      hadithPayload: hadithPayload,
      ayahIds: ayahIds,
      hadithIds: hadithIds,
      monthKey: monthKey,
    );
  }

  Future<Map<String, dynamic>?> _getJsonObject({
    required Uri uri,
    required String label,
    required List<String> warnings,
  }) async {
    try {
      final response = await _httpClient
          .get(uri)
          .timeout(DailyContentPaths.remoteRequestTimeout);
      if (response.statusCode != 200) {
        warnings.add('daily_content_remote: $label status=${response.statusCode}');
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        warnings.add('daily_content_remote: $label json object degil.');
        return null;
      }
      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      warnings.add('daily_content_remote: $label okunamadi ($error)');
      return null;
    }
  }

  Uri _resolveUri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    final left = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final right = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$left/$right');
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  String? _readMonthlyPath(Map<String, dynamic> manifest, String monthKey) {
    final rows = manifest['monthly'];
    if (rows is! List) return null;
    for (final row in rows) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      final month = map['month'];
      if (month is! String || month.trim() != monthKey) continue;
      final path = map['path'];
      if (path is String && path.trim().isNotEmpty) {
        return path.trim();
      }
      return null;
    }
    return null;
  }

  String? _readPublishPath(Map<String, dynamic> manifest, {required String type}) {
    final publishFiles = manifest['publish_files'];
    if (publishFiles is! Map) return null;
    final publishMap = Map<String, dynamic>.from(publishFiles);
    final rawType = publishMap[type];
    if (rawType is! Map) return null;
    final typeMap = Map<String, dynamic>.from(rawType);
    final path = typeMap['path'];
    if (path is! String || path.trim().isEmpty) return null;
    return path.trim();
  }

  Set<String> _readIdSet(Object? value) {
    if (value is! List) return const <String>{};
    final set = <String>{};
    for (final entry in value) {
      if (entry is! String) continue;
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;
      set.add(trimmed);
    }
    return set;
  }
}
