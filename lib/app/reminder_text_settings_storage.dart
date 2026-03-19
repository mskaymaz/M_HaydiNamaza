import 'package:shared_preferences/shared_preferences.dart';

class ReminderTextSettings {
  final String voiceText;
  final String visualText;
  final bool voiceTextEnabled;
  final String? selectedVoiceName;
  final String? selectedVoiceLocale;

  const ReminderTextSettings({
    required this.voiceText,
    required this.visualText,
    required this.voiceTextEnabled,
    this.selectedVoiceName,
    this.selectedVoiceLocale,
  });
}

class ReminderTextSettingsStorage {
  static const String _voiceTextKey = 'reminder_voice_text';
  static const String _visualTextKey = 'reminder_visual_text';
  static const String _voiceTextEnabledKey = 'reminder_voice_text_enabled';
  static const String _selectedVoiceNameKey = 'reminder_selected_voice_name';
  static const String _selectedVoiceLocaleKey = 'reminder_selected_voice_locale';

  Future<ReminderTextSettings> read() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderTextSettings(
      voiceText: prefs.getString(_voiceTextKey) ?? '',
      visualText: prefs.getString(_visualTextKey) ?? '',
      voiceTextEnabled: prefs.getBool(_voiceTextEnabledKey) ?? true,
      selectedVoiceName: prefs.getString(_selectedVoiceNameKey),
      selectedVoiceLocale: prefs.getString(_selectedVoiceLocaleKey),
    );
  }

  Future<void> write(ReminderTextSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceTextKey, settings.voiceText);
    await prefs.setString(_visualTextKey, settings.visualText);
    await prefs.setBool(_voiceTextEnabledKey, settings.voiceTextEnabled);
    if (settings.selectedVoiceName == null || settings.selectedVoiceName!.isEmpty) {
      await prefs.remove(_selectedVoiceNameKey);
    } else {
      await prefs.setString(_selectedVoiceNameKey, settings.selectedVoiceName!);
    }
    if (settings.selectedVoiceLocale == null ||
        settings.selectedVoiceLocale!.isEmpty) {
      await prefs.remove(_selectedVoiceLocaleKey);
    } else {
      await prefs.setString(_selectedVoiceLocaleKey, settings.selectedVoiceLocale!);
    }
  }
}
