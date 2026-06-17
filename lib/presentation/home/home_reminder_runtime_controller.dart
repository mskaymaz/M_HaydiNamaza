part of 'home_screen.dart';

extension _HomeReminderRuntimeController on _HomeScreenState {
  Future<void> _loadReminderTriggerLog() async {
    final saved = await _reminderTriggerStorage.read();
    _triggerLog
      ..clear()
      ..addAll(saved);
  }

  void _stopVoiceLoop() {
    _voiceRepeatTimer?.cancel();
    _voiceRepeatTimer = null;
    if (_voiceLoopUntil != null || _voiceLoopPrayerLabel != null) {
      _setHomeState(() {
        _voiceLoopUntil = null;
        _voiceLoopPrayerLabel = null;
      });
    }
  }

  void _stopVibrationLoop() {
    _vibrationRepeatTimer?.cancel();
    _vibrationRepeatTimer = null;
    if (_vibrationLoopUntil != null || _vibrationLoopPrayerLabel != null) {
      _setHomeState(() {
        _vibrationLoopUntil = null;
        _vibrationLoopPrayerLabel = null;
      });
    }
  }

  void _dismissVoiceReminder() {
    _stopVoiceLoop();
    _stopVibrationLoop();
  }

  void _startVoiceLoop({
    required String prayerLabel,
    required DateTime prayerTime,
  }) {
    _stopVoiceLoop();
    final repeatSeconds = _reminderSettings.voiceRepeatSeconds;
    if (repeatSeconds <= 0) return;
    _setHomeState(() {
      _voiceLoopUntil = prayerTime;
      _voiceLoopPrayerLabel = prayerLabel;
    });
    _voiceRepeatTimer = Timer.periodic(Duration(seconds: repeatSeconds), (
      _,
    ) async {
      if (!mounted ||
          _voiceLoopUntil == null ||
          DateTime.now().isAfter(_voiceLoopUntil!) ||
          !_canPlayVoiceReminder()) {
        _stopVoiceLoop();
        return;
      }
      try {
        await _reminderAudioService.playReminder(
          settings: _reminderSettings,
          selectedLocale: widget.localeController.value,
          prayerLabel: prayerLabel,
        );
      } catch (_) {}
    });
  }

  void _startVibrationLoop({
    required String prayerLabel,
    required DateTime prayerTime,
  }) {
    _vibrationRepeatTimer?.cancel();
    final vibrationOnMilliseconds =
        _reminderSettings.vibrationDurationSeconds * 1000;
    final vibrationRepeatMilliseconds =
        (_reminderSettings.vibrationPauseSeconds * 1000).clamp(1, 3600000);
    _setHomeState(() {
      _vibrationLoopUntil = prayerTime;
      _vibrationLoopPrayerLabel = prayerLabel;
    });
    _vibrationRepeatTimer = Timer.periodic(
      Duration(milliseconds: vibrationRepeatMilliseconds),
      (_) async {
        if (!mounted ||
            _vibrationLoopUntil == null ||
            DateTime.now().isAfter(_vibrationLoopUntil!)) {
          _stopVibrationLoop();
          return;
        }
        await _playVibrationPulse(vibrationOnMilliseconds);
      },
    );
  }

  Future<void> _playVibrationPulse(int durationMilliseconds) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(duration: durationMilliseconds);
        return;
      }
    } catch (_) {}
    await HapticFeedback.mediumImpact();
  }
}
