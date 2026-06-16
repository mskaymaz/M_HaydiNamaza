part of 'home_screen.dart';

extension _HomeSettingsPersistenceController on _HomeScreenState {
  _PrayerRowSettings _settingsFor(Prayer prayer) {
    return _rowSettings.putIfAbsent(prayer, () {
      final minutes = _defaultReminderMinutes(prayer);
      _reminderControllers.putIfAbsent(
        prayer,
        () => TextEditingController(text: minutes.toString()),
      );
      return _PrayerRowSettings(reminderMinutes: minutes);
    });
  }

  Future<void> _loadPrayerRowSettings() async {
    final saved = await _rowSettingsStorage.read();
    if (!mounted || saved.isEmpty) return;
    _setHomeState(() {
      for (final entry in saved.entries) {
        _rowSettings[entry.key] = _PrayerRowSettings(
          reminderMinutes: entry.value.reminderMinutes,
          voiceEnabled: entry.value.voiceEnabled,
          visualEnabled: entry.value.visualEnabled,
          azanEnabled: entry.value.azanEnabled,
          vibrationEnabled: entry.value.vibrationEnabled,
        );
        final controller = _reminderControllers[entry.key];
        if (controller != null) {
          controller.text = entry.value.reminderMinutes.toString();
        }
      }
    });
    unawaited(_refreshNativeReminderSchedule());
  }

  Future<void> _loadCustomPrayerRows() async {
    final saved = await _customPrayerStorage.read();
    if (!mounted || saved.isEmpty) return;
    final loadedRows = <_CustomPrayerDraft>[];
    var maxSeed = _customPrayerSeed;
    for (final record in saved) {
      final manualTime =
          record.manualHour == null || record.manualMinute == null
          ? null
          : TimeOfDay(hour: record.manualHour!, minute: record.manualMinute!);
      loadedRows.add(
        _CustomPrayerDraft(
          id: record.id,
          labelController: TextEditingController(text: record.label),
          reminderController: TextEditingController(
            text: record.reminderMinutes.toString(),
          ),
          settings: _PrayerRowSettings(
            reminderMinutes: record.reminderMinutes,
            voiceEnabled: record.voiceEnabled,
            visualEnabled: record.visualEnabled,
            azanEnabled: record.azanEnabled,
            vibrationEnabled: record.vibrationEnabled,
          ),
          timeRule: _CustomPrayerTimeRule(
            mode: _customPrayerTimeModeFromKey(record.timeMode),
            anchorPrayer: record.anchorPrayer,
            secondaryAnchorPrayer: record.secondaryAnchorPrayer,
            offsetMinutes: record.offsetMinutes,
            manualTime: manualTime,
          ),
        ),
      );
      final match = RegExp(r'^nafile_(\d+)$').firstMatch(record.id);
      final seed = int.tryParse(match?.group(1) ?? '');
      if (seed != null && seed >= maxSeed) {
        maxSeed = seed + 1;
      }
    }
    _setHomeState(() {
      _customPrayerRows
        ..clear()
        ..addAll(loadedRows);
      _customPrayerSeed = maxSeed;
    });
    unawaited(_refreshNativeReminderSchedule());
  }

  Future<void> _persistCustomPrayerRows() async {
    final payload = _customPrayerRows.map((row) {
      return CustomPrayerRecord(
        id: row.id,
        label: row.labelController.text.trim(),
        reminderMinutes: row.settings.reminderMinutes,
        voiceEnabled: row.settings.voiceEnabled,
        visualEnabled: row.settings.visualEnabled,
        azanEnabled: row.settings.azanEnabled,
        vibrationEnabled: row.settings.vibrationEnabled,
        timeMode: row.timeRule.mode.name,
        anchorPrayer: row.timeRule.anchorPrayer,
        secondaryAnchorPrayer: row.timeRule.secondaryAnchorPrayer,
        offsetMinutes: row.timeRule.offsetMinutes,
        manualHour: row.timeRule.manualTime?.hour,
        manualMinute: row.timeRule.manualTime?.minute,
      );
    }).toList();
    await _customPrayerStorage.write(payload);
    unawaited(_refreshNativeReminderSchedule());
  }

  Future<void> _persistPrayerRowSettings() async {
    final payload = <Prayer, PrayerRowSettingsRecord>{};
    for (final entry in _rowSettings.entries) {
      payload[entry.key] = PrayerRowSettingsRecord(
        reminderMinutes: entry.value.reminderMinutes,
        voiceEnabled: entry.value.voiceEnabled,
        visualEnabled: entry.value.visualEnabled,
        azanEnabled: entry.value.azanEnabled,
        vibrationEnabled: entry.value.vibrationEnabled,
      );
    }
    await _rowSettingsStorage.write(payload);
    unawaited(_refreshNativeReminderSchedule());
  }

  int _defaultReminderMinutes(Prayer prayer) {
    return prayer == Prayer.sunrise ? 0 : 15;
  }

  TextEditingController _controllerFor(Prayer prayer) {
    final settings = _settingsFor(prayer);
    return _reminderControllers.putIfAbsent(
      prayer,
      () => TextEditingController(text: settings.reminderMinutes.toString()),
    );
  }
}
