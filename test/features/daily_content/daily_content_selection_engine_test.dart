import 'package:flutter_test/flutter_test.dart';
import 'package:mhaydinamaza/features/daily_content/daily_content_clock.dart';
import 'package:mhaydinamaza/features/daily_content/daily_content_loader.dart';
import 'package:mhaydinamaza/features/daily_content/daily_content_models.dart';
import 'package:mhaydinamaza/features/daily_content/daily_content_parse_result.dart';
import 'package:mhaydinamaza/features/daily_content/daily_content_selection_engine.dart';
import 'package:mhaydinamaza/features/daily_content/daily_content_selection_models.dart';
import 'package:mhaydinamaza/features/daily_content/daily_content_state_repository.dart';

void main() {
  group('DailyContentSelectionEngine repeat prevention', () {
    test('reuses same pick within same day', () async {
      final clock = _FakeClock(DateTime(2026, 5, 13, 9));
      final repository = _InMemoryStateRepository();
      final engine = DailyContentSelectionEngine(
        loader: _FakeLoader(_sampleLoadResult()),
        stateRepository: repository,
        clock: clock,
        recentWindow: 2,
      );

      final first = await engine.selectToday();
      final second = await engine.selectToday();

      expect(second.ayah?.id, first.ayah?.id);
      expect(second.hadith?.id, first.hadith?.id);
      expect(second.state.ayahCycleId, first.state.ayahCycleId);
      expect(second.state.hadithCycleId, first.state.hadithCycleId);
    });

    test('does not repeat before cycle completes and then increments cycle', () async {
      final clock = _FakeClock(DateTime(2026, 5, 13, 9));
      final repository = _InMemoryStateRepository();
      final engine = DailyContentSelectionEngine(
        loader: _FakeLoader(_sampleLoadResult()),
        stateRepository: repository,
        clock: clock,
        recentWindow: 2,
      );

      final ayahIds = <String>{};
      final hadithIds = <String>{};

      for (var i = 0; i < 3; i++) {
        clock.setNow(DateTime(2026, 5, 13 + i, 9));
        final result = await engine.selectToday();
        ayahIds.add(result.ayah!.id);
        hadithIds.add(result.hadith!.id);
      }

      expect(ayahIds.length, 3);
      expect(hadithIds.length, 3);

      clock.setNow(DateTime(2026, 5, 16, 9));
      final afterCycle = await engine.selectToday();
      expect(afterCycle.state.ayahCycleId, 1);
      expect(afterCycle.state.hadithCycleId, 1);
    });
  });
}

DailyContentLoadResult _sampleLoadResult() {
  const approval = DailyContentApproval(
    approvedBy: 'test_editor',
    approvedAt: '2026-05-13T09:00:00Z',
    reviewNote: 'test',
  );
  return DailyContentLoadResult(
    ayahSchemaVersion: '1.0.0',
    hadithSchemaVersion: '1.0.0',
    ayahContentVersion: 'v-test',
    hadithContentVersion: 'v-test',
    ayahs: const <DailyAyahRecord>[
      DailyAyahRecord(
        id: 'ayah-1',
        type: 'ayah',
        surahName: 'Fatiha',
        surahNumber: 1,
        ayahNumber: 1,
        text: 'Bismillah',
        translation: 'Rahman ve Rahim',
        mealSource: 'test',
        sourceNote: 'test',
        topics: <String>['baslangic'],
        status: 'approved',
        approval: approval,
      ),
      DailyAyahRecord(
        id: 'ayah-2',
        type: 'ayah',
        surahName: 'Bakara',
        surahNumber: 2,
        ayahNumber: 2,
        text: 'Zalik',
        translation: 'Bu kitap',
        mealSource: 'test',
        sourceNote: 'test',
        topics: <String>['iman'],
        status: 'approved',
        approval: approval,
      ),
      DailyAyahRecord(
        id: 'ayah-3',
        type: 'ayah',
        surahName: 'Ikhlas',
        surahNumber: 112,
        ayahNumber: 1,
        text: 'Kul huvallahu',
        translation: 'De ki Allah birdir',
        mealSource: 'test',
        sourceNote: 'test',
        topics: <String>['tevhid'],
        status: 'approved',
        approval: approval,
      ),
    ],
    hadiths: const <DailyHadithRecord>[
      DailyHadithRecord(
        id: 'hadith-1',
        type: 'hadith',
        collection: 'Buhari',
        book: 'Iman',
        hadithNumber: '1',
        narrator: 'Omer',
        text: 'Ameller niyetlere goredir',
        translation: 'Ameller niyetlere gore deger kazanir',
        grade: 'sahih',
        sourceNote: 'test',
        topics: <String>['niyet'],
        status: 'approved',
        approval: approval,
      ),
      DailyHadithRecord(
        id: 'hadith-2',
        type: 'hadith',
        collection: 'Muslim',
        book: 'Birr',
        hadithNumber: '2',
        narrator: 'Ebu Hureyre',
        text: 'Merhamet edenlere merhamet edilir',
        translation: 'Merhamet onemlidir',
        grade: 'sahih',
        sourceNote: 'test',
        topics: <String>['ahlak'],
        status: 'approved',
        approval: approval,
      ),
      DailyHadithRecord(
        id: 'hadith-3',
        type: 'hadith',
        collection: 'Tirmizi',
        book: 'Dua',
        hadithNumber: '3',
        narrator: 'Ali',
        text: 'Dua ibadetin ozudur',
        translation: 'Dua ibadettir',
        grade: 'hasen',
        sourceNote: 'test',
        topics: <String>['dua'],
        status: 'approved',
        approval: approval,
      ),
    ],
    skippedCount: 0,
    warnings: const <String>[],
  );
}

class _FakeLoader extends DailyContentLoader {
  final DailyContentLoadResult _result;

  _FakeLoader(this._result);

  @override
  Future<DailyContentLoadResult> loadApprovedSampleContent() async {
    return _result;
  }
}

class _InMemoryStateRepository extends DailyContentStateRepository {
  DailyContentSelectionState _state = DailyContentSelectionState.empty();

  @override
  Future<DailyContentSelectionState> read({List<String>? warnings}) async {
    return _state;
  }

  @override
  Future<void> write(DailyContentSelectionState state) async {
    _state = state;
  }
}

class _FakeClock extends DailyContentClock {
  DateTime _now;

  _FakeClock(this._now);

  void setNow(DateTime value) {
    _now = value;
  }

  @override
  DateTime now() => _now;
}
