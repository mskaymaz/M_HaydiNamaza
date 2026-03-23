import 'package:shared_preferences/shared_preferences.dart';

const kDefaultVoiceReminderText = 'Namaz vakti yaklaşıyor.. Haydı hazırlan...';

enum ReminderAudioMode { textToSpeech, deviceAudio, mp3File }

extension ReminderAudioModeX on ReminderAudioMode {
  String get key {
    switch (this) {
      case ReminderAudioMode.textToSpeech:
        return 'tts';
      case ReminderAudioMode.deviceAudio:
        return 'device_audio';
      case ReminderAudioMode.mp3File:
        return 'mp3';
    }
  }
}

ReminderAudioMode reminderAudioModeFromKey(String? key) {
  switch (key) {
    case 'device_audio':
      return ReminderAudioMode.deviceAudio;
    case 'mp3':
      return ReminderAudioMode.mp3File;
    case 'tts':
    default:
      return ReminderAudioMode.textToSpeech;
  }
}

class ReminderTextSettings {
  final String voiceText;
  final String visualText;
  final ReminderAudioMode audioMode;
  final bool showVoiceIcon;
  final bool showVisualIcon;
  final bool showAzanIcon;
  final bool showVibrationIcon;
  final bool sortCustomPrayersByTime;
  final int voiceRepeatSeconds;
  final int vibrationDurationSeconds;
  final int vibrationPauseSeconds;
  final int visualDisplaySeconds;
  final int visualReopenSeconds;
  final String? selectedVoiceName;
  final String? selectedVoiceLocale;
  final String? selectedAudioPath;
  final String? selectedAudioLabel;

  const ReminderTextSettings({
    required this.voiceText,
    required this.visualText,
    this.audioMode = ReminderAudioMode.textToSpeech,
    this.showVoiceIcon = true,
    this.showVisualIcon = true,
    this.showAzanIcon = true,
    this.showVibrationIcon = true,
    this.sortCustomPrayersByTime = true,
    this.voiceRepeatSeconds = 15,
    this.vibrationDurationSeconds = 3,
    this.vibrationPauseSeconds = 5,
    this.visualDisplaySeconds = 6,
    this.visualReopenSeconds = 4,
    this.selectedVoiceName,
    this.selectedVoiceLocale,
    this.selectedAudioPath,
    this.selectedAudioLabel,
  });

  bool get voiceTextEnabled => audioMode == ReminderAudioMode.textToSpeech;
}

class ReminderTextSettingsStorage {
  static const String _voiceTextKey = 'reminder_voice_text';
  static const String _visualTextKey = 'reminder_visual_text';
  static const String _voiceTextEnabledKey = 'reminder_voice_text_enabled';
  static const String _audioModeKey = 'reminder_audio_mode';
  static const String _showVoiceIconKey = 'reminder_show_voice_icon';
  static const String _showVisualIconKey = 'reminder_show_visual_icon';
  static const String _showAzanIconKey = 'reminder_show_azan_icon';
  static const String _showVibrationIconKey = 'reminder_show_vibration_icon';
  static const String _sortCustomPrayersByTimeKey =
      'sort_custom_prayers_by_time';
  static const String _voiceRepeatSecondsKey = 'reminder_voice_repeat_seconds';
  static const String _vibrationDurationSecondsKey =
      'reminder_vibration_duration_seconds';
  static const String _vibrationPauseSecondsKey =
      'reminder_vibration_pause_seconds';
  static const String _visualDisplaySecondsKey =
      'reminder_visual_display_seconds';
  static const String _visualReopenSecondsKey =
      'reminder_visual_reopen_seconds';
  static const String _selectedVoiceNameKey = 'reminder_selected_voice_name';
  static const String _selectedVoiceLocaleKey =
      'reminder_selected_voice_locale';
  static const String _selectedAudioPathKey = 'reminder_selected_audio_path';
  static const String _selectedAudioLabelKey = 'reminder_selected_audio_label';
  static const _legacyDefaultVoiceTexts = <String>{
    '',
    'Namaz vakti',
    'Namaz vakti yaklaşıyor.. Haydi hazırlan..',
    'Namaz vakti yaklasiyor.. Haydi hazirlan..',
    'Namaz vakti yaklaÅŸÄ±yor.. Haydi hazÄ±rlan..',
  };

  Future<ReminderTextSettings> read() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyVoiceTextEnabled = prefs.getBool(_voiceTextEnabledKey) ?? true;
    final storedAudioMode = prefs.getString(_audioModeKey);
    final storedVoiceText = prefs.getString(_voiceTextKey)?.trim() ?? '';
    final storedVoiceRepeatSeconds = prefs.getInt(_voiceRepeatSecondsKey);
    return ReminderTextSettings(
      voiceText: _legacyDefaultVoiceTexts.contains(storedVoiceText)
          ? kDefaultVoiceReminderText
          : storedVoiceText,
      visualText: prefs.getString(_visualTextKey) ?? '',
      audioMode: storedAudioMode == null
          ? (legacyVoiceTextEnabled
                ? ReminderAudioMode.textToSpeech
                : ReminderAudioMode.deviceAudio)
          : reminderAudioModeFromKey(storedAudioMode),
      showVoiceIcon: prefs.getBool(_showVoiceIconKey) ?? true,
      showVisualIcon: prefs.getBool(_showVisualIconKey) ?? true,
      showAzanIcon: prefs.getBool(_showAzanIconKey) ?? true,
      showVibrationIcon: prefs.getBool(_showVibrationIconKey) ?? true,
      sortCustomPrayersByTime:
          prefs.getBool(_sortCustomPrayersByTimeKey) ?? true,
      voiceRepeatSeconds:
          (storedVoiceRepeatSeconds == null || storedVoiceRepeatSeconds <= 0)
          ? 15
          : storedVoiceRepeatSeconds.clamp(0, 3600),
      vibrationDurationSeconds:
          (prefs.getInt(_vibrationDurationSecondsKey) ?? 3).clamp(1, 3600),
      vibrationPauseSeconds: (prefs.getInt(_vibrationPauseSecondsKey) ?? 5)
          .clamp(0, 3600),
      visualDisplaySeconds: (prefs.getInt(_visualDisplaySecondsKey) ?? 6).clamp(
        1,
        3600,
      ),
      visualReopenSeconds: (prefs.getInt(_visualReopenSecondsKey) ?? 4).clamp(
        0,
        3600,
      ),
      selectedVoiceName: prefs.getString(_selectedVoiceNameKey),
      selectedVoiceLocale: prefs.getString(_selectedVoiceLocaleKey),
      selectedAudioPath: prefs.getString(_selectedAudioPathKey),
      selectedAudioLabel: prefs.getString(_selectedAudioLabelKey),
    );
  }

  Future<void> write(ReminderTextSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceTextKey, settings.voiceText);
    await prefs.setString(_visualTextKey, settings.visualText);
    await prefs.setBool(_voiceTextEnabledKey, settings.voiceTextEnabled);
    await prefs.setString(_audioModeKey, settings.audioMode.key);
    await prefs.setBool(_showVoiceIconKey, settings.showVoiceIcon);
    await prefs.setBool(_showVisualIconKey, settings.showVisualIcon);
    await prefs.setBool(_showAzanIconKey, settings.showAzanIcon);
    await prefs.setBool(_showVibrationIconKey, settings.showVibrationIcon);
    await prefs.setBool(
      _sortCustomPrayersByTimeKey,
      settings.sortCustomPrayersByTime,
    );
    await prefs.setInt(_voiceRepeatSecondsKey, settings.voiceRepeatSeconds);
    await prefs.setInt(
      _vibrationDurationSecondsKey,
      settings.vibrationDurationSeconds,
    );
    await prefs.setInt(
      _vibrationPauseSecondsKey,
      settings.vibrationPauseSeconds,
    );
    await prefs.setInt(_visualDisplaySecondsKey, settings.visualDisplaySeconds);
    await prefs.setInt(_visualReopenSecondsKey, settings.visualReopenSeconds);
    if (settings.selectedVoiceName == null ||
        settings.selectedVoiceName!.isEmpty) {
      await prefs.remove(_selectedVoiceNameKey);
    } else {
      await prefs.setString(_selectedVoiceNameKey, settings.selectedVoiceName!);
    }
    if (settings.selectedVoiceLocale == null ||
        settings.selectedVoiceLocale!.isEmpty) {
      await prefs.remove(_selectedVoiceLocaleKey);
    } else {
      await prefs.setString(
        _selectedVoiceLocaleKey,
        settings.selectedVoiceLocale!,
      );
    }
    if (settings.selectedAudioPath == null ||
        settings.selectedAudioPath!.isEmpty) {
      await prefs.remove(_selectedAudioPathKey);
    } else {
      await prefs.setString(_selectedAudioPathKey, settings.selectedAudioPath!);
    }
    if (settings.selectedAudioLabel == null ||
        settings.selectedAudioLabel!.isEmpty) {
      await prefs.remove(_selectedAudioLabelKey);
    } else {
      await prefs.setString(
        _selectedAudioLabelKey,
        settings.selectedAudioLabel!,
      );
    }
  }
}
