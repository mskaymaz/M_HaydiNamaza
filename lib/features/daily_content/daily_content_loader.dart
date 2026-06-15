import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'daily_content_models.dart';
import 'daily_content_parse_result.dart';
import 'daily_content_paths.dart';
import 'daily_content_remote_client.dart';

part 'daily_content_loader_parsers.dart';
part 'daily_content_loader_helpers.dart';

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

    final records = _readRecords(payload);
    final schemaVersion =
        _readRequiredString(payload, 'schema_version') ??
        (records == null ? null : '1.0.0');
    final contentVersion =
        _readRequiredString(payload, 'content_version') ??
        _readMetadataString(payload, 'updatedAt') ??
        _readMetadataString(payload, 'exportedAt') ??
        (records == null ? null : 'local-items');
    final type =
        _readRequiredString(payload, 'type') ??
        _readTypeFromMetadata(payload) ??
        (records == null ? null : expectedType);

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
    final records = _readRecords(payload);
    final schemaVersion =
        _readRequiredString(payload, 'schema_version') ??
        (records == null ? null : '1.0.0');
    final contentVersion =
        _readRequiredString(payload, 'content_version') ??
        _readMetadataString(payload, 'updatedAt') ??
        _readMetadataString(payload, 'exportedAt') ??
        (records == null ? null : 'local-items');
    final type =
        _readRequiredString(payload, 'type') ??
        _readTypeFromMetadata(payload) ??
        (records == null ? null : expectedType);

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
}
