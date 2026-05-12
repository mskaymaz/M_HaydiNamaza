import 'dart:convert';

import 'daily_content_selection_models.dart';

class DailyContentStateCodec {
  static const String schemaVersion = '1.0.0';

  DailyContentSelectionState decodeOrDefault(
    String? raw, {
    List<String>? warnings,
  }) {
    if (raw == null || raw.trim().isEmpty) {
      return DailyContentSelectionState.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        warnings?.add('daily_content_state_v1: state object formatinda degil.');
        return DailyContentSelectionState.empty();
      }
      final map = Map<String, dynamic>.from(decoded);
      return DailyContentSelectionState(
        schemaVersion:
            _readString(map, 'schema_version') ?? DailyContentStateCodec.schemaVersion,
        dayKey: _readString(map, 'day_key') ?? '',
        contentVersion: _readString(map, 'content_version') ?? '',
        ayahId: _readString(map, 'ayah_id'),
        hadithId: _readString(map, 'hadith_id'),
        recentAyahIds: _readStringList(map, 'recent_ayah_ids'),
        recentHadithIds: _readStringList(map, 'recent_hadith_ids'),
        seenAyahIds: _readStringList(map, 'seen_ayah_ids'),
        seenHadithIds: _readStringList(map, 'seen_hadith_ids'),
        ayahCycleId: _readInt(map, 'ayah_cycle_id'),
        hadithCycleId: _readInt(map, 'hadith_cycle_id'),
        updatedAt: _readString(map, 'updated_at') ?? '',
      );
    } catch (_) {
      warnings?.add('daily_content_state_v1: state parse edilemedi, reset uygulandi.');
      return DailyContentSelectionState.empty();
    }
  }

  String encode(DailyContentSelectionState state) {
    final map = <String, dynamic>{
      'schema_version': state.schemaVersion,
      'day_key': state.dayKey,
      'content_version': state.contentVersion,
      'ayah_id': state.ayahId,
      'hadith_id': state.hadithId,
      'recent_ayah_ids': state.recentAyahIds,
      'recent_hadith_ids': state.recentHadithIds,
      'seen_ayah_ids': state.seenAyahIds,
      'seen_hadith_ids': state.seenHadithIds,
      'ayah_cycle_id': state.ayahCycleId,
      'hadith_cycle_id': state.hadithCycleId,
      'updated_at': state.updatedAt,
    };
    return jsonEncode(map);
  }

  String? _readString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  int _readInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  List<String> _readStringList(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! List) return const [];
    final result = <String>[];
    for (final item in value) {
      if (item is! String) continue;
      final trimmed = item.trim();
      if (trimmed.isEmpty) continue;
      if (!result.contains(trimmed)) {
        result.add(trimmed);
      }
    }
    return result;
  }
}

