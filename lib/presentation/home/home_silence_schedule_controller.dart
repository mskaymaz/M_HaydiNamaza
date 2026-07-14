part of 'home_screen.dart';

extension _HomeSilenceScheduleController on _HomeScreenState {
  NativePrayerNotificationEvent _nativeEvent({
    required int baseId,
    required DateTime triggerAt,
    required String prayerLabel,
    required String stage,
    required bool voiceEnabled,
    required bool visualEnabled,
    required bool azanEnabled,
    required bool vibrationEnabled,
    String? azanFilePath,
    bool silentModeEvent = false,
  }) {
    final stageOffset = switch (stage) {
      'prayer' => 5000,
      'silence_start' => 10000,
      'silence_end' => 15000,
      _ => 0,
    };
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
      azanFilePath: azanFilePath,
      vibrationEnabled: vibrationEnabled,
      vibrationDurationMs: _reminderSettings.vibrationDurationSeconds * 1000,
      silentModeEvent: silentModeEvent,
    );
  }

  Future<void> _appendFutureNativeSilenceEvents({
    required List<NativePrayerNotificationEvent> notifications,
    required LocationData location,
    required String methodCode,
    required DateTime firstDate,
    required DateTime now,
  }) async {
    if (!_reminderSettings.prayerSilenceEnabled) return;
    final latitude = double.tryParse(location.latitude) ?? 0;
    final longitude = double.tryParse(location.longitude) ?? 0;
    for (var offset = 1; offset < prayerTimesPrefetchDays; offset += 1) {
      final date = firstDate.add(Duration(days: offset));
      try {
        final times = await _prayerService.calculateForDate(
          location: location,
          latitude: latitude,
          longitude: longitude,
          timeZone: location.timeZoneOffset,
          methodCode: methodCode,
          date: date,
          allowDiyanet:
              methodCode == 'diyanet' || methodCode == 'diyanet_tabanli',
          allowRemote: true,
        );
        final prayerTimes = <Prayer, DateTime>{
          Prayer.fajr: times.fajr,
          Prayer.sunrise: times.sunrise,
          Prayer.dhuhr: times.dhuhr,
          Prayer.asr: times.asr,
          Prayer.maghrib: times.maghrib,
          Prayer.isha: times.isha,
        };
        for (final entry in prayerTimes.entries) {
          final settings = _settingsFor(entry.key);
          if (!settings.silentEnabled) continue;
          _appendNativeSilenceEventsForRow(
            events: notifications,
            baseId: entry.key.index + 1,
            label: _turkishPrayerLabel(entry.key),
            prayerTime: entry.value,
            settings: settings,
            now: now,
          );
        }
      } catch (_) {
        // Keep already scheduled dates when a later date is unavailable.
      }
    }
  }

  void _appendNativeSilenceEventsForRow({
    required List<NativePrayerNotificationEvent> events,
    required int baseId,
    required String label,
    required DateTime prayerTime,
    required _PrayerRowSettings settings,
    required DateTime now,
  }) {
    if (!settings.silentEnabled) return;
    final start = prayerTime.subtract(
      Duration(minutes: _reminderSettings.prayerSilenceStartMinutes.clamp(0, 1440)),
    );
    final end = start.add(
      Duration(
        minutes: _reminderSettings.prayerSilenceDurationMinutes.clamp(1, 1440),
      ),
    );
    if (start.isAfter(now)) {
      events.add(
        _nativeEvent(
          baseId: baseId,
          triggerAt: start,
          prayerLabel: label,
          stage: 'silence_start',
          voiceEnabled: false,
          visualEnabled: false,
          azanEnabled: false,
          vibrationEnabled: false,
          silentModeEvent: true,
        ),
      );
    }
    if (end.isAfter(now)) {
      events.add(
        _nativeEvent(
          baseId: baseId,
          triggerAt: end,
          prayerLabel: label,
          stage: 'silence_end',
          voiceEnabled: false,
          visualEnabled: false,
          azanEnabled: false,
          vibrationEnabled: false,
          silentModeEvent: true,
        ),
      );
    }
  }
}
