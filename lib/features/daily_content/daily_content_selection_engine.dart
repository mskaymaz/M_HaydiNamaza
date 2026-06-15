import 'daily_content_clock.dart';
import 'daily_content_loader.dart';
import 'daily_content_models.dart';
import 'daily_content_parse_result.dart';
import 'daily_content_selection_models.dart';
import 'daily_content_state_codec.dart';
import 'daily_content_state_repository.dart';

class DailyContentSelectionEngine {
  final DailyContentLoader _loader;
  final DailyContentStateRepository _stateRepository;
  final DailyContentClock _clock;

  DailyContentSelectionEngine({
    DailyContentLoader? loader,
    DailyContentStateRepository? stateRepository,
    DailyContentClock? clock,
    int recentWindow = 7, // kept for constructor compatibility
  }) : _loader = loader ?? DailyContentLoader(),
       _stateRepository = stateRepository ?? DailyContentStateRepository(),
       _clock = clock ?? SystemDailyContentClock();

  Future<DailyContentSelectionResult> selectToday() async {
    return _selectInternal(
      ayahOffset: 0,
      hadithOffset: 0,
      esmaOffset: 0,
      sifatOffset: 0,
    );
  }

  Future<DailyContentSelectionResult> selectPreview({
    int ayahOffset = 0,
    int hadithOffset = 0,
    int esmaOffset = 0,
    int sifatOffset = 0,
  }) async {
    return _selectInternal(
      ayahOffset: ayahOffset,
      hadithOffset: hadithOffset,
      esmaOffset: esmaOffset,
      sifatOffset: sifatOffset,
    );
  }

  Future<DailyContentSelectionResult> _selectInternal({
    required int ayahOffset,
    required int hadithOffset,
    required int esmaOffset,
    required int sifatOffset,
  }) async {
    final warnings = <String>[];
    final now = _clock.now();
    final loadResult = await _loader.loadApprovedSampleContent(
      referenceDate: now,
    );
    warnings.addAll(loadResult.warnings);

    final ayahs = _dedupeAyahRecords(loadResult.ayahs, warnings);
    final hadiths = _dedupeHadithRecords(loadResult.hadiths, warnings);
    final esmas = _dedupeEsmaRecords(loadResult.esmas, warnings, label: 'esma');
    final sifats = _dedupeEsmaRecords(
      loadResult.sifats,
      warnings,
      label: 'sifat',
    );
    final todayKey = _clock.dayKey();

    final startDate = _parseStartDate(loadResult.sequenceStartDate);
    final dayIndex = _dayIndex(startDate, now);
    final ayahId = _idAt(loadResult.ayahOrderIds, dayIndex + ayahOffset);
    final hadithId = _idAt(loadResult.hadithOrderIds, dayIndex + hadithOffset);
    final esmaId = _idAt(loadResult.esmaOrderIds, dayIndex + esmaOffset);
    final sifatId = _idAt(loadResult.sifatOrderIds, dayIndex + sifatOffset);
    final ayahCycleId = _cycleId(
      loadResult.ayahOrderIds,
      dayIndex + ayahOffset,
    );
    final hadithCycleId = _cycleId(
      loadResult.hadithOrderIds,
      dayIndex + hadithOffset,
    );
    final esmaCycleId = _cycleId(
      loadResult.esmaOrderIds,
      dayIndex + esmaOffset,
    );
    final sifatCycleId = _cycleId(
      loadResult.sifatOrderIds,
      dayIndex + sifatOffset,
    );

    final currentState = await _stateRepository.read(warnings: warnings);
    final nextState = currentState.copyWith(
      schemaVersion: DailyContentStateCodec.schemaVersion,
      dayKey: todayKey,
      contentVersion: _buildContentVersion(loadResult),
      ayahId: ayahId,
      clearAyahId: ayahId == null,
      hadithId: hadithId,
      clearHadithId: hadithId == null,
      esmaId: esmaId,
      clearEsmaId: esmaId == null,
      sifatId: sifatId,
      clearSifatId: sifatId == null,
      recentAyahIds: const <String>[],
      recentHadithIds: const <String>[],
      seenAyahIds: const <String>[],
      seenHadithIds: const <String>[],
      ayahCycleId: ayahCycleId,
      hadithCycleId: hadithCycleId,
      esmaCycleId: esmaCycleId,
      sifatCycleId: sifatCycleId,
      updatedAt: now.toIso8601String(),
    );
    await _stateRepository.write(nextState);

    return DailyContentSelectionResult(
      ayah: _findAyahById(ayahs, ayahId),
      hadith: _findHadithById(hadiths, hadithId),
      esma: _findEsmaById(esmas, esmaId),
      sifat: _findEsmaById(sifats, sifatId),
      state: nextState,
      warnings: warnings,
      skippedCount: loadResult.skippedCount,
    );
  }

  String _buildContentVersion(DailyContentLoadResult result) {
    final ayahVersion = (result.ayahContentVersion ?? '').trim();
    final hadithVersion = (result.hadithContentVersion ?? '').trim();
    final esmaVersion = (result.esmaContentVersion ?? '').trim();
    final left = ayahVersion.isEmpty ? 'na' : ayahVersion;
    final middle = hadithVersion.isEmpty ? 'na' : hadithVersion;
    final right = esmaVersion.isEmpty ? 'na' : esmaVersion;
    return '$left|$middle|$right';
  }

  DateTime _parseStartDate(String raw) {
    final value = raw.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return DateTime.utc(2026, 5, 15);
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    return DateTime.utc(year, month, day);
  }

  int _dayIndex(DateTime startDateUtc, DateTime now) {
    final startDay = DateTime.utc(
      startDateUtc.year,
      startDateUtc.month,
      startDateUtc.day,
    );
    final currentDay = DateTime.utc(now.year, now.month, now.day);
    return currentDay.difference(startDay).inDays;
  }

  String? _idAt(List<String> orderedIds, int dayIndex) {
    if (orderedIds.isEmpty) return null;
    final size = orderedIds.length;
    final index = ((dayIndex % size) + size) % size;
    return orderedIds[index];
  }

  int _cycleId(List<String> orderedIds, int dayIndex) {
    if (orderedIds.isEmpty) return 0;
    if (dayIndex < 0) return 0;
    return dayIndex ~/ orderedIds.length;
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

  List<DailyEsmaRecord> _dedupeEsmaRecords(
    List<DailyEsmaRecord> records,
    List<String> warnings, {
    required String label,
  }) {
    final seenIds = <String>{};
    final unique = <DailyEsmaRecord>[];
    for (final record in records) {
      if (seenIds.contains(record.id)) {
        warnings.add('$label duplicate id atlandi: ${record.id}');
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

  DailyEsmaRecord? _findEsmaById(List<DailyEsmaRecord> records, String? id) {
    if (id == null || id.trim().isEmpty) return null;
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }
}
