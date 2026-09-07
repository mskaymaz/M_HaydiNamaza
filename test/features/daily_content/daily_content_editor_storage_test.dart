import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mhaydinamaza/features/daily_content/editor/daily_content_editor_models.dart';
import 'package:mhaydinamaza/features/daily_content/editor/daily_content_editor_storage.dart';

void main() {
  group('DailyContentEditorStorage Tests', () {
    late Directory tempDir;
    late DailyContentEditorStorage storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('daily_content_test_');
      storage = DailyContentEditorStorage(approvedBasePath: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('write and read Ayahs payload correctly', () async {
      final record = const ContentItemRecord(
        id: '001/001',
        kind: 'ayah',
        ref: '001/001',
        ar: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        tr: 'Rahman ve Rahim olan Allah\'ın adıyla',
        en: 'In the name of Allah, the Entirely Merciful, the Especially Merciful',
        isApproved: true,
      );

      final payload = ContentDatasetPayload(
        type: 'ayah',
        records: [record],
      );

      await storage.writeAyahs(payload);
      final readBack = await storage.readAyahs();

      expect(readBack.records.length, equals(1));
      expect(readBack.records.first.id, equals('001/001'));
      expect(readBack.records.first.tr, contains('Rahman'));
      expect(readBack.records.first.isApproved, isTrue);
    });

    test('write and read Sequence correctly', () async {
      const sequence = ContentSequenceRecord(
        startDate: '2026-06-02',
        esmaOrderIds: ['esma-001', 'esma-002'],
      );

      await storage.writeSequence(sequence);
      final readBack = await storage.readSequence();

      expect(readBack.startDate, equals('2026-06-02'));
      expect(readBack.esmaOrderIds, equals(['esma-001', 'esma-002']));
    });
  });
}
