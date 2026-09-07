import 'dart:convert';

enum DailyContentType { ayah, hadith, esma }

class ContentItemRecord {
  final String id;
  final String kind;
  final String ref;
  final String ar;
  final String tr;
  final String en;
  final int priority;
  final bool isApproved;
  final String? approvedAt;
  final Map<String, dynamic> rawJson;

  const ContentItemRecord({
    required this.id,
    required this.kind,
    required this.ref,
    required this.ar,
    required this.tr,
    required this.en,
    this.priority = 1,
    this.isApproved = true,
    this.approvedAt,
    this.rawJson = const <String, dynamic>{},
  });

  ContentItemRecord copyWith({
    String? id,
    String? kind,
    String? ref,
    String? ar,
    String? tr,
    String? en,
    int? priority,
    bool? isApproved,
    String? approvedAt,
    Map<String, dynamic>? rawJson,
  }) {
    return ContentItemRecord(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      ref: ref ?? this.ref,
      ar: ar ?? this.ar,
      tr: tr ?? this.tr,
      en: en ?? this.en,
      priority: priority ?? this.priority,
      isApproved: isApproved ?? this.isApproved,
      approvedAt: approvedAt ?? this.approvedAt,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  Map<String, dynamic> toJson() {
    final copy = Map<String, dynamic>.from(rawJson);
    copy['id'] = id;
    copy['kind'] = kind;
    copy['ref'] = ref;
    copy['ar'] = ar;
    copy['tr'] = tr;
    copy['en'] = en;
    copy['priority'] = priority;
    copy['status'] = isApproved ? 'approved' : 'pending';
    if (approvedAt != null) {
      copy['approvedAt'] = approvedAt;
    }
    return copy;
  }

  static ContentItemRecord fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as String?)?.toLowerCase() ?? 'approved';
    return ContentItemRecord(
      id: json['id'] as String? ?? json['ref'] as String? ?? '',
      kind: json['kind'] as String? ?? 'ayah',
      ref: json['ref'] as String? ?? json['id'] as String? ?? '',
      ar: json['ar'] as String? ?? '',
      tr: json['tr'] as String? ?? '',
      en: json['en'] as String? ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      isApproved: status == 'approved',
      approvedAt: json['approvedAt'] as String?,
      rawJson: json,
    );
  }
}

class ContentDatasetPayload {
  final String schemaVersion;
  final String contentVersion;
  final String type;
  final List<ContentItemRecord> records;

  const ContentDatasetPayload({
    this.schemaVersion = '1.0.0',
    this.contentVersion = '',
    required this.type,
    required this.records,
  });

  Map<String, dynamic> toJson() {
    return {
      'schema_version': schemaVersion,
      'content_version': contentVersion,
      'type': type,
      'records': records.map((r) => r.toJson()).toList(),
    };
  }

  static ContentDatasetPayload fromJson(Map<String, dynamic> json, String defaultType) {
    final type = json['type'] as String? ?? defaultType;
    final itemsRaw = json['records'] ?? json['items'];
    final list = <ContentItemRecord>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map<String, dynamic>) {
          list.add(ContentItemRecord.fromJson(item));
        }
      }
    }
    return ContentDatasetPayload(
      schemaVersion: json['schema_version'] as String? ?? '1.0.0',
      contentVersion: json['content_version'] as String? ?? '',
      type: type,
      records: list,
    );
  }
}

class ContentSequenceRecord {
  final String startDate;
  final List<String> ayahOrderIds;
  final List<String> hadithOrderIds;
  final List<String> esmaOrderIds;

  const ContentSequenceRecord({
    this.startDate = '2026-06-02',
    this.ayahOrderIds = const [],
    this.hadithOrderIds = const [],
    this.esmaOrderIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate,
      'ayah_order_ids': ayahOrderIds,
      'hadith_order_ids': hadithOrderIds,
      'esma_order_ids': esmaOrderIds,
    };
  }

  static ContentSequenceRecord fromJson(Map<String, dynamic> json) {
    return ContentSequenceRecord(
      startDate: json['start_date'] as String? ?? '2026-06-02',
      ayahOrderIds: List<String>.from(json['ayah_order_ids'] ?? []),
      hadithOrderIds: List<String>.from(json['hadith_order_ids'] ?? []),
      esmaOrderIds: List<String>.from(json['esma_order_ids'] ?? []),
    );
  }
}
