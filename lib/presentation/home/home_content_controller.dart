part of 'home_screen.dart';

extension _HomeContentController on _HomeScreenState {
  Future<void> _loadReminderSettings() async {
    final settings = await _reminderTextStorage.read();
    if (!mounted) {
      _reminderSettings = settings;
      return;
    }
    _setHomeState(() {
      _reminderSettings = settings;
    });
    unawaited(_refreshNativeReminderSchedule());
  }

  void _resetDailyContentPreviewOffsets() {
    _dailyContentAyahOffset = 0;
    _dailyContentHadithOffset = 0;
    _dailyContentEsmaOffset = 0;
    _dailyContentSifatOffset = 0;
  }

  Future<void> _cycleDailyContent(DailyContentPanelKind kind) async {
    _setHomeState(() {
      switch (kind) {
        case DailyContentPanelKind.ayah:
          _dailyContentAyahOffset += 1;
          break;
        case DailyContentPanelKind.hadith:
          _dailyContentHadithOffset += 1;
          break;
        case DailyContentPanelKind.esma:
          _dailyContentEsmaOffset += 1;
          break;
        case DailyContentPanelKind.sifat:
          _dailyContentSifatOffset += 1;
          break;
      }
      _dailyContentFuture = _dailyContentService.loadPreview(
        ayahOffset: _dailyContentAyahOffset,
        hadithOffset: _dailyContentHadithOffset,
        esmaOffset: _dailyContentEsmaOffset,
        sifatOffset: _dailyContentSifatOffset,
      );
    });
  }
}
