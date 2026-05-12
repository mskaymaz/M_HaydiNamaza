import 'daily_content_models.dart';

class DailyContentSelectionState {
  final String schemaVersion;
  final String dayKey;
  final String contentVersion;
  final String? ayahId;
  final String? hadithId;
  final List<String> recentAyahIds;
  final List<String> recentHadithIds;
  final List<String> seenAyahIds;
  final List<String> seenHadithIds;
  final int ayahCycleId;
  final int hadithCycleId;
  final String updatedAt;

  const DailyContentSelectionState({
    required this.schemaVersion,
    required this.dayKey,
    required this.contentVersion,
    required this.ayahId,
    required this.hadithId,
    required this.recentAyahIds,
    required this.recentHadithIds,
    required this.seenAyahIds,
    required this.seenHadithIds,
    required this.ayahCycleId,
    required this.hadithCycleId,
    required this.updatedAt,
  });

  factory DailyContentSelectionState.empty() {
    return const DailyContentSelectionState(
      schemaVersion: '1.0.0',
      dayKey: '',
      contentVersion: '',
      ayahId: null,
      hadithId: null,
      recentAyahIds: <String>[],
      recentHadithIds: <String>[],
      seenAyahIds: <String>[],
      seenHadithIds: <String>[],
      ayahCycleId: 0,
      hadithCycleId: 0,
      updatedAt: '',
    );
  }

  DailyContentSelectionState copyWith({
    String? schemaVersion,
    String? dayKey,
    String? contentVersion,
    String? ayahId,
    bool clearAyahId = false,
    String? hadithId,
    bool clearHadithId = false,
    List<String>? recentAyahIds,
    List<String>? recentHadithIds,
    List<String>? seenAyahIds,
    List<String>? seenHadithIds,
    int? ayahCycleId,
    int? hadithCycleId,
    String? updatedAt,
  }) {
    return DailyContentSelectionState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      dayKey: dayKey ?? this.dayKey,
      contentVersion: contentVersion ?? this.contentVersion,
      ayahId: clearAyahId ? null : (ayahId ?? this.ayahId),
      hadithId: clearHadithId ? null : (hadithId ?? this.hadithId),
      recentAyahIds: recentAyahIds ?? this.recentAyahIds,
      recentHadithIds: recentHadithIds ?? this.recentHadithIds,
      seenAyahIds: seenAyahIds ?? this.seenAyahIds,
      seenHadithIds: seenHadithIds ?? this.seenHadithIds,
      ayahCycleId: ayahCycleId ?? this.ayahCycleId,
      hadithCycleId: hadithCycleId ?? this.hadithCycleId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DailyContentSelectionResult {
  final DailyAyahRecord? ayah;
  final DailyHadithRecord? hadith;
  final DailyContentSelectionState state;
  final List<String> warnings;
  final int skippedCount;

  const DailyContentSelectionResult({
    required this.ayah,
    required this.hadith,
    required this.state,
    required this.warnings,
    required this.skippedCount,
  });
}

