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
    final remoteClient = _remoteClient;
    if (remoteClient != null) {
      final bundle = await remoteClient.fetchBundle(
        date: referenceDate ?? DateTime.now(),
        warnings: remoteWarnings,
      );
      if (bundle != null) {
        final esmaResult = _loadApprovedPayload<DailyEsmaRecord>(
          payload: bundle.esmaPayload,
          sourceLabel: 'remote:publish/esmaul_husna.v1.approved.json',
          expectedType: 'esma',
          recordParser: _parseEsmaRecord,
        );
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
        final orderedAyahs = _orderAyahs(
          records: ayahResult.records,
          orderedIds: bundle.ayahOrderIds,
        );
        final orderedHadiths = _orderHadiths(
          records: hadithResult.records,
          orderedIds: bundle.hadithOrderIds,
        );
        final esmaGroups = _groupEsmaRecords(esmaResult.records);
        final orderedEsmas = _orderEsmas(
          records: esmaGroups.esmas,
          orderedIds: bundle.esmaOrderIds,
        );
        final orderedSifats = _orderEsmas(
          records: esmaGroups.sifats,
          orderedIds: bundle.sifatOrderIds,
        );
        return DailyContentLoadResult(
          ayahSchemaVersion: ayahResult.schemaVersion,
          hadithSchemaVersion: hadithResult.schemaVersion,
          esmaSchemaVersion: esmaResult.schemaVersion,
          ayahContentVersion: ayahResult.contentVersion,
          hadithContentVersion: hadithResult.contentVersion,
          esmaContentVersion: esmaResult.contentVersion,
          ayahs: orderedAyahs,
          hadiths: orderedHadiths,
          esmas: orderedEsmas,
          sifats: orderedSifats,
          ayahOrderIds: _extractAyahIds(orderedAyahs),
          hadithOrderIds: _extractHadithIds(orderedHadiths),
          esmaOrderIds: _extractEsmaIds(orderedEsmas),
          sifatOrderIds: _extractEsmaIds(orderedSifats),
          sequenceStartDate: bundle.sequenceStartDate,
          skippedCount:
              ayahResult.skippedCount +
              hadithResult.skippedCount +
              esmaResult.skippedCount,
          warnings: [
            ...remoteWarnings,
            ...ayahResult.warnings,
            ...hadithResult.warnings,
            ...esmaResult.warnings,
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
    final esmaResult = await _loadApprovedFile<DailyEsmaRecord>(
      path: DailyContentPaths.approvedEsmaSample,
      expectedType: 'esma',
      recordParser: _parseEsmaRecord,
    );

    final localAyahIds = _extractAyahIds(ayahResult.records);
    final localHadithIds = _extractHadithIds(hadithResult.records);
    final esmaGroups = _groupEsmaRecords(esmaResult.records);
    final localEsmaIds = _extractEsmaIds(esmaGroups.esmas);
    final localSifatIds = _extractEsmaIds(esmaGroups.sifats);
    final sequenceAsset = await _loadLocalSequence(
      warnings: remoteWarnings,
      fallbackAyahIds: localAyahIds,
      fallbackHadithIds: localHadithIds,
      fallbackEsmaIds: localEsmaIds,
      fallbackSifatIds: localSifatIds,
    );
    final orderedAyahs = _orderAyahs(
      records: ayahResult.records,
      orderedIds: sequenceAsset.ayahOrderIds,
    );
    final orderedHadiths = _orderHadiths(
      records: hadithResult.records,
      orderedIds: sequenceAsset.hadithOrderIds,
    );
    final orderedEsmas = _orderEsmas(
      records: esmaGroups.esmas,
      orderedIds: sequenceAsset.esmaOrderIds,
    );
    final orderedSifats = _orderEsmas(
      records: esmaGroups.sifats,
      orderedIds: sequenceAsset.sifatOrderIds,
    );

    return DailyContentLoadResult(
      ayahSchemaVersion: ayahResult.schemaVersion,
      hadithSchemaVersion: hadithResult.schemaVersion,
      esmaSchemaVersion: esmaResult.schemaVersion,
      ayahContentVersion: ayahResult.contentVersion,
      hadithContentVersion: hadithResult.contentVersion,
      esmaContentVersion: esmaResult.contentVersion,
      ayahs: orderedAyahs,
      hadiths: orderedHadiths,
      esmas: orderedEsmas,
      sifats: orderedSifats,
      ayahOrderIds: _extractAyahIds(orderedAyahs),
      hadithOrderIds: _extractHadithIds(orderedHadiths),
      esmaOrderIds: _extractEsmaIds(orderedEsmas),
      sifatOrderIds: _extractEsmaIds(orderedSifats),
      sequenceStartDate: sequenceAsset.startDate,
      skippedCount:
          ayahResult.skippedCount +
          hadithResult.skippedCount +
          esmaResult.skippedCount,
      warnings: [
        ...remoteWarnings,
        ...ayahResult.warnings,
        ...hadithResult.warnings,
        ...esmaResult.warnings,
      ],
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
      warnings.add(
        '$sourceLabel: type beklenen degerle uyusmuyor ($expectedType).',
      );
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
    final textAr = _readRequiredString(json, 'text_ar') ?? _readRequiredString(json, 'text');
    final textTr = _readRequiredString(json, 'text_tr') ?? _readRequiredString(json, 'translation');
    final textEn = _readRequiredString(json, 'text_en');
    final sourceAr = _readRequiredString(json, 'source_ar');
    final sourceTr = _readRequiredString(json, 'source_tr');
    final sourceEn = _readRequiredString(json, 'source_en');
    final mealSource = _readRequiredString(json, 'meal_source') ?? 'source_based';
    final sourceNote = _readRequiredString(json, 'source_note') ?? '';
    final topics = _readRequiredStringList(json, 'topics');
    final status = _readOptionalString(json, 'status') ?? 'approved';
    final approval = _parseApprovalOrDefault(json);

    if (id == null ||
        type == null ||
        surahName == null ||
        surahNumber == null ||
        ayahNumber == null ||
        textAr == null ||
        textTr == null ||
        textEn == null ||
        sourceAr == null ||
        sourceTr == null ||
        sourceEn == null ||
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
      textAr: textAr,
      textTr: textTr,
      textEn: textEn,
      sourceAr: sourceAr,
      sourceTr: sourceTr,
      sourceEn: sourceEn,
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
    final textAr = _readRequiredString(json, 'text_ar') ?? _readRequiredString(json, 'text');
    final rawTextTr = _readRequiredString(json, 'text_tr') ?? _readRequiredString(json, 'text');
    final textEn = _readRequiredString(json, 'text_en') ?? _readRequiredString(json, 'translation');
    final sourceAr = _readRequiredString(json, 'source_ar');
    final sourceTr = _readRequiredString(json, 'source_tr');
    final sourceEn = _readRequiredString(json, 'source_en');
    final grade = _readRequiredString(json, 'grade');
    final bookReferenceTr = _readOptionalString(json, 'book_reference_tr') ?? '';
    final sourceNote = _readRequiredString(json, 'source_note') ?? '';
    final topics = _readRequiredStringList(json, 'topics');
    final status = _readOptionalString(json, 'status') ?? 'approved';
    final approval = _parseApprovalOrDefault(json);

    if (id == null ||
        type == null ||
        collection == null ||
        book == null ||
        hadithNumber == null ||
        narrator == null ||
        textAr == null ||
        rawTextTr == null ||
        textEn == null ||
        sourceAr == null ||
        sourceTr == null ||
        sourceEn == null ||
        grade == null ||
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

    final turkishTextAndReference = _normalizeTurkishHadithTextAndReference(
      rawText: rawTextTr,
      explicitBookReferenceTr: bookReferenceTr,
    );

    return DailyHadithRecord(
      id: id,
      type: type,
      collection: collection,
      book: book,
      hadithNumber: hadithNumber,
      narrator: narrator,
      textAr: textAr,
      textTr: turkishTextAndReference.textTr,
      textEn: textEn,
      sourceAr: sourceAr,
      sourceTr: sourceTr,
      sourceEn: sourceEn,
      bookReferenceTr: turkishTextAndReference.bookReferenceTr,
      grade: grade,
      sourceNote: sourceNote,
      topics: topics,
      status: status,
      approval: approval,
    );
  }

  DailyEsmaRecord? _parseEsmaRecord(
    Map<String, dynamic> json,
    String path,
    int index,
    List<String> warnings,
  ) {
    final id = _readRequiredString(json, 'id');
    final type = _readRequiredString(json, 'type') ?? 'esma';
    final kind = _readRequiredString(json, 'kind');
    final category = _readRequiredString(json, 'category') ?? '';
    final sourceId = _readRequiredInt(json, 'source_id') ?? _readRequiredInt(json, 'esma_number');
    final displayOrder = _readRequiredInt(json, 'display_order') ?? sourceId;
    final ref = _readRequiredString(json, 'ref') ?? id;
    final nameArabic =
        _readRequiredString(json, 'name_arabic') ??
        _readRequiredString(json, 'arabic_name');
    final nameTurkish =
        _readRequiredString(json, 'name_turkish') ??
        _readRequiredString(json, 'latin_tr');
    final nameTransliteration =
        _readRequiredString(json, 'name_transliteration') ??
        _readRequiredString(json, 'latin_en');
    final textAr =
        _readRequiredString(json, 'text_ar') ??
        _readRequiredString(json, 'ar') ??
        _readRequiredString(json, 'descriptionAr');
    final textTr =
        _readRequiredString(json, 'text_tr') ??
        _readRequiredString(json, 'tr') ??
        _readRequiredString(json, 'descriptionTr');
    final textEn =
        _readRequiredString(json, 'text_en') ??
        _readRequiredString(json, 'en') ??
        _readRequiredString(json, 'descriptionEn');
    final meaningAr = _readRequiredString(json, 'meaning_ar') ?? '';
    final meaningTr = _readRequiredString(json, 'meaning_tr') ?? '';
    final meaningEn = _readRequiredString(json, 'meaning_en') ?? '';
    final sourceNote = _readRequiredString(json, 'source_note') ?? '';
    final topics = _readRequiredStringList(json, 'topics') ?? const <String>[];
    final status = _readOptionalString(json, 'status') ?? 'approved';
    final approval = _parseApprovalOrDefault(json);

    if (id == null ||
        kind == null ||
        sourceId == null ||
        displayOrder == null ||
        ref == null ||
        nameArabic == null ||
        nameTurkish == null ||
        nameTransliteration == null ||
        textAr == null ||
        textTr == null ||
        textEn == null) {
      warnings.add('$path[$index]: esma kaydi zorunlu alanlari eksik.');
      return null;
    }

    if (type != 'esma') {
      warnings.add('$path[$index]: type esma olmali.');
      return null;
    }
    if (kind != 'esma' && kind != 'sifat') {
      warnings.add('$path[$index]: kind esma veya sifat olmali.');
      return null;
    }
    if (status != 'approved') {
      warnings.add('$path[$index]: status approved olmadigi icin atlandi.');
      return null;
    }

    return DailyEsmaRecord(
      id: id,
      type: type,
      kind: kind,
      category: category,
      sourceId: sourceId,
      displayOrder: displayOrder,
      ref: ref,
      nameArabic: nameArabic,
      nameTurkish: nameTurkish,
      nameTransliteration: nameTransliteration,
      textAr: textAr,
      textTr: textTr,
      textEn: textEn,
      meaningAr: meaningAr,
      meaningTr: meaningTr,
      meaningEn: meaningEn,
      sourceNote: sourceNote,
      topics: topics,
      status: status,
      approval: approval,
    );
  }

  _TurkishHadithTextAndReference _normalizeTurkishHadithTextAndReference({
    required String rawText,
    required String explicitBookReferenceTr,
  }) {
    final explicitReference = explicitBookReferenceTr.trim();
    final normalizedText = rawText.replaceAll('\r\n', '\n');
    if (explicitReference.isNotEmpty) {
      final text = _stripTrailingExactReference(
        text: normalizedText,
        reference: explicitReference,
      );
      return _TurkishHadithTextAndReference(
        textTr: text,
        bookReferenceTr: explicitReference,
      );
    }

    final extractedReference = _extractTrailingReferenceLine(normalizedText);
    if (extractedReference != null) {
      final text = _stripTrailingExactReference(
        text: normalizedText,
        reference: extractedReference,
      );
      return _TurkishHadithTextAndReference(
        textTr: text,
        bookReferenceTr: extractedReference,
      );
    }

    return _TurkishHadithTextAndReference(
      textTr: normalizedText,
      bookReferenceTr: '',
    );
  }

  String _stripTrailingExactReference({
    required String text,
    required String reference,
  }) {
    final trimmedRightText = text.trimRight();
    if (!trimmedRightText.endsWith(reference)) {
      return text;
    }
    final withoutReference = trimmedRightText.substring(
      0,
      trimmedRightText.length - reference.length,
    );
    return withoutReference.trimRight();
  }

  String? _extractTrailingReferenceLine(String text) {
    final lines = text.split('\n');
    var lastNonEmptyIndex = -1;
    for (var i = lines.length - 1; i >= 0; i--) {
      if (lines[i].trim().isNotEmpty) {
        lastNonEmptyIndex = i;
        break;
      }
    }
    if (lastNonEmptyIndex < 0) {
      return null;
    }
    final candidate = lines[lastNonEmptyIndex].trim();
    if (candidate.startsWith('(') &&
        candidate.contains(')') &&
        RegExp(r'[A-Z][0-9]{2,}').hasMatch(candidate)) {
      return candidate;
    }
    return null;
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

  List<DailyAyahRecord> _orderAyahs({
    required List<DailyAyahRecord> records,
    required List<String> orderedIds,
  }) {
    if (records.isEmpty) return const [];
    if (orderedIds.isEmpty) return records;
    final map = <String, DailyAyahRecord>{for (final r in records) r.id: r};
    final ordered = <DailyAyahRecord>[];
    final seen = <String>{};
    for (final id in orderedIds) {
      final row = map[id];
      if (row == null) continue;
      ordered.add(row);
      seen.add(id);
    }
    for (final row in records) {
      if (seen.contains(row.id)) continue;
      ordered.add(row);
    }
    return ordered;
  }

  List<DailyHadithRecord> _orderHadiths({
    required List<DailyHadithRecord> records,
    required List<String> orderedIds,
  }) {
    if (records.isEmpty) return const [];
    if (orderedIds.isEmpty) return records;
    final map = <String, DailyHadithRecord>{for (final r in records) r.id: r};
    final ordered = <DailyHadithRecord>[];
    final seen = <String>{};
    for (final id in orderedIds) {
      final row = map[id];
      if (row == null) continue;
      ordered.add(row);
      seen.add(id);
    }
    for (final row in records) {
      if (seen.contains(row.id)) continue;
      ordered.add(row);
    }
    return ordered;
  }

  List<DailyEsmaRecord> _orderEsmas({
    required List<DailyEsmaRecord> records,
    required List<String> orderedIds,
  }) {
    if (records.isEmpty) return const [];
    if (orderedIds.isEmpty) return records;
    final map = <String, DailyEsmaRecord>{for (final r in records) r.id: r};
    final ordered = <DailyEsmaRecord>[];
    final seen = <String>{};
    for (final id in orderedIds) {
      final row = map[id];
      if (row == null) continue;
      ordered.add(row);
      seen.add(id);
    }
    for (final row in records) {
      if (seen.contains(row.id)) continue;
      ordered.add(row);
    }
    return ordered;
  }

  _EsmaGroups _groupEsmaRecords(List<DailyEsmaRecord> records) {
    final esmas = <DailyEsmaRecord>[];
    final sifats = <DailyEsmaRecord>[];
    for (final record in records) {
      if (record.kind == 'sifat') {
        sifats.add(record);
      } else {
        esmas.add(record);
      }
    }
    return _EsmaGroups(esmas: esmas, sifats: sifats);
  }

  List<String> _extractAyahIds(List<DailyAyahRecord> records) {
    final ids = <String>[];
    for (final row in records) {
      final id = row.id.trim();
      if (id.isEmpty || ids.contains(id)) continue;
      ids.add(id);
    }
    return ids;
  }

  List<String> _extractHadithIds(List<DailyHadithRecord> records) {
    final ids = <String>[];
    for (final row in records) {
      final id = row.id.trim();
      if (id.isEmpty || ids.contains(id)) continue;
      ids.add(id);
    }
    return ids;
  }

  List<String> _extractEsmaIds(List<DailyEsmaRecord> records) {
    final ids = <String>[];
    for (final row in records) {
      final id = row.id.trim();
      if (id.isEmpty || ids.contains(id)) continue;
      ids.add(id);
    }
    return ids;
  }

  Future<_LocalSequenceAsset> _loadLocalSequence({
    required List<String> warnings,
    required List<String> fallbackAyahIds,
    required List<String> fallbackHadithIds,
    required List<String> fallbackEsmaIds,
    required List<String> fallbackSifatIds,
  }) async {
    try {
      final raw = await rootBundle.loadString(DailyContentPaths.approvedSequence);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        warnings.add('local sequence: json object degil, fallback kullanildi.');
        return _LocalSequenceAsset(
          startDate: DailyContentPaths.defaultSequenceStartDate,
          ayahOrderIds: fallbackAyahIds,
          hadithOrderIds: fallbackHadithIds,
          esmaOrderIds: fallbackEsmaIds,
          sifatOrderIds: fallbackSifatIds,
        );
      }
      final map = Map<String, dynamic>.from(decoded);
      final startDate =
          _readRequiredString(map, 'start_date') ??
          DailyContentPaths.defaultSequenceStartDate;
      final ayahOrderIds = _readRequiredStringList(map, 'ayah_order_ids') ?? fallbackAyahIds;
      final hadithOrderIds =
          _readRequiredStringList(map, 'hadith_order_ids') ?? fallbackHadithIds;
      final esmaOrderIds = _readRequiredStringList(map, 'esma_order_ids') ?? fallbackEsmaIds;
      final sifatOrderIds =
          _readRequiredStringList(map, 'sifat_order_ids') ?? fallbackSifatIds;
      return _LocalSequenceAsset(
        startDate: startDate,
        ayahOrderIds: ayahOrderIds,
        hadithOrderIds: hadithOrderIds,
        esmaOrderIds: esmaOrderIds,
        sifatOrderIds: sifatOrderIds,
      );
    } catch (_) {
      return _LocalSequenceAsset(
        startDate: DailyContentPaths.defaultSequenceStartDate,
        ayahOrderIds: fallbackAyahIds,
        hadithOrderIds: fallbackHadithIds,
        esmaOrderIds: fallbackEsmaIds,
        sifatOrderIds: fallbackSifatIds,
      );
    }
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
      if (!list.contains(trimmed)) {
        list.add(trimmed);
      }
    }
    return list;
  }
}

class _LocalSequenceAsset {
  final String startDate;
  final List<String> ayahOrderIds;
  final List<String> hadithOrderIds;
  final List<String> esmaOrderIds;
  final List<String> sifatOrderIds;

  const _LocalSequenceAsset({
    required this.startDate,
    required this.ayahOrderIds,
    required this.hadithOrderIds,
    required this.esmaOrderIds,
    required this.sifatOrderIds,
  });
}

class _EsmaGroups {
  final List<DailyEsmaRecord> esmas;
  final List<DailyEsmaRecord> sifats;

  const _EsmaGroups({required this.esmas, required this.sifats});
}

class _TurkishHadithTextAndReference {
  final String textTr;
  final String bookReferenceTr;

  const _TurkishHadithTextAndReference({
    required this.textTr,
    required this.bookReferenceTr,
  });
}
