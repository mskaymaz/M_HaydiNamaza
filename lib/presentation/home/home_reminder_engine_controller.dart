part of 'home_screen.dart';

extension _HomeReminderEngineController on _HomeScreenState {
  Future<void> _checkAndTriggerReminders(
    PrayerTimes times,
    AppLocalizations l10n,
  ) async {
    if (_reminderCheckInProgress || !mounted) return;
    _reminderCheckInProgress = true;
    try {
      final now = _now;
      final prayerTimes = <Prayer, DateTime>{
        Prayer.fajr: _atToday(times.fajr, now),
        Prayer.sunrise: _atToday(times.sunrise, now),
        Prayer.dhuhr: _atToday(times.dhuhr, now),
        Prayer.asr: _atToday(times.asr, now),
        Prayer.maghrib: _atToday(times.maghrib, now),
        Prayer.isha: _atToday(times.isha, now),
      };
      for (final entry in prayerTimes.entries) {
        await _checkRowReminderTriggers(
          rowId: entry.key.name,
          prayerLabel: _prayerLabel(entry.key, l10n),
          settings: _settingsFor(entry.key),
          prayerTime: entry.value,
          now: now,
        );
      }
      for (final row in _customPrayerRows) {
        final customTime = _resolveCustomPrayerTime(row.timeRule, times);
        if (customTime == null) continue;
        final label = row.labelController.text.trim().isEmpty
            ? 'Nafile'
            : row.labelController.text.trim();
        await _checkRowReminderTriggers(
          rowId: row.id,
          prayerLabel: label,
          settings: row.settings,
          prayerTime: customTime,
          now: now,
        );
      }
    } finally {
      _reminderCheckInProgress = false;
    }
  }

  Future<void> _checkRowReminderTriggers({
    required String rowId,
    required String prayerLabel,
    required _PrayerRowSettings settings,
    required DateTime prayerTime,
    required DateTime now,
  }) async {
    final reminderTime = prayerTime.subtract(
      Duration(minutes: settings.reminderMinutes.clamp(0, 1440)),
    );
    final reminderKey = _rowTriggerKey(
      rowId,
      'reminder',
      reminderTime,
      prayerTime,
    );
    final reminderId = _rowTriggerId(rowId, 'reminder');
    if ((settings.voiceEnabled || settings.vibrationEnabled) &&
        _isWithinTriggerWindow(now, reminderTime) &&
        _triggerLog[reminderId] != reminderKey) {
      await _triggerReminderForLabel(
        prayerLabel: prayerLabel,
        rowSettings: settings,
        stage: _ReminderStage.reminder,
        prayerTime: prayerTime,
      );
      _triggerLog[reminderId] = reminderKey;
      await _reminderTriggerStorage.write(_triggerLog);
    }

    final prayerKey = _rowTriggerKey(rowId, 'prayer', prayerTime, prayerTime);
    final prayerId = _rowTriggerId(rowId, 'prayer');
    if ((settings.azanEnabled || settings.vibrationEnabled) &&
        _isWithinTriggerWindow(now, prayerTime) &&
        _triggerLog[prayerId] != prayerKey) {
      await _triggerReminderForLabel(
        prayerLabel: prayerLabel,
        rowSettings: settings,
        stage: _ReminderStage.prayer,
        prayerTime: prayerTime,
      );
      _triggerLog[prayerId] = prayerKey;
      await _reminderTriggerStorage.write(_triggerLog);
    }
  }

  bool _isWithinTriggerWindow(DateTime now, DateTime triggerTime) {
    return !now.isBefore(triggerTime) &&
        now.isBefore(triggerTime.add(const Duration(minutes: 1)));
  }

  Future<void> _refreshNativeReminderSchedule() async {
    if (_nativeScheduleRefreshInProgress) {
      _nativeScheduleRefreshPending = true;
      return;
    }
    _nativeScheduleRefreshInProgress = true;
    try {
      final schedule = await _buildNativeReminderSchedule();
      await _nativeNotificationScheduler.ensurePermissions();
      await _nativeNotificationScheduler.configure(schedule.notifications);
      await _nativeNotificationScheduler.configureWidget(schedule.widgetEvents);
    } catch (_) {
      try {
        await _nativeNotificationScheduler.cancelAll();
      } catch (_) {}
    } finally {
      _nativeScheduleRefreshInProgress = false;
      if (_nativeScheduleRefreshPending) {
        _nativeScheduleRefreshPending = false;
        unawaited(_refreshNativeReminderSchedule());
      }
    }
  }

  Future<_NativeReminderSchedule> _buildNativeReminderSchedule() async {
    final location = await _locationStorage.read();
    if (location == null) {
      return const _NativeReminderSchedule(notifications: [], widgetEvents: []);
    }

    var methodCode = await _methodStorage.readCode();
    methodCode ??= CalculationMethodStorage.defaultCode;
    final latitude = double.tryParse(location.latitude);
    final longitude = double.tryParse(location.longitude);
    if ((methodCode != 'turkey' && methodCode != 'diyanet' && methodCode != 'diyanet_tabanli') &&
        (latitude == null || longitude == null)) {
      return const _NativeReminderSchedule(notifications: [], widgetEvents: []);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifications = <NativePrayerNotificationEvent>[];
    final widgetEvents = <NativePrayerWidgetEvent>[];
    final times = await _prayerService.calculateToday(
      location: location,
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      timeZone: location.timeZoneOffset,
      methodCode: methodCode,
    );
    _appendNativeStandardPrayerEvents(
      notifications: notifications,
      widgetEvents: widgetEvents,
      times: times,
      now: now,
    );
    final tomorrow = today.add(const Duration(days: 1));
    final tomorrowTimes = await _prayerService.calculateForDate(
      location: location,
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      timeZone: location.timeZoneOffset,
      methodCode: methodCode,
      date: tomorrow,
      allowDiyanet: false,
      allowRemote: true,
    );
    _appendNativeWidgetEvents(
      widgetEvents,
      <Prayer, DateTime>{
        Prayer.fajr: tomorrowTimes.fajr,
        Prayer.sunrise: tomorrowTimes.sunrise,
        Prayer.dhuhr: tomorrowTimes.dhuhr,
        Prayer.asr: tomorrowTimes.asr,
        Prayer.maghrib: tomorrowTimes.maghrib,
        Prayer.isha: tomorrowTimes.isha,
      },
      now,
    );
    _appendNativeCustomPrayerEvents(notifications, times, now);
    return _NativeReminderSchedule(
      notifications: notifications,
      widgetEvents: widgetEvents,
    );
  }

  void _appendNativeStandardPrayerEvents({
    required List<NativePrayerNotificationEvent> notifications,
    required List<NativePrayerWidgetEvent> widgetEvents,
    required PrayerTimes times,
    required DateTime now,
  }) {
    final prayerTimes = <Prayer, DateTime>{
      Prayer.fajr: times.fajr,
      Prayer.sunrise: times.sunrise,
      Prayer.dhuhr: times.dhuhr,
      Prayer.asr: times.asr,
      Prayer.maghrib: times.maghrib,
      Prayer.isha: times.isha,
    };
    _appendNativeWidgetEvents(widgetEvents, prayerTimes, now);
    for (final entry in prayerTimes.entries) {
      final settings = _settingsFor(entry.key);
      final label = _turkishPrayerLabel(entry.key);
      _appendNativeEventsForRow(
        events: notifications,
        now: now,
        baseId: entry.key.index + 1,
        label: label,
        prayerTime: entry.value,
        settings: settings,
      );
    }
  }

  void _appendNativeWidgetEvents(
    List<NativePrayerWidgetEvent> widgetEvents,
    Map<Prayer, DateTime> prayerTimes,
    DateTime now,
  ) {
    NativePrayerWidgetEvent widgetEvent(Prayer prayer, DateTime time) {
      return NativePrayerWidgetEvent(
        triggerAt: time,
        prayerLabel: _turkishPrayerLabel(prayer),
        dateLabel: _turkishWidgetDateLabel(time),
        fajrTime: homeFormatTime(prayerTimes[Prayer.fajr]!),
        sunriseTime: homeFormatTime(prayerTimes[Prayer.sunrise]!),
        dhuhrTime: homeFormatTime(prayerTimes[Prayer.dhuhr]!),
        asrTime: homeFormatTime(prayerTimes[Prayer.asr]!),
        maghribTime: homeFormatTime(prayerTimes[Prayer.maghrib]!),
        ishaTime: homeFormatTime(prayerTimes[Prayer.isha]!),
      );
    }

    for (final entry in prayerTimes.entries) {
      if (!entry.value.isAfter(now)) continue;
      widgetEvents.add(widgetEvent(entry.key, entry.value));
    }
  }

  String _turkishWidgetDateLabel(DateTime date) {
    final l10n = AppLocalizations.of(context);
    if (l10n != null) {
      return _combinedDateLabel(date, l10n);
    }
    const months = <String>[
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final month = months[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  void _appendNativeCustomPrayerEvents(
    List<NativePrayerNotificationEvent> events,
    PrayerTimes times,
    DateTime now,
  ) {
    for (var index = 0; index < _customPrayerRows.length; index++) {
      final row = _customPrayerRows[index];
      final prayerTime = _resolveCustomPrayerTimeForDate(
        row.timeRule,
        times,
        times.fajr,
      );
      if (prayerTime == null) continue;
      final label = row.labelController.text.trim().isEmpty
          ? 'Nafile'
          : row.labelController.text.trim();
      _appendNativeEventsForRow(
        events: events,
        now: now,
        baseId: 100 + index,
        label: label,
        prayerTime: prayerTime,
        settings: row.settings,
      );
    }
  }

  void _appendNativeEventsForRow({
    required List<NativePrayerNotificationEvent> events,
    required DateTime now,
    required int baseId,
    required String label,
    required DateTime prayerTime,
    required _PrayerRowSettings settings,
  }) {
    if (settings.voiceEnabled || settings.vibrationEnabled) {
      final reminderTime = prayerTime.subtract(
        Duration(minutes: settings.reminderMinutes.clamp(0, 1440)),
      );
      if (reminderTime.isAfter(now)) {
        events.add(
          _nativeEvent(
            baseId: baseId,
            triggerAt: reminderTime,
            prayerLabel: label,
            stage: 'reminder',
            voiceEnabled: settings.voiceEnabled,
            visualEnabled: false,
            azanEnabled: false,
            vibrationEnabled: settings.vibrationEnabled,
          ),
        );
      }
    }
    if (settings.azanEnabled || settings.vibrationEnabled) {
      if (prayerTime.isAfter(now)) {
        events.add(
          _nativeEvent(
            baseId: baseId,
            triggerAt: prayerTime,
            prayerLabel: label,
            stage: 'prayer',
            voiceEnabled: false,
            visualEnabled: false,
            azanEnabled: settings.azanEnabled,
            vibrationEnabled: settings.vibrationEnabled,
          ),
        );
      }
    }
  }

  NativePrayerNotificationEvent _nativeEvent({
    required int baseId,
    required DateTime triggerAt,
    required String prayerLabel,
    required String stage,
    required bool voiceEnabled,
    required bool visualEnabled,
    required bool azanEnabled,
    required bool vibrationEnabled,
  }) {
    final stageOffset = stage == 'prayer' ? 5000 : 0;
    final dayId =
        DateTime(
          triggerAt.year,
          triggerAt.month,
          triggerAt.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    final id = (dayId * 10000) + stageOffset + baseId;
    final isPrayerStage = stage == 'prayer';
    final title = isPrayerStage
        ? '$prayerLabel vakti'
        : '$prayerLabel vakti yakla\u015f\u0131yor';
    final fallbackMessage = isPrayerStage
        ? '$prayerLabel vakti girdi.'
        : _effectiveReminderMessage(prayerLabel);
    return NativePrayerNotificationEvent(
      id: id,
      triggerAt: triggerAt,
      prayerLabel: prayerLabel,
      stage: stage,
      title: title,
      message: fallbackMessage,
      voiceEnabled: voiceEnabled,
      visualEnabled: visualEnabled,
      azanEnabled: azanEnabled,
      vibrationEnabled: vibrationEnabled,
      vibrationDurationMs: _reminderSettings.vibrationDurationSeconds * 1000,
    );
  }

  String _turkishPrayerLabel(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return '\u0130msak';
      case Prayer.sunrise:
        return 'G\u00fcne\u015f';
      case Prayer.dhuhr:
        return '\u00d6\u011fle';
      case Prayer.asr:
        return '\u0130kindi';
      case Prayer.maghrib:
        return 'Ak\u015fam';
      case Prayer.isha:
        return 'Yats\u0131';
      case Prayer.none:
        return 'Vakit';
    }
  }

  Future<void> _triggerReminderForLabel({
    required String prayerLabel,
    required _PrayerRowSettings rowSettings,
    required _ReminderStage stage,
    required DateTime prayerTime,
  }) async {
    if (stage == _ReminderStage.prayer) {
      _stopVoiceLoop();
    }
    if (rowSettings.vibrationEnabled) {
      await _playVibrationPulse(
        _reminderSettings.vibrationDurationSeconds * 1000,
      );
      if (stage == _ReminderStage.reminder) {
        _startVibrationLoop(prayerLabel: prayerLabel, prayerTime: prayerTime);
      }
    }
    if (stage == _ReminderStage.prayer && rowSettings.azanEnabled) {
      await _reminderAudioService.playAzan();
    }
    if (stage == _ReminderStage.reminder &&
        rowSettings.voiceEnabled &&
        _canPlayVoiceReminder()) {
      try {
        await _reminderAudioService.playReminder(
          settings: _reminderSettings,
          selectedLocale: widget.localeController.value,
          prayerLabel: prayerLabel,
        );
        _startVoiceLoop(prayerLabel: prayerLabel, prayerTime: prayerTime);
      } catch (_) {}
    }
  }

  bool _canPlayVoiceReminder() {
    switch (_reminderSettings.audioMode) {
      case ReminderAudioMode.textToSpeech:
        return true;
      case ReminderAudioMode.deviceAudio:
      case ReminderAudioMode.mp3File:
        return (_reminderSettings.selectedAudioPath ?? '').trim().isNotEmpty;
    }
  }

  String _effectiveReminderMessage(String prayerLabel) {
    final voiceText = _reminderSettings.voiceText.trim();
    if (voiceText.isNotEmpty) return voiceText;
    return '$prayerLabel vakti';
  }

  String _rowTriggerId(String rowId, String stage) => '$rowId|$stage';

  String _rowTriggerKey(
    String rowId,
    String stage,
    DateTime reminderTime,
    DateTime prayerTime,
  ) {
    String two(int value) => value.toString().padLeft(2, '0');
    final reminderStamp =
        '${reminderTime.year}${two(reminderTime.month)}${two(reminderTime.day)}'
        '${two(reminderTime.hour)}${two(reminderTime.minute)}';
    final prayerStamp = '${two(prayerTime.hour)}${two(prayerTime.minute)}';
    return '$rowId|$stage|$reminderStamp|$prayerStamp';
  }

}
