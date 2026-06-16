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
    _setHomeState(() {
      _future = _loadData();
    });
    unawaited(_refreshNativeReminderSchedule());
  }

  Future<void> _openQibla(LocationData? location) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HomeQiblaScreen(location: location)),
    );
  }

  String _combinedDateLabel(DateTime date, AppLocalizations l10n) {
    final hijri =
        '${homeFormatHijriDayMonth(date, l10n)} ${homeFormatHijriYear(date)}';
    final gregorian =
        '${homeFormatGregorianDayMonth(date, l10n)} '
        '${homeFormatGregorianYear(date, l10n)}';
    return '$hijri / $gregorian';
  }

  Future<void> _openLocationSettings(LocationData? location) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LocationScreen(
          initial: location,
          uiPaletteController: widget.uiPaletteController,
        ),
      ),
    );
    if (!mounted) return;
    _setHomeState(() {
      _future = _loadData();
    });
  }
}
