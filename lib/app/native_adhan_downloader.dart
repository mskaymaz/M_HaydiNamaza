import 'package:flutter/services.dart';

import 'adhan_catalog.dart';

class NativeAdhanDownloader {
  static const MethodChannel _channel = MethodChannel(
    'mhaydinamaza/prayer_notifications',
  );

  Future<String> downloadOption(AdhanCatalogOption option) async {
    final path = await _channel.invokeMethod<String>(
      'downloadAdhanOption',
      <String, Object?>{
        'id': option.id,
        'fileName': option.fileName,
        'url': option.url,
      },
    );
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty) throw Exception('adhan_download_failed');
    return trimmed;
  }
}
