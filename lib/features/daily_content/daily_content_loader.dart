import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'daily_content_models.dart';
import 'daily_content_parse_result.dart';
import 'daily_content_paths.dart';

class DailyContentLoader {
  Future<DailyContentLoadResult> loadApprovedSampleContent() async {
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
      ayahs: ayahResult.records,
      hadiths: hadithResult.records,
      skippedCount: ayahResult.skippedCount + hadithResult.skippedCount,
      warnings: [...ayahResult.warnings, ...hadithResult.warnings],
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
        records: validRecords,
        skippedCount: skippedCount,
        warnings: warnings,
      );
    }

    if (decoded is! Map) {
      warnings.add('$path: top-level json object olmali.');
      return DailyContentFileParseResult(
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
      warnings.add('$path: records alanı dizi olmali.');
      return DailyContentFileParseResult(
        records: validRecords,
        skippedCount: skippedCount,
        warnings: warnings,
      );
    }

    if (type != expectedType) {
      warnings.add('$path: type beklenen degerle uyusmuyor ($expectedType).');
      return DailyContentFileParseResult(
        records: validRecords,
        skippedCount: records.length,
        warnings: warnings,
      );
    }
    if (schemaVersion == null || contentVersion == null) {
      return DailyContentFileParseResult(
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
    final status = _readRequiredString(json, 'status');
    final approval = _parseApproval(json, path, index, warnings);

    if (id == null ||
        type == null ||
        surahName == null ||
        surahNumber == null ||
        ayahNumber == null ||
        text == null ||
        translation == null ||
        mealSource == null ||
        sourceNote == null ||
        topics == null ||
        status == null ||
        approval == null) {
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
    final status = _readRequiredString(json, 'status');
    final approval = _parseApproval(json, path, index, warnings);

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
        topics == null ||
        status == null ||
        approval == null) {
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

  DailyContentApproval? _parseApproval(
    Map<String, dynamic> json,
    String path,
    int index,
    List<String> warnings,
  ) {
    final rawApproval = json['approval'];
    if (rawApproval is! Map) {
      warnings.add('$path[$index]: approval object olmali.');
      return null;
    }
    final approval = Map<String, dynamic>.from(rawApproval);
    final approvedBy = _readRequiredString(approval, 'approved_by');
    final approvedAt = _readRequiredString(approval, 'approved_at');
    final reviewNote = _readRequiredString(approval, 'review_note') ?? '';

    if (approvedBy == null || approvedAt == null) {
      warnings.add(
        '$path[$index]: approval.approved_by ve approval.approved_at zorunlu.',
      );
      return null;
    }

    return DailyContentApproval(
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      reviewNote: reviewNote,
    );
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

