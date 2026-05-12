import 'daily_content_clock.dart';
import 'daily_content_loader.dart';
import 'daily_content_models.dart';
import 'daily_content_selection_models.dart';
import 'daily_content_state_codec.dart';
import 'daily_content_state_repository.dart';

class DailyContentSelectionEngine {
  final DailyContentLoader _loader;
  final DailyContentStateRepository _stateRepository;
  final DailyContentClock _clock;
  final int _recentWindow;

  DailyContentSelectionEngine({
    DailyContentLoader? loader,
    DailyContentStateRepository? stateRepository,
    DailyContentClock? clock,
    int recentWindow = 7,
  }) : _loader = loader ?? DailyContentLoader(),
       _stateRepository = stateRepository ?? DailyContentStateRepository(),
       _clock = clock ?? const SystemDailyContentClock(),
       _recentWindow = recentWindow < 0 ? 0 : recentWindow;

  Future<DailyContentSelectionResult> selectToday() async {
    final warnings = <String>[];
    final loadResult = await _loader.loadApprovedSampleContent();
    warnings.addAll(loadResult.warnings);

    final currentState = await _stateRepository.read(warnings: warnings);
    final todayKey = _clock.dayKey();
    final contentVersion = _buildContentVersion(loadResult);

    final ayahs = _dedupeAyahRecords(loadResult.ayahs, warnings);
    final hadiths = _dedupeHadithRecords(loadResult.hadiths, warnings);

    final sameDay = currentState.dayKey == todayKey;
    final ayahOutcome = _selectForType(
      label: 'ayah',
      candidateIds: ayahs.map((e) => e.id).toList(),
      currentId: currentState.ayahId,
      canReuseCurrent: sameDay,
      recentIds: currentState.recentAyahIds,
      seenIds: currentState.seenAyahIds,
      cycleId: currentState.ayahCycleId,
      dayKey: todayKey,
      contentVersion: contentVersion,
      warnings: warnings,
    );
    final hadithOutcome = _selectForType(
      label: 'hadith',
      candidateIds: hadiths.map((e) => e.id).toList(),
      currentId: currentState.hadithId,
      canReuseCurrent: sameDay,
      recentIds: currentState.recentHadithIds,
      seenIds: currentState.seenHadithIds,
      cycleId: currentState.hadithCycleId,
      dayKey: todayKey,
      contentVersion: contentVersion,
      warnings: warnings,
    );

    final nextState = currentState.copyWith(
      schemaVersion: DailyContentStateCodec.schemaVersion,
      dayKey: todayKey,
      contentVersion: contentVersion,
      ayahId: ayahOutcome.selectedId,
      clearAyahId: ayahOutcome.selectedId == null,
      hadithId: hadithOutcome.selectedId,
      clearHadithId: hadithOutcome.selectedId == null,
      recentAyahIds: ayahOutcome.recentIds,
      recentHadithIds: hadithOutcome.recentIds,
      seenAyahIds: ayahOutcome.seenIds,
      seenHadithIds: hadithOutcome.seenIds,
      ayahCycleId: ayahOutcome.cycleId,
      hadithCycleId: hadithOutcome.cycleId,
      updatedAt: _clock.now().toIso8601String(),
    );
    await _stateRepository.write(nextState);

    return DailyContentSelectionResult(
      ayah: _findAyahById(ayahs, ayahOutcome.selectedId),
      hadith: _findHadithById(hadiths, hadithOutcome.selectedId),
      state: nextState,
      warnings: warnings,
      skippedCount: loadResult.skippedCount,
    );
  }

  String _buildContentVersion(DailyContentLoadResult result) {
    final ayahVersion = (result.ayahContentVersion ?? '').trim();
    final hadithVersion = (result.hadithContentVersion ?? '').trim();
    final left = ayahVersion.isEmpty ? 'na' : ayahVersion;
    final right = hadithVersion.isEmpty ? 'na' : hadithVersion;
    return '$left|$right';
  }

  List<DailyAyahRecord> _dedupeAyahRecords(
    List<DailyAyahRecord> records,
    List<String> warnings,
  ) {
    final seenIds = <String>{};
    final unique = <DailyAyahRecord>[];
    for (final record in records) {
      if (seenIds.contains(record.id)) {
        warnings.add('ayah duplicate id atlandi: ${record.id}');
        continue;
      }
      seenIds.add(record.id);
      unique.add(record);
    }
    return unique;
  }

  List<DailyHadithRecord> _dedupeHadithRecords(
    List<DailyHadithRecord> records,
    List<String> warnings,
  ) {
    final seenIds = <String>{};
    final unique = <DailyHadithRecord>[];
    for (final record in records) {
      if (seenIds.contains(record.id)) {
        warnings.add('hadith duplicate id atlandi: ${record.id}');
        continue;
      }
      seenIds.add(record.id);
      unique.add(record);
    }
    return unique;
  }

  DailyAyahRecord? _findAyahById(List<DailyAyahRecord> records, String? id) {
    if (id == null || id.trim().isEmpty) return null;
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  DailyHadithRecord? _findHadithById(
    List<DailyHadithRecord> records,
    String? id,
  ) {
    if (id == null || id.trim().isEmpty) return null;
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  _TypeSelectionOutcome _selectForType({
    required String label,
    required List<String> candidateIds,
    required String? currentId,
    required bool canReuseCurrent,
    required List<String> recentIds,
    required List<String> seenIds,
    required int cycleId,
    required String dayKey,
    required String contentVersion,
    required List<String> warnings,
  }) {
    if (candidateIds.isEmpty) {
      warnings.add('$label: valid icerik listesi bos, secim null.');
      return _TypeSelectionOutcome(
        selectedId: null,
        recentIds: const <String>[],
        seenIds: const <String>[],
        cycleId: cycleId,
      );
    }

    final candidateSet = candidateIds.toSet();
    final normalizedSeen = _retainKnownIds(seenIds, candidateSet);
    final normalizedRecent = _retainKnownIds(recentIds, candidateSet);

    if (canReuseCurrent &&
        currentId != null &&
        currentId.trim().isNotEmpty &&
        candidateSet.contains(currentId)) {
      return _TypeSelectionOutcome(
        selectedId: currentId,
        recentIds: normalizedRecent,
        seenIds: normalizedSeen,
        cycleId: cycleId,
      );
    }

    if (canReuseCurrent &&
        currentId != null &&
        currentId.trim().isNotEmpty &&
        !candidateSet.contains(currentId)) {
      warnings.add('$label: ayni gun kayit bulunamadi, yeni secim yapildi.');
    }

    var nextCycleId = cycleId;
    var nextSeen = List<String>.from(normalizedSeen);
    var available = candidateIds.where((id) => !nextSeen.contains(id)).toList();

    if (available.isEmpty) {
      nextCycleId += 1;
      nextSeen = <String>[];
      available = List<String>.from(candidateIds);
      warnings.add('$label: tum adaylar goruldu, cycle reset uygulandi.');
    }

    final recentBlock = normalizedRecent.toSet();
    var preferred = available.where((id) => !recentBlock.contains(id)).toList();
    if (preferred.isEmpty) {
      preferred = available;
      warnings.add('$label: recent disinda aday kalmadi, fallback uygulandi.');
    }

    final pickedId = _pickDeterministicId(
      ids: preferred,
      seedText: '$label|$dayKey|$contentVersion|$nextCycleId',
    );
    if (pickedId == null) {
      warnings.add('$label: secim yapilamadi, null donuldu.');
      return _TypeSelectionOutcome(
        selectedId: null,
        recentIds: normalizedRecent,
        seenIds: nextSeen,
        cycleId: nextCycleId,
      );
    }

    final updatedSeen = _appendUnique(nextSeen, pickedId);
    final updatedRecent = _trimRecent(
      _appendUnique(normalizedRecent, pickedId),
      candidateIds.length,
    );

    return _TypeSelectionOutcome(
      selectedId: pickedId,
      recentIds: updatedRecent,
      seenIds: updatedSeen,
      cycleId: nextCycleId,
    );
  }

  List<String> _retainKnownIds(List<String> ids, Set<String> candidateSet) {
    final result = <String>[];
    for (final id in ids) {
      final trimmed = id.trim();
      if (trimmed.isEmpty || !candidateSet.contains(trimmed)) continue;
      if (!result.contains(trimmed)) {
        result.add(trimmed);
      }
    }
    return result;
  }

  List<String> _appendUnique(List<String> ids, String value) {
    final result = List<String>.from(ids);
    result.remove(value);
    result.add(value);
    return result;
  }

  List<String> _trimRecent(List<String> ids, int candidateCount) {
    final maxWindow = candidateCount <= 1
        ? 0
        : _recentWindow.clamp(1, candidateCount - 1) as int;
    if (maxWindow <= 0) return const <String>[];
    if (ids.length <= maxWindow) return ids;
    return ids.sublist(ids.length - maxWindow);
  }

  String? _pickDeterministicId({
    required List<String> ids,
    required String seedText,
  }) {
    if (ids.isEmpty) return null;
    final seed = _stableHash(seedText);
    final index = seed % ids.length;
    return ids[index];
  }

  int _stableHash(String input) {
    var hash = 2166136261;
    for (var i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }
}

class _TypeSelectionOutcome {
  final String? selectedId;
  final List<String> recentIds;
  final List<String> seenIds;
  final int cycleId;

  const _TypeSelectionOutcome({
    required this.selectedId,
    required this.recentIds,
    required this.seenIds,
    required this.cycleId,
  });
}
