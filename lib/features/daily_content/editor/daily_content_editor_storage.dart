import 'dart:convert';
import 'dart:io';

import 'daily_content_editor_models.dart';

class DailyContentEditorStorage {
  final String approvedBasePath;
  final String? allAppPublishPath;

  DailyContentEditorStorage({
    this.approvedBasePath = 'assets/data/daily_content/approved',
    this.allAppPublishPath,
  });

  Future<ContentDatasetPayload> readAyahs() async {
    return _readPayload('$approvedBasePath/ayahs.v1.approved.json', 'ayah');
  }

  Future<ContentDatasetPayload> readHadiths() async {
    return _readPayload('$approvedBasePath/hadiths.v1.approved.json', 'hadith');
  }

  Future<ContentDatasetPayload> readEsma() async {
    return _readPayload(
      '$approvedBasePath/esmaul_husna.v1.approved.json',
      'esma',
    );
  }

  Future<ContentSequenceRecord> readSequence() async {
    final file = File('$approvedBasePath/sequence.v1.json');
    if (!await file.exists()) {
      return const ContentSequenceRecord();
    }
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ContentSequenceRecord.fromJson(decoded);
      }
    } catch (_) {}
    return const ContentSequenceRecord();
  }

  Future<void> writeAyahs(ContentDatasetPayload payload) async {
    await _writePayload('$approvedBasePath/ayahs.v1.approved.json', payload);
    if (allAppPublishPath != null) {
      await _writePayload('$allAppPublishPath/ayahs.v1.approved.json', payload);
    }
  }

  Future<void> writeHadiths(ContentDatasetPayload payload) async {
    await _writePayload('$approvedBasePath/hadiths.v1.approved.json', payload);
    if (allAppPublishPath != null) {
      await _writePayload(
        '$allAppPublishPath/hadiths.v1.approved.json',
        payload,
      );
    }
  }

  Future<void> writeEsma(ContentDatasetPayload payload) async {
    await _writePayload(
      '$approvedBasePath/esmaul_husna.v1.approved.json',
      payload,
    );
    if (allAppPublishPath != null) {
      await _writePayload(
        '$allAppPublishPath/esmaul_husna.v1.approved.json',
        payload,
      );
    }
  }

  Future<void> writeSequence(ContentSequenceRecord sequence) async {
    final file = File('$approvedBasePath/sequence.v1.json');
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(sequence.toJson()));
  }

  Future<ContentDatasetPayload> _readPayload(
    String filePath,
    String defaultType,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ContentDatasetPayload(type: defaultType, records: const []);
    }
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return ContentDatasetPayload.fromJson(decoded, defaultType);
      }
    } catch (_) {}
    return ContentDatasetPayload(type: defaultType, records: const []);
  }

  Future<void> _writePayload(
    String filePath,
    ContentDatasetPayload payload,
  ) async {
    final file = File(filePath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload.toJson()));
  }
}
