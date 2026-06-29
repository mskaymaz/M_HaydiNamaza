import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'shared_settings_models.dart';
import 'shared_settings_parser.dart';

class SharedSettingsRemoteClient {
  const SharedSettingsRemoteClient({http.Client? httpClient})
    : _httpClient = httpClient;

  final http.Client? _httpClient;

  Future<List<OtherAppItem>> loadOtherApps({
    required String remoteUrl,
    required String localAssetPath,
    required String currentAppId,
  }) async {
    final remotePayload = await _fetchRemote(remoteUrl);
    final localPayload = await _fetchLocalAsset(localAssetPath);
    final payload = remotePayload?.trim().isNotEmpty == true
        ? remotePayload
        : localPayload;
    if (payload == null) return const <OtherAppItem>[];

    final localItems = localPayload == null
        ? const <OtherAppItem>[]
        : SharedSettingsParser.parseCatalogPayload(localPayload);
    final localById = <String, OtherAppItem>{
      for (final item in localItems) item.appId: item,
    };

    final items = SharedSettingsParser.parseCatalogPayload(payload)
        .map((item) => _withDeterministicVisuals(item, localById[item.appId]))
        .where((item) => item.isTargetFor(currentAppId))
        .toList(growable: false);
    items.sort((left, right) => left.order.compareTo(right.order));
    return items;
  }

  Future<UpdateManifest?> loadUpdateManifest({
    required String remoteUrl,
    required String localAssetPath,
  }) async {
    final payload = await _loadPayload(
      remoteUrl: remoteUrl,
      localAssetPath: localAssetPath,
    );
    if (payload == null) return null;
    return SharedSettingsParser.parseUpdatePayload(payload);
  }

  OtherAppItem _withDeterministicVisuals(
    OtherAppItem item,
    OtherAppItem? localItem,
  ) {
    if (localItem == null) return item;
    final localIconAsset = localItem.iconAsset.trim();
    final localName = localItem.name.trim();
    return item.copyWith(
      name: localName.isNotEmpty ? localName : item.name,
      iconAsset: localIconAsset.isNotEmpty ? localIconAsset : item.iconAsset,
    );
  }

  Future<String?> _loadPayload({
    required String remoteUrl,
    required String localAssetPath,
  }) async {
    final remote = await _fetchRemote(remoteUrl);
    if (remote != null && remote.trim().isNotEmpty) {
      return remote;
    }
    return _fetchLocalAsset(localAssetPath);
  }

  Future<String?> _fetchRemote(String remoteUrl) async {
    final uri = Uri.tryParse(remoteUrl.trim());
    if (uri == null) return null;

    try {
      final client = _httpClient ?? http.Client();
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (_httpClient == null) {
        client.close();
      }
      if (response.statusCode != 200) return null;
      return response.body;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fetchLocalAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return null;
    }
  }
}
