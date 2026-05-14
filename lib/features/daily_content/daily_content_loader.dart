import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'daily_content_models.dart';
import 'daily_content_parse_result.dart';
import 'daily_content_paths.dart';
import 'daily_content_remote_client.dart';

class DailyContentLoader {
  final DailyContentRemoteClient? _remoteClient;

  DailyContentLoader({
    DailyContentRemoteClient? remoteClient,
    bool enableRemote = false,
  }) : _remoteClient = enableRemote
           ? (remoteClient ?? DailyContentRemoteClient())
           : null;

  Future<DailyContentLoadResult> loadApprovedSampleContent({
    DateTime? referenceDate,
  }) async {
    final remoteWarnings = <String>[];
    if (_remoteClient != null) {
      final bundle = await _remoteClient!.fetchMonthlyBundle(
        date: referenceDate ?? DateTime.now(),
        warnings: remoteWarnings,
      );
      if (bundle != null) {
        final ayahResult = _loadApprovedPayload<DailyAyahRecord>(
          payload: bundle.ayahPayload,
          sourceLabel: 'remote:publish/ayahs.v1.approved.json',
          expectedType: 'ayah',
          recordParser: _parseAyahRecord,
        );
        final hadithResult = _loadApprovedPayload<DailyHadithRecord>(
          payload: bundle.hadithPayload,
          sourceLabel: 'remote:publish/hadiths.v1.approved.json',
          expectedType: 'hadith',
          recordParser: _parseHadithRecord,
        );

        final filteredAyahs = _filterAyahsForMonth(
          records: ayahResult.records,
          allowedIds: bundle.ayahIds,
          monthKey: bundle.monthKey,
          warnings: remoteWarnings,
        );
        final filteredHadiths = _filterHadithsForMonth(
          records: hadithResult.records,
          allowedIds: bundle.hadithIds,
          monthKey: bundle.monthKey,
          warnings: remoteWarnings,
        );

        return DailyContentLoadResult(
          ayahSchemaVersion: ayahResult.schemaVersion,
          hadithSchemaVersion: hadithResult.schemaVersion,
          ayahContentVersion: ayahResult.contentVersion,
          hadithContentVersion: hadithResult.contentVersion,
          ayahs: filteredAyahs,
          hadiths: filteredHadiths,
          skippedCount:
              ayahResult.skippedCount +
              hadithResult.skippedCount +
              (ayahResult.records.length - filteredAyahs.length) +
              (hadithResult.records.length - filteredHadiths.length),
          warnings: [
            ...remoteWarnings,
            ...ayahResult.warnings,
            ...hadithResult.warnings,
          ],
        );
      }
    }

    final ayahResult = await _loadApprovedFile<DailyAyahRecord>(
      path: DailyContentPaths.approvedAyahsSample,
      expectedType: 'ayah',
      recordParser: _parseAyahRecord,
    );
    final hadithResult = await _loadApprovedFile<DailyHadithRecord>(
      path: DailyContentPaths.approvedHadithsSample,
      expectedType: 'hadith',
      recordParser: _parseHadithRecord,
    );

    return DailyContentLoadResult(
      ayahSchemaVersion: ayahResult.schemaVersion,
      hadithSchemaVersion: hadithResult.schemaVersion,
      ayahContentVersion: ayahResult.contentVersion,
      hadithContentVersion: hadithResult.contentVersion,
      ayahs: ayahResult.records,
      hadiths: hadithResult.records,
      skippedCount: ayahResult.skippedCount + hadithResult.skippedCount,
      warnings: [...remoteWarnings, ...ayahResult.warnings, ...hadithResult.warnings],
    );
  }

  DailyContentFileParseResult<T> _loadApprovedPayload<T>({
    required Map<String, dynamic> payload,
    required String sourceLabel,
    required String expectedType,
    required T? Function(
      Map<String, dynamic> json,
      String path,
      int index,
      List<String> warnings,
    )
    recordParser,
  }) {
    final warnings = <String>[];
    final validRecords = <T>[];
    var skippedCount = 0;

    final schemaVersion = _readRequiredString(payload, 'schema_version');
    final contentVersion = _readRequiredString(payload, 'content_version');
    final type = _readRequiredString(payload, 'type');
    final records = payload['records'];

    if (schemaVersion == null) {
      warnings.add('$sourceLabel: schema_version zorunlu.');
    }
    if (contentVersion == null) {
      warnings.add('$sourceLabel: content_version zorunlu.');
    }
    if (type == null) {
      warnings.add('$sourceLabel: type zorunlu.');
    }
    if (records is! List) {
      warnings.add('$sourceLabel: records alani dizi olmali.');
      return DailyContentFileParseResult(
        schemaVersion: schemaVersion,
        contentVersion: contentVersion,
        type: type,
        records: validRecords,
        skippedCount: skippedCount,
        warnings: warnings,
      );
    }

    if (type != expectedType) {
      warnings.add('$sourceLabel: type beklenen degerle uyusmuyor ($expectedType).');
      return DailyContentFileParseResult(
        schemaVersion: schemaVersion,
        contentVersion: contentVersion,
        type: type,
        records: validRecords,
        skippedCount: records.length,
        warnings: warnings,
      );
    }
    if (schemaVersion == null || contentVersion == null) {
      return DailyContentFileParseResult(
        schemaVersion: schemaVersion,
        contentVersion: contentVersion,
        type: type,
        records: validRecords,
        skippedCount: records.length,
        warnings: warnings,
      );
    }

    for (var i = 0; i < records.length; i++) {
      final entry = records[i];
      if (entry is! Map) {
        skippedCount++;
        warnings.add('$sourceLabel[$i]: record object olmali.');
        continue;
      }
      final parsed = recordParser(
        Map<String, dynamic>.from(entry),
        sourceLabel,
        i,
        warnings,
      );
      if (parsed == null) {
        skippedCount++;
        continue;
      }
      validRecords.add(parsed);
    }

    return DailyContentFileParseResult(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      type: type,
      records: validRecords,
      skippedCount: skippedCount,
      warnings: warnings,
    );
  }

  Future<DailyContentFileParseResult<T>> _loadApprovedFile<T>({
    required String path,
    required String expectedType,
    required T? Function(
      Map<String, dynamic> json,
      String path,
      int index,
      List<String> warnings,
    )
    recordParser,
  }) async {
    final warnings = <String>[];
    final validRecords = <T>[];
    var skippedCount = 0;

    dynamic decoded;
    try {
      final raw = await rootBundle.loadString(path);
      decoded = jsonDecode(raw);
    } catch (error) {
      warnings.add('$path: json okunamadi ($error)');
      return DailyContentFileParseResult(
        schemaVersion: null,
        contentVersion: null,
        type: null,
        records: validRecords,
        skippedCount: skippedCount,
        warnings: warnings,
      );
    }

    if (decoded is! Map) {
      warnings.add('$path: top-level json object olmali.');
      return DailyContentFileParseResult(
        schemaVersion: null,
        contentVersion: null,
        type: null,
        records: validRecords,
        skippedCount: skippedCount,
        warnings: warnings,
      );
    }

    final payload = Map<String, dynamic>.from(decoded);
    final schemaVersion = _readRequiredString(payload, 'schema_version');
    final contentVersion = _readRequiredString(payload, 'content_version');
    final type = _readRequiredString(payload, 'type');
    final records = payload['records'];

    if (schemaVersion == null) {
      warnings.add('$path: schema_version zorunlu.');
    }
    if (contentVersion == null) {
      warnings.add('$path: content_version zorunlu.');
    }
    if (type == null) {
      warnings.add('$path: type zorunlu.');
    }
    if (records is! List) {
      warnings.add('$path: records alani dizi olmali.');
      return DailyContentFileParseResult(
        schemaVersion: schemaVersion,
        contentVersion: contentVersion,
        type: type,
        records: validRecords,
        skippedCount: skippedCount,
        warnings: warnings,
      );
    }

    if (type != expectedType) {
      warnings.add('$path: type beklenen degerle uyusmuyor ($expectedType).');
      return DailyContentFileParseResult(
        schemaVersion: schemaVersion,
        contentVersion: contentVersion,
        type: type,
        records: validRecords,
        skippedCount: records.length,
        warnings: warnings,
      );
    }
    if (schemaVersion == null || contentVersion == null) {
      return DailyContentFileParseResult(
        schemaVersion: schemaVersion,
        contentVersion: contentVersion,
        type: type,
        records: validRecords,
        skippedCount: records.length,
        warnings: warnings,
      );
    }

    for (var i = 0; i < records.length; i++) {
      final entry = records[i];
      if (entry is! Map) {
        skippedCount++;
        warnings.add('$path[$i]: record object olmali.');
        continue;
      }
      final parsed = recordParser(
        Map<String, dynamic>.from(entry),
        path,
        i,
        warnings,
      );
      if (parsed == null) {
        skippedCount++;
        continue;
      }
      validRecords.add(parsed);
    }

    return DailyContentFileParseResult(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      type: type,
      records: validRecords,
      skippedCount: skippedCount,
      warnings: warnings,
    );
  }

  DailyAyahRecord? _parseAyahRecord(
    Map<String, dynamic> json,
    String path,
    int index,
    List<String> warnings,
  ) {
    final id = _readRequiredString(json, 'id');
    final type = _readRequiredString(json, 'type');
    final surahName = _readRequiredString(json, 'surah_name');
    final surahNumber = _readRequiredInt(json, 'surah_number');
    final ayahNumber = _readRequiredInt(json, 'ayah_number');
    final text = _readRequiredString(json, 'text');
    final translation = _readRequiredString(json, 'translation');
    final mealSource = _readRequiredString(json, 'meal_source');
    final sourceNote = _readRequiredString(json, 'source_note');
    final topics = _readRequiredStringList(json, 'topics');
    final status = _readOptionalString(json, 'status') ?? 'approved';
    final approval = _parseApprovalOrDefault(json);

    if (id == null ||
        type == null ||
        surahName == null ||
        surahNumber == null ||
        ayahNumber == null ||
        text == null ||
        translation == null ||
        mealSource == null ||
        sourceNote == null ||
        topics == null) {
      warnings.add('$path[$index]: ayah kaydi zorunlu alanlari eksik.');
      return null;
    }

    if (type != 'ayah') {
      warnings.add('$path[$index]: type ayah olmali.');
      return null;
    }
    if (status != 'approved') {
      warnings.add('$path[$index]: status approved olmadigi icin atlandi.');
      return null;
    }

    return DailyAyahRecord(
      id: id,
      type: type,
      surahName: surahName,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      text: text,
      translation: translation,
      mealSource: mealSource,
      sourceNote: sourceNote,
      topics: topics,
      status: status,
      approval: approval,
    );
  }

  DailyHadithRecord? _parseHadithRecord(
    Map<String, dynamic> json,
    String path,
    int index,
    List<String> warnings,
  ) {
    final id = _readRequiredString(json, 'id');
    final type = _readRequiredString(json, 'type');
    final collection = _readRequiredString(json, 'collection');
    final book = _readRequiredString(json, 'book');
    final hadithNumber = _readRequiredString(json, 'hadith_number');
    final narrator = _readRequiredString(json, 'narrator');
    final text = _readRequiredString(json, 'text');
    final translation = _readRequiredString(json, 'translation');
    final grade = _readRequiredString(json, 'grade');
    final sourceNote = _readRequiredString(json, 'source_note');
    final topics = _readRequiredStringList(json, 'topics');
    final status = _readOptionalString(json, 'status') ?? 'approved';
    final approval = _parseApprovalOrDefault(json);

    if (id == null ||
        type == null ||
        collection == null ||
        book == null ||
        hadithNumber == null ||
        narrator == null ||
        text == null ||
        translation == null ||
        grade == null ||
        sourceNote == null ||
        topics == null) {
      warnings.add('$path[$index]: hadith kaydi zorunlu alanlari eksik.');
      return null;
    }

    if (type != 'hadith') {
      warnings.add('$path[$index]: type hadith olmali.');
      return null;
    }
    if (status != 'approved') {
      warnings.add('$path[$index]: status approved olmadigi icin atlandi.');
      return null;
    }

    return DailyHadithRecord(
      id: id,
      type: type,
      collection: collection,
      book: book,
      hadithNumber: hadithNumber,
      narrator: narrator,
      text: text,
      translation: translation,
      grade: grade,
      sourceNote: sourceNote,
      topics: topics,
      status: status,
      approval: approval,
    );
  }

  DailyContentApproval _parseApprovalOrDefault(Map<String, dynamic> json) {
    final rawApproval = json['approval'];
    if (rawApproval is! Map) {
      return const DailyContentApproval(
        approvedBy: 'publish_pipeline',
        approvedAt: '1970-01-01T00:00:00Z',
        reviewNote: '',
      );
    }
    final approval = Map<String, dynamic>.from(rawApproval);
    final approvedBy = _readRequiredString(approval, 'approved_by');
    final approvedAt = _readRequiredString(approval, 'approved_at');
    final reviewNote = _readRequiredString(approval, 'review_note') ?? '';

    if (approvedBy == null || approvedAt == null) {
      return const DailyContentApproval(
        approvedBy: 'publish_pipeline',
        approvedAt: '1970-01-01T00:00:00Z',
        reviewNote: '',
      );
    }

    return DailyContentApproval(
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      reviewNote: reviewNote,
    );
  }

  List<DailyAyahRecord> _filterAyahsForMonth({
    required List<DailyAyahRecord> records,
    required Set<String> allowedIds,
    required String monthKey,
    required List<String> warnings,
  }) {
    if (allowedIds.isEmpty) return records;
    final filtered = records.where((record) => allowedIds.contains(record.id)).toList();
    if (filtered.isEmpty) {
      warnings.add('daily_content_remote: ayah monthly listesi bos kaldi ($monthKey).');
      return records;
    }
    if (filtered.length != allowedIds.length) {
      warnings.add(
        'daily_content_remote: ayah monthly id uyumsuzlugu var '
        '(beklenen=${allowedIds.length}, bulunan=${filtered.length}).',
      );
    }
    return filtered;
  }

  List<DailyHadithRecord> _filterHadithsForMonth({
    required List<DailyHadithRecord> records,
    required Set<String> allowedIds,
    required String monthKey,
    required List<String> warnings,
  }) {
    if (allowedIds.isEmpty) return records;
    final filtered = records.where((record) => allowedIds.contains(record.id)).toList();
    if (filtered.isEmpty) {
      warnings.add(
        'daily_content_remote: hadith monthly listesi bos kaldi ($monthKey).',
      );
      return records;
    }
    if (filtered.length != allowedIds.length) {
      warnings.add(
        'daily_content_remote: hadith monthly id uyumsuzlugu var '
        '(beklenen=${allowedIds.length}, bulunan=${filtered.length}).',
      );
    }
    return filtered;
  }

  String? _readOptionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  int? _readRequiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is! String) return null;
    return int.tryParse(value.trim());
  }

  List<String>? _readRequiredStringList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) return null;
    final list = <String>[];
    for (final entry in value) {
      if (entry is! String) return null;
      final trimmed = entry.trim();
      if (trimmed.isEmpty) return null;
      list.add(trimmed);
    }
    return list;
  }
}
