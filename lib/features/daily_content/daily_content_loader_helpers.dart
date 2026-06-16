part of 'daily_content_loader.dart';

extension DailyContentLoaderHelpers on DailyContentLoader {
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
      final raw = await rootBundle.loadString(
        DailyContentPaths.approvedSequence,
      );
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        warnings.add('local sequence: json object değil, fallback kullanıldı.');
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
      final ayahOrderIds =
          _readRequiredStringList(map, 'ayah_order_ids') ?? fallbackAyahIds;
      final hadithOrderIds =
          _readRequiredStringList(map, 'hadith_order_ids') ?? fallbackHadithIds;
      final esmaOrderIds =
          _readRequiredStringList(map, 'esma_order_ids') ?? fallbackEsmaIds;
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
    if (value is num) return value.toString();
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _readRequiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toString();
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  List<dynamic>? _readRecords(Map<String, dynamic> json) {
    final records = json['records'];
    if (records is List) return records;
    final items = json['items'];
    if (items is List) return items;
    return null;
  }

  String? _readMetadataString(Map<String, dynamic> json, String key) {
    final metadata = json['metadata'];
    if (metadata is! Map) return null;
    return _readStringFromMap(Map<String, dynamic>.from(metadata), key);
  }

  String? _readTypeFromMetadata(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    if (metadata is! Map) return null;
    final dataset = _readStringFromMap(
      Map<String, dynamic>.from(metadata),
      'dataset',
    );
    if (dataset == 'hadiths') return 'hadith';
    if (dataset == 'ayahs') return 'ayah';
    if (dataset == 'esma') return 'esma';
    return null;
  }

  Map<String, dynamic> _readMap(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  Map<String, dynamic> _readNestedMap(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  String? _readStringFromMap(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toString();
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _readNestedText(Map<String, dynamic> json, String language) {
    final text = json['text'];
    if (text is! Map) return null;
    final languageBlock = text[language];
    if (languageBlock is String) {
      final trimmed = languageBlock.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (languageBlock is! Map) return null;
    final map = Map<String, dynamic>.from(languageBlock);
    return _readStringFromMap(map, 'clean') ??
        _readStringFromMap(map, 'sourceText');
  }

  int? _readAyahEndNumberFromReference(String? reference, int ayahNumber) {
    final value = reference?.trim();
    if (value == null || value.isEmpty) return null;
    final match = RegExp(
      r'[/:-](\d{1,3})(?:\s*-\s*(\d{1,3}))?',
    ).firstMatch(value);
    if (match == null) return null;
    final start = int.tryParse(match.group(1) ?? '');
    final end = int.tryParse(match.group(2) ?? '');
    if (start != ayahNumber || end == null || end <= ayahNumber) {
      return null;
    }
    return end;
  }

  int? _readAyahEndNumberFromText(List<String> texts, int ayahNumber) {
    var maxNumber = ayahNumber;
    final markerPattern = RegExp(r'\((\d{1,3})\)');
    for (final text in texts) {
      for (final match in markerPattern.allMatches(text)) {
        final number = int.tryParse(match.group(1) ?? '');
        if (number == null) continue;
        if (number < ayahNumber || number > ayahNumber + 20) continue;
        if (number > maxNumber) {
          maxNumber = number;
        }
      }
    }
    return maxNumber > ayahNumber ? maxNumber : null;
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
