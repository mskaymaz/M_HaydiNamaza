import '../../app/reminder_text_settings_storage.dart';

class ReminderTextSettingsMapperInput {
  final String voiceText;
  final String visualText;
  final ReminderAudioMode audioMode;
  final bool showVoiceIcon;
  final bool showVisualIcon;
  final bool showAzanIcon;
  final bool showVibrationIcon;
  final bool sortCustomPrayersByTime;
  final String voiceRepeatSecondsText;
  final String vibrationDurationSecondsText;
  final String vibrationPauseSecondsText;
  final String visualDisplaySecondsText;
  final String visualReopenSecondsText;
  final String? selectedVoiceName;
  final String? selectedVoiceLocale;
  final String? selectedEnglishVoiceName;
  final String? selectedEnglishVoiceLocale;
  final String? selectedArabicVoiceName;
  final String? selectedArabicVoiceLocale;
  final String? selectedAudioPath;
  final String? selectedAudioLabel;

  const ReminderTextSettingsMapperInput({
    required this.voiceText,
    required this.visualText,
    required this.audioMode,
    required this.showVoiceIcon,
    required this.showVisualIcon,
    required this.showAzanIcon,
    required this.showVibrationIcon,
    required this.sortCustomPrayersByTime,
    required this.voiceRepeatSecondsText,
    required this.vibrationDurationSecondsText,
    required this.vibrationPauseSecondsText,
    required this.visualDisplaySecondsText,
    required this.visualReopenSecondsText,
    this.selectedVoiceName,
    this.selectedVoiceLocale,
    this.selectedEnglishVoiceName,
    this.selectedEnglishVoiceLocale,
    this.selectedArabicVoiceName,
    this.selectedArabicVoiceLocale,
    this.selectedAudioPath,
    this.selectedAudioLabel,
  });
}

ReminderTextSettings mapReminderTextSettings(
  ReminderTextSettingsMapperInput input,
) {
  return ReminderTextSettings(
    voiceText: input.voiceText.trim(),
    visualText: input.visualText.trim(),
    audioMode: input.audioMode,
    showVoiceIcon: input.showVoiceIcon,
    showVisualIcon: input.showVisualIcon,
    showAzanIcon: input.showAzanIcon,
    showVibrationIcon: input.showVibrationIcon,
    sortCustomPrayersByTime: input.sortCustomPrayersByTime,
    voiceRepeatSeconds: readReminderSeconds(
      input.voiceRepeatSecondsText,
      fallback: 15,
    ),
    vibrationDurationSeconds: readReminderSeconds(
      input.vibrationDurationSecondsText,
      fallback: 3,
    ),
    vibrationPauseSeconds: readReminderSeconds(
      input.vibrationPauseSecondsText,
      fallback: 5,
    ),
    visualDisplaySeconds: readReminderSeconds(
      input.visualDisplaySecondsText,
      fallback: 6,
    ),
    visualReopenSeconds: readReminderSeconds(
      input.visualReopenSecondsText,
      fallback: 4,
    ),
    selectedVoiceName: input.selectedVoiceName,
    selectedVoiceLocale: input.selectedVoiceLocale,
    selectedEnglishVoiceName: input.selectedEnglishVoiceName,
    selectedEnglishVoiceLocale: input.selectedEnglishVoiceLocale,
    selectedArabicVoiceName: input.selectedArabicVoiceName,
    selectedArabicVoiceLocale: input.selectedArabicVoiceLocale,
    selectedAudioPath: input.selectedAudioPath,
    selectedAudioLabel: input.selectedAudioLabel,
  );
}

int readReminderSeconds(String input, {required int fallback}) {
  final parsed = int.tryParse(input.trim());
  if (parsed == null) return fallback;
  if (fallback == 0) {
    return parsed.clamp(0, 3600);
  }
  return parsed.clamp(1, 3600);
}
