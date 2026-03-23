import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'reminder_text_settings_storage.dart';

class ReminderVoiceOption {
  final String name;
  final String locale;

  const ReminderVoiceOption({
    required this.name,
    required this.locale,
  });

  String get key => '$locale|$name';
  String get label => '$name ($locale)';
}

class ReminderAudioService {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<List<ReminderVoiceOption>> loadVoiceOptions() async {
    dynamic voices;
    try {
      voices = await _flutterTts.getVoices;
    } catch (_) {
      return const [];
    }
    if (voices is! List) return const [];
    final options = <ReminderVoiceOption>[];
    for (final item in voices) {
      if (item is! Map) continue;
      final name = (item['name'] ?? '').toString().trim();
      final locale = (item['locale'] ?? '').toString().trim();
      if (name.isEmpty || locale.isEmpty) continue;
      options.add(ReminderVoiceOption(name: name, locale: locale));
    }
    options.sort((a, b) => a.label.compareTo(b.label));
    return options;
  }

  Future<void> playReminder({
    required ReminderTextSettings settings,
    required Locale? selectedLocale,
    required String prayerLabel,
  }) async {
    switch (settings.audioMode) {
      case ReminderAudioMode.textToSpeech:
        final trimmed = settings.voiceText.trim();
        final spokenText = trimmed.isEmpty ? '$prayerLabel vakti.' : '$prayerLabel vakti. $trimmed';
        await _speakWithFallback(
          spokenText,
          selectedLocale: selectedLocale,
          selectedVoiceName: settings.selectedVoiceName,
          selectedVoiceLocale: settings.selectedVoiceLocale,
        );
        return;
      case ReminderAudioMode.deviceAudio:
      case ReminderAudioMode.mp3File:
        final audioPath = settings.selectedAudioPath?.trim() ?? '';
        if (audioPath.isEmpty) {
          throw Exception('audio_file_missing');
        }
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(audioPath));
        return;
    }
  }

  Future<void> playAlert() async {
    await SystemSound.play(SystemSoundType.alert);
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
  }

  Future<void> _applyPreferredVoice({
    required Locale? selectedLocale,
    String? selectedVoiceName,
    String? selectedVoiceLocale,
  }) async {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final locale = selectedLocale ?? deviceLocale;
    final localeKey = locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}-${locale.countryCode}';
    try {
      await _flutterTts.setLanguage(selectedVoiceLocale ?? localeKey);
    } catch (_) {
      try {
        await _flutterTts.setLanguage(locale.languageCode);
      } catch (_) {}
    }
    if ((selectedVoiceName ?? '').isNotEmpty &&
        (selectedVoiceLocale ?? '').isNotEmpty) {
      try {
        await _flutterTts.setVoice({
          'name': selectedVoiceName!,
          'locale': selectedVoiceLocale!,
        });
        return;
      } catch (_) {}
    }
    dynamic voices;
    try {
      voices = await _flutterTts.getVoices;
    } catch (_) {
      return;
    }
    if (voices is! List) return;
    Map<String, dynamic>? matchedVoice;
    for (final voice in voices) {
      if (voice is! Map) continue;
      final name = (voice['name'] ?? '').toString().toLowerCase();
      final localeName = (voice['locale'] ?? '').toString().toLowerCase();
      final sameLocale =
          localeName.startsWith(locale.languageCode.toLowerCase());
      if (!sameLocale) continue;
      if (name.contains('male') ||
          name.contains('erkek') ||
          name.contains('man')) {
        matchedVoice = Map<String, dynamic>.from(voice);
        break;
      }
      matchedVoice ??= Map<String, dynamic>.from(voice);
    }
    if (matchedVoice == null) return;
    try {
      await _flutterTts.setVoice({
        'name': (matchedVoice['name'] ?? '').toString(),
        'locale': (matchedVoice['locale'] ?? localeKey).toString(),
      });
    } catch (_) {}
  }

  Future<void> _speakWithFallback(
    String spokenText, {
    required Locale? selectedLocale,
    String? selectedVoiceName,
    String? selectedVoiceLocale,
  }) async {
    await _flutterTts.stop();
    try {
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (_) {}
    try {
      await _applyPreferredVoice(
        selectedLocale: selectedLocale,
        selectedVoiceName: selectedVoiceName,
        selectedVoiceLocale: selectedVoiceLocale,
      );
    } catch (_) {}
    try {
      await _flutterTts.setPitch(0.95);
    } catch (_) {}
    try {
      await _flutterTts.setSpeechRate(0.45);
    } catch (_) {}
    final result = await _flutterTts.speak(spokenText);
    if (result == 1 || result == null) {
      return;
    }
    await _flutterTts.setVoice(const <String, String>{});
    final retry = await _flutterTts.speak(spokenText);
    if (retry == 1 || retry == null) {
      return;
    }
    throw Exception('tts_failed');
  }
}
