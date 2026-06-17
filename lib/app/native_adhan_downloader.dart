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

  Future<void> previewBundled() async {
    await _channel.invokeMethod<void>('previewBundledAdhan');
  }

  Future<void> previewFile(String localPath) async {
    final trimmed = localPath.trim();
    if (trimmed.isEmpty) throw Exception('adhan_preview_file_missing');
    await _channel.invokeMethod<void>(
      'previewAdhanFile',
      <String, Object?>{'path': trimmed},
    );
  }

  Future<void> stopPreview() async {
    await _channel.invokeMethod<void>('stopAdhanPreview');
  }

  Future<void> deleteFile(String localPath) async {
    final trimmed = localPath.trim();
    if (trimmed.isEmpty) return;
    await _channel.invokeMethod<void>(
      'deleteAdhanFile',
      <String, Object?>{'path': trimmed},
    );
  }
}
