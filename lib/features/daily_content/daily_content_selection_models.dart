import 'daily_content_models.dart';

class DailyContentSelectionState {
  final String schemaVersion;
  final String dayKey;
  final String contentVersion;
  final String? ayahId;
  final String? hadithId;
  final String? esmaId;
  final String? sifatId;
  final List<String> recentAyahIds;
  final List<String> recentHadithIds;
  final List<String> seenAyahIds;
  final List<String> seenHadithIds;
  final int ayahCycleId;
  final int hadithCycleId;
  final int esmaCycleId;
  final int sifatCycleId;
  final String updatedAt;

  const DailyContentSelectionState({
    required this.schemaVersion,
    required this.dayKey,
    required this.contentVersion,
    required this.ayahId,
    required this.hadithId,
    this.esmaId,
    this.sifatId,
    required this.recentAyahIds,
    required this.recentHadithIds,
    required this.seenAyahIds,
    required this.seenHadithIds,
    required this.ayahCycleId,
    required this.hadithCycleId,
    this.esmaCycleId = 0,
    this.sifatCycleId = 0,
    required this.updatedAt,
  });

  factory DailyContentSelectionState.empty() {
    return const DailyContentSelectionState(
      schemaVersion: '1.0.0',
      dayKey: '',
      contentVersion: '',
      ayahId: null,
      hadithId: null,
      esmaId: null,
      sifatId: null,
      recentAyahIds: <String>[],
      recentHadithIds: <String>[],
      seenAyahIds: <String>[],
      seenHadithIds: <String>[],
      ayahCycleId: 0,
      hadithCycleId: 0,
      esmaCycleId: 0,
      sifatCycleId: 0,
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
    String? esmaId,
    bool clearEsmaId = false,
    String? sifatId,
    bool clearSifatId = false,
    List<String>? recentAyahIds,
    List<String>? recentHadithIds,
    List<String>? seenAyahIds,
    List<String>? seenHadithIds,
    int? ayahCycleId,
    int? hadithCycleId,
    int? esmaCycleId,
    int? sifatCycleId,
    String? updatedAt,
  }) {
    return DailyContentSelectionState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      dayKey: dayKey ?? this.dayKey,
      contentVersion: contentVersion ?? this.contentVersion,
      ayahId: clearAyahId ? null : (ayahId ?? this.ayahId),
      hadithId: clearHadithId ? null : (hadithId ?? this.hadithId),
      esmaId: clearEsmaId ? null : (esmaId ?? this.esmaId),
      sifatId: clearSifatId ? null : (sifatId ?? this.sifatId),
      recentAyahIds: recentAyahIds ?? this.recentAyahIds,
      recentHadithIds: recentHadithIds ?? this.recentHadithIds,
      seenAyahIds: seenAyahIds ?? this.seenAyahIds,
      seenHadithIds: seenHadithIds ?? this.seenHadithIds,
      ayahCycleId: ayahCycleId ?? this.ayahCycleId,
      hadithCycleId: hadithCycleId ?? this.hadithCycleId,
      esmaCycleId: esmaCycleId ?? this.esmaCycleId,
      sifatCycleId: sifatCycleId ?? this.sifatCycleId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DailyContentSelectionResult {
  final DailyAyahRecord? ayah;
  final DailyHadithRecord? hadith;
  final DailyEsmaRecord? esma;
  final DailyEsmaRecord? sifat;
  final DailyContentSelectionState state;
  final List<String> warnings;
  final int skippedCount;

  const DailyContentSelectionResult({
    required this.ayah,
    required this.hadith,
    this.esma,
    this.sifat,
    required this.state,
    required this.warnings,
    required this.skippedCount,
  });
}
