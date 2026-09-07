part of 'home_screen.dart';

extension _HomeNavigationController on _HomeScreenState {
  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          localeController: widget.localeController,
          uiPaletteController: widget.uiPaletteController,
        ),
      ),
    );
    await _loadReminderSettings();
    await _loadKerahatSettings();
    _setHomeState(() {
      _future = _loadData();
    });
    unawaited(_refreshNativeReminderSchedule());
  }

  Future<void> _openQibla(LocationData? location) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeQiblaScreen(
          location: location,
          showHelpBalloons: _reminderSettings.showHelpBalloons,
        ),
      ),
    );
  }

  String _combinedDateLabel(
    DateTime date,
    AppLocalizations l10n, {
    String? diyanetHijriText,
  }) {
    final hijri = diyanetHijriText != null && diyanetHijriText.trim().isNotEmpty
        ? diyanetHijriText.trim()
        : '${homeFormatHijriDayMonth(date, l10n)} ${homeFormatHijriYear(date)}';
    final gregorian =
        '${homeFormatGregorianDayMonth(date, l10n)} '
        '${homeFormatGregorianYear(date, l10n)}';
    return '$hijri / $gregorian';
  }

  Future<void> _openLocationSettings(LocationData? location) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LocationScreen(
          initial: location,
          uiPaletteController: widget.uiPaletteController,
          showHelpBalloons: _reminderSettings.showHelpBalloons,
        ),
      ),
    );
    if (!mounted) return;
    _setHomeState(() {
      if (changed == true) {
        _prayerDayOffset = 0;
        _prayerDayCache.clear();
        _prayerDayCacheSignature = null;
        _prayerTableMode = _PrayerTableMode.none;
        _prayerTableRange = null;
        _prayerTableFuture = null;
      }
      _future = _loadData();
    });
    // Location changes may be persisted without returning an explicit
    // `true` result, for example after a manual district selection followed by
    // the Android back button. Always rebuild the native schedule after the
    // location screen closes so home widgets receive the latest saved location.
    unawaited(_refreshNativeReminderSchedule());
  }
}
