part of 'settings_screen.dart';

extension _SettingsReminderController on _SettingsScreenState {
  void _syncBackgroundDraftWithPalette(UiPaletteConfig palette) {
    final hasDraft = _draftBackgroundColor != null;
    if (!hasDraft || !_hasPendingBackgroundChanges(palette)) {
      _setBackgroundDraftFromPalette(palette);
    }
  }

  bool _hasPendingBackgroundChanges(UiPaletteConfig palette) {
    final draftBackgroundColor =
        _draftBackgroundColor ?? palette.backgroundZeminColor;

    return draftBackgroundColor != palette.backgroundZeminColor;
  }

  void _setBackgroundDraftFromPalette(UiPaletteConfig palette) {
    _draftBackgroundColor = palette.backgroundZeminColor;
  }

  Future<void> _applyBackgroundDraft() async {
    final palette = widget.uiPaletteController.value;
    final updated = palette.copyWith(
      backgroundZeminColor:
          _draftBackgroundColor ?? palette.backgroundZeminColor,
    );
    await widget.uiPaletteController.setPalette(updated);
    if (!mounted) return;
    setState(() {
      _setBackgroundDraftFromPalette(updated);
    });
  }

  Future<void> _editColor({
    required BuildContext context,
    required String title,
    required Color initialColor,
    required Future<void> Function(Color color) onApply,
  }) async {
    await showSettingsColorPickerDialog(
      context: context,
      title: title,
      initialColor: initialColor,
      onApply: onApply,
      onApplied: () {
        if (!mounted) return;
        setState(() {});
      },
    );
  }

  Future<void> _pickReminderAudio(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: _selectedAudioMode == ReminderAudioMode.mp3File
          ? FileType.custom
          : FileType.audio,
      allowedExtensions: _selectedAudioMode == ReminderAudioMode.mp3File
          ? const ['mp3']
          : null,
    );
    final file = result == null || result.files.isEmpty
        ? null
        : result.files.first;
    final path = file?.path?.trim() ?? '';
    if (path.isEmpty) return;
    setState(() {
      _selectedAudioPath = path;
      _selectedAudioLabel = file?.name ?? path.split('\\').last;
    });
    await _persistReminderTexts();
  }

  Future<void> _persistReminderTexts() async {
    await _reminderTextStorage.write(_currentReminderSettingsSnapshot());
  }

  Future<void> _playVoiceReminderTest(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (_reminderAudioService.isSpeaking || _reminderAudioService.isPlayingAudio) {
      await _reminderAudioService.stop();
      return;
    }
    final settings = _currentReminderSettingsSnapshot();
    if (settings.audioMode != ReminderAudioMode.textToSpeech &&
        (settings.selectedAudioPath?.trim().isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test için önce bir ses dosyası seçin.')),
      );
      return;
    }
    try {
      await _reminderAudioService.playReminder(
        settings: settings,
        selectedLocale: widget.localeController.value,
        prayerLabel: l10n.prayerDhuhr,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesli test başlatılamadı.')),
      );
    }
  }

  ReminderTextSettings _currentReminderSettingsSnapshot() {
    return buildReminderSettingsSnapshot(
      voiceText: _voiceReminderController.text,
      visualText: _visualReminderController.text,
      audioMode: _selectedAudioMode,
      showVoiceIcon: _showVoiceIcon,
      showVisualIcon: _showVisualIcon,
      showAzanIcon: _showAzanIcon,
      showVibrationIcon: _showVibrationIcon,
      prayerSilenceEnabled: _prayerSilenceEnabled,
      prayerSilenceStartMinutesText:
          _prayerSilenceStartMinutesController.text,
      prayerSilenceDurationMinutesText:
          _prayerSilenceDurationMinutesController.text,
      sortCustomPrayersByTime: _sortCustomPrayersByTime,
      showHelpBalloons: _showHelpBalloons,
      voiceRepeatSecondsText: _voiceRepeatController.text,
      vibrationDurationSecondsText: _vibrationDurationController.text,
      vibrationPauseSecondsText: _vibrationPauseController.text,
      visualDisplaySecondsText: _visualDisplayController.text,
      visualReopenSecondsText: _visualReopenController.text,
      selectedVoiceName:
          _selectedVoiceName ?? ReminderAudioService.defaultTurkishVoiceName,
      selectedVoiceLocale:
          _selectedVoiceLocale ??
          ReminderAudioService.defaultTurkishVoiceLocale,
      selectedEnglishVoiceName: _selectedEnglishVoiceName,
      selectedEnglishVoiceLocale: _selectedEnglishVoiceLocale,
      selectedArabicVoiceName: _selectedArabicVoiceName,
      selectedArabicVoiceLocale: _selectedArabicVoiceLocale,
      selectedAudioPath: _selectedAudioPath,
      selectedAudioLabel: _selectedAudioLabel,
    );
  }
}
