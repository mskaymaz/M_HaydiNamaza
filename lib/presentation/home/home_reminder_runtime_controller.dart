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

  void _stopVisualLoop() {
    _visualCycleTimer?.cancel();
    _visualCycleTimer = null;
    if (_visualLoopUntil != null ||
        _visualLoopPrayerLabel != null ||
        _visualLoopMessage != null ||
        _showVisualOverlay) {
      _setHomeState(() {
        _visualLoopUntil = null;
        _visualLoopPrayerLabel = null;
        _visualLoopMessage = null;
        _showVisualOverlay = false;
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

  void _dismissVisualReminder() {
    _stopVisualLoop();
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

  void _startVisualLoop({
    required String prayerLabel,
    required String message,
    required DateTime prayerTime,
  }) {
    _stopVisualLoop();
    _setHomeState(() {
      _visualLoopUntil = prayerTime;
      _visualLoopPrayerLabel = prayerLabel;
      _visualLoopMessage = message;
      _showVisualOverlay = true;
    });
    _scheduleVisualPhase(isVisible: true);
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

  void _scheduleVisualPhase({required bool isVisible}) {
    _visualCycleTimer?.cancel();
    final until = _visualLoopUntil;
    if (!mounted || until == null || DateTime.now().isAfter(until)) {
      _stopVisualLoop();
      return;
    }
    final seconds = isVisible
        ? _reminderSettings.visualDisplaySeconds
        : _reminderSettings.visualReopenSeconds;
    if (!isVisible && seconds <= 0) {
      _setHomeState(() {
        _showVisualOverlay = true;
      });
      _scheduleVisualPhase(isVisible: true);
      return;
    }
    _visualCycleTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted ||
          _visualLoopUntil == null ||
          DateTime.now().isAfter(_visualLoopUntil!)) {
        _stopVisualLoop();
        return;
      }
      _setHomeState(() {
        _showVisualOverlay = !isVisible;
      });
      _scheduleVisualPhase(isVisible: !isVisible);
    });
  }
}
