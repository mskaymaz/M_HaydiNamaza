import 'dart:convert';

import 'package:http/http.dart' as http;

import 'daily_content_paths.dart';

class DailyContentRemoteBundle {
  final Map<String, dynamic> ayahPayload;
  final Map<String, dynamic> hadithPayload;
  final Map<String, dynamic> esmaPayload;
  final List<String> ayahOrderIds;
  final List<String> hadithOrderIds;
  final List<String> esmaOrderIds;
  final List<String> sifatOrderIds;
  final String sequenceStartDate;

  const DailyContentRemoteBundle({
    required this.ayahPayload,
    required this.hadithPayload,
    required this.esmaPayload,
    required this.ayahOrderIds,
    required this.hadithOrderIds,
    required this.esmaOrderIds,
    required this.sifatOrderIds,
    required this.sequenceStartDate,
  });
}

class DailyContentRemoteClient {
  final String _baseUrl;
  final http.Client _httpClient;

  DailyContentRemoteClient({String? baseUrl, http.Client? httpClient})
    : _baseUrl = (baseUrl ?? DailyContentPaths.remoteBaseUrl).trim(),
      _httpClient = httpClient ?? http.Client();

  Future<DailyContentRemoteBundle?> fetchBundle({
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

    final ayahPath = _readPublishPath(manifest, type: 'ayahs');
    final hadithPath = _readPublishPath(manifest, type: 'hadiths');
    final esmaPath = _readPublishPath(manifest, type: 'esmas');
    if (ayahPath == null || hadithPath == null || esmaPath == null) {
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
    final esmaPayload = await _getJsonObject(
      uri: _resolveUri(esmaPath),
      label: esmaPath,
      warnings: warnings,
    );
    if (ayahPayload == null || hadithPayload == null || esmaPayload == null) {
      return null;
    }

    final startDate =
        _readScheduleStartDate(manifest) ??
        DailyContentPaths.defaultSequenceStartDate;
    final sequencePaths = _readSequencePaths(manifest);

    final ayahOrderIds = await _loadOrderIds(
      path: sequencePaths.$1,
      payloadType: 'ayah',
      fallbackPayload: ayahPayload,
      warnings: warnings,
    );
    final hadithOrderIds = await _loadOrderIds(
      path: sequencePaths.$2,
      payloadType: 'hadith',
      fallbackPayload: hadithPayload,
      warnings: warnings,
    );
    final esmaOrderIds = await _loadOrderIds(
      path: sequencePaths.$3,
      payloadType: 'esma',
      fallbackPayload: esmaPayload,
      warnings: warnings,
      recordKind: 'esma',
    );
    final sifatOrderIds = await _loadOrderIds(
      path: sequencePaths.$4,
      payloadType: 'sifat',
      fallbackPayload: esmaPayload,
      warnings: warnings,
      recordKind: 'sifat',
    );

    return DailyContentRemoteBundle(
      ayahPayload: ayahPayload,
      hadithPayload: hadithPayload,
      esmaPayload: esmaPayload,
      ayahOrderIds: ayahOrderIds,
      hadithOrderIds: hadithOrderIds,
      esmaOrderIds: esmaOrderIds,
      sifatOrderIds: sifatOrderIds,
      sequenceStartDate: startDate,
    );
  }

  Future<List<String>> _loadOrderIds({
    required String? path,
    required String payloadType,
    required Map<String, dynamic> fallbackPayload,
    required List<String> warnings,
    String? recordKind,
  }) async {
    final fallback = _extractIdsFromPayload(fallbackPayload, recordKind: recordKind);
    if (path == null || path.trim().isEmpty) return fallback;
    final obj = await _getJsonObject(
      uri: _resolveUri(path),
      label: path,
      warnings: warnings,
    );
    if (obj == null) return fallback;
    final ids = _extractIds(obj['ids']);
    if (ids.isEmpty) {
      warnings.add(
        'daily_content_remote: $payloadType sirasi bos, payload sirasi kullanildi.',
      );
      return fallback;
    }
    return ids;
  }

  List<String> _extractIdsFromPayload(
    Map<String, dynamic> payload, {
    String? recordKind,
  }) {
    final records = payload['records'];
    if (records is! List) return const <String>[];
    final ids = <String>[];
    for (final row in records) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      if (recordKind != null && map['kind'] != recordKind) continue;
      final id = map['id'];
      if (id is! String) continue;
      final trimmed = id.trim();
      if (trimmed.isEmpty || ids.contains(trimmed)) continue;
      ids.add(trimmed);
    }
    return ids;
  }

  List<String> _extractIds(Object? value) {
    if (value is! List) return const <String>[];
    final ids = <String>[];
    for (final row in value) {
      if (row is! String) continue;
      final trimmed = row.trim();
      if (trimmed.isEmpty || ids.contains(trimmed)) continue;
      ids.add(trimmed);
    }
    return ids;
  }

  String? _readScheduleStartDate(Map<String, dynamic> manifest) {
    final raw = manifest['schedule'];
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final value = map['start_date'];
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  (String?, String?, String?, String?) _readSequencePaths(
    Map<String, dynamic> manifest,
  ) {
    final raw = manifest['sequence_files'];
    if (raw is! Map) return (null, null, null, null);
    final map = Map<String, dynamic>.from(raw);

    String? readPath(String key) {
      final row = map[key];
      if (row is! Map) return null;
      final item = Map<String, dynamic>.from(row);
      final path = item['path'];
      if (path is! String) return null;
      final trimmed = path.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return (
      readPath('ayah_ids'),
      readPath('hadith_ids'),
      readPath('esma_ids'),
      readPath('sifat_ids'),
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
    final left = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final right = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$left/$right');
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
}
