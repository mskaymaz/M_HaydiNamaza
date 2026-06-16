import 'daily_content_clock.dart';
import 'daily_content_loader.dart';
import 'daily_content_selection_engine.dart';
import 'daily_content_selection_models.dart';
import 'daily_content_state_repository.dart';

class DailyContentService {
  final DailyContentStateRepository _stateRepository;
  final DailyContentSelectionEngine _selectionEngine;

  DailyContentService({
    DailyContentLoader? loader,
    DailyContentStateRepository? stateRepository,
    DailyContentClock? clock,
    int recentWindow = 7,
  }) : this._(
         loader: loader ?? DailyContentLoader(enableRemote: true),
         stateRepository: stateRepository ?? DailyContentStateRepository(),
         clock: clock ?? SystemDailyContentClock(),
         recentWindow: recentWindow,
       );

  DailyContentService._({
    required DailyContentLoader loader,
    required DailyContentStateRepository stateRepository,
    required DailyContentClock clock,
    required int recentWindow,
  }) : _stateRepository = stateRepository,
       _selectionEngine = DailyContentSelectionEngine(
         loader: loader,
         stateRepository: stateRepository,
         clock: clock,
         recentWindow: recentWindow,
       );

  Future<DailyContentSelectionResult> loadToday() async {
    try {
      final result = await _selectionEngine.selectToday();
      final warnings = List<String>.from(result.warnings);

      if (result.ayah == null) {
        warnings.add(
          'daily_content_service: ayah seçilemedi (boş veya geçersiz içerik).',
        );
      }
      if (result.hadith == null) {
        warnings.add(
          'daily_content_service: hadith seçilemedi (boş veya geçersiz içerik).',
        );
      }
      if (result.esma == null) {
        warnings.add(
          'daily_content_service: esma seçilemedi (boş veya geçersiz içerik).',
        );
      }
      if (result.sifat == null) {
        warnings.add(
          'daily_content_service: sifat seçilemedi (boş veya geçersiz içerik).',
        );
      }

      if (warnings.length == result.warnings.length) {
        return result;
      }

      return DailyContentSelectionResult(
        ayah: result.ayah,
        hadith: result.hadith,
        esma: result.esma,
        sifat: result.sifat,
        state: result.state,
        warnings: warnings,
        skippedCount: result.skippedCount,
      );
    } catch (_) {
      final warnings = <String>[
        'daily_content_service: günlük içerik seçimi başarısız, fallback state kullanıldı.',
      ];
      final fallbackState = await _stateRepository.read(warnings: warnings);
      return DailyContentSelectionResult(
        ayah: null,
        hadith: null,
        state: fallbackState,
        warnings: warnings,
        skippedCount: 0,
      );
    }
  }

  Future<DailyContentSelectionResult> loadPreview({
    int ayahOffset = 0,
    int hadithOffset = 0,
    int esmaOffset = 0,
    int sifatOffset = 0,
  }) async {
    return _selectionEngine.selectPreview(
      ayahOffset: ayahOffset,
      hadithOffset: hadithOffset,
      esmaOffset: esmaOffset,
      sifatOffset: sifatOffset,
    );
  }
}
