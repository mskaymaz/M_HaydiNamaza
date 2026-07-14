import 'dart:convert';

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
    final remotePayload = await _fetchRemote(remoteUrl);
    if (remotePayload != null && remotePayload.trim().isNotEmpty) {
      final remoteManifest =
          SharedSettingsParser.parseUpdatePayload(remotePayload);
      if (remoteManifest != null) return remoteManifest;
    }

    final localPayload = await _fetchLocalAsset(localAssetPath);
    if (localPayload == null) return null;
    return SharedSettingsParser.parseUpdatePayload(localPayload);
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


  Future<String?> _fetchRemote(String remoteUrl) async {
    final parsed = Uri.tryParse(remoteUrl.trim());
    if (parsed == null) return null;

    final uri = parsed.replace(
      queryParameters: <String, String>{
        ...parsed.queryParameters,
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    http.Client? ownedClient;
    final client = _httpClient ?? (ownedClient = http.Client());
    try {
      final response = await client
          .get(
            uri,
            headers: const <String, String>{
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
              'Accept': 'application/json,text/plain,*/*',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      return utf8.decode(response.bodyBytes);
    } catch (_) {
      return null;
    } finally {
      ownedClient?.close();
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
