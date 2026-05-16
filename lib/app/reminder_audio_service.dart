import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'reminder_text_settings_storage.dart';

class ReminderVoiceOption {
  final String name;
  final String locale;

  const ReminderVoiceOption({required this.name, required this.locale});

  String get key => '$locale|$name';
  String get label => '$name ($locale)';
}

class ReminderAudioService {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const String defaultTurkishVoiceName = 'tr-tr-x-tmc-network';
  static const String defaultTurkishVoiceLocale = 'tr-TR';
  static const double _stableTtsPitch = 1.0;
  static const double _stableTtsRate = 0.52;
  static const double _stableTtsVolume = 1.0;
  static const Duration _ttsRestartGap = Duration(milliseconds: 80);
  static const Duration _ttsDebounce = Duration(milliseconds: 400);
  bool _ttsInProgress = false;
  DateTime? _lastTtsStartAt;

  Future<List<ReminderVoiceOption>> loadVoiceOptions({
    bool onlyTurkishMale = false,
  }) async {
    return _loadVoiceOptionsInternal(onlyTurkishMale: onlyTurkishMale);
  }

  Future<List<ReminderVoiceOption>> _loadVoiceOptionsInternal({
    required bool onlyTurkishMale,
  }) async {
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
      if (onlyTurkishMale) {
        // Heuristic: locale starts with tr and voice looks male
        final normalized = Map<String, dynamic>.from(item);
        final voiceLocale = (normalized['locale'] ?? '')
            .toString()
            .toLowerCase();
        if (!voiceLocale.startsWith('tr')) continue;
        if (!_voiceLooksMale(normalized)) continue;
      }
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
        final spokenText = trimmed.isEmpty
            ? '$prayerLabel vakti.'
            : '$prayerLabel vakti. $trimmed';
        await _speakWithFallback(spokenText, selectedLocale: selectedLocale);
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
    _ttsInProgress = false;
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    _ttsInProgress = false;
  }

  Future<void> _applyPreferredVoice({required Locale? selectedLocale}) async {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final locale = selectedLocale ?? deviceLocale;
    final localeKey = locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}-${locale.countryCode}';
    try {
      await _flutterTts.setLanguage(defaultTurkishVoiceLocale);
    } catch (_) {
      try {
        await _flutterTts.setLanguage(localeKey);
      } catch (_) {}
    }
    try {
      await _flutterTts.setVoice(const {
        'name': defaultTurkishVoiceName,
        'locale': defaultTurkishVoiceLocale,
      });
      return;
    } catch (_) {}
    dynamic voices;
    try {
      voices = await _flutterTts.getVoices;
    } catch (_) {
      return;
    }
    if (voices is! List) return;
    final matchedVoice = _pickBestFallbackVoice(voices: voices, locale: locale);
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
  }) async {
    final now = DateTime.now();
    final last = _lastTtsStartAt;
    if (_ttsInProgress) return;
    if (last != null && now.difference(last) < _ttsDebounce) return;

    _ttsInProgress = true;
    _lastTtsStartAt = now;
    try {
      await _flutterTts.stop();
      await Future<void>.delayed(_ttsRestartGap);
      try {
        await _flutterTts.awaitSpeakCompletion(true);
      } catch (_) {}
      try {
        await _flutterTts.setQueueMode(0);
      } catch (_) {}
      try {
        await _applyPreferredVoice(selectedLocale: selectedLocale);
      } catch (_) {}
      try {
        await _flutterTts.setVolume(_stableTtsVolume);
      } catch (_) {}
      try {
        await _flutterTts.setPitch(_stableTtsPitch);
      } catch (_) {}
      try {
        await _flutterTts.setSpeechRate(_stableTtsRate);
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
    } finally {
      _ttsInProgress = false;
    }
  }

  Map<String, dynamic>? _pickBestFallbackVoice({
    required List voices,
    required Locale locale,
  }) {
    final localeCode = locale.languageCode.toLowerCase();
    final localeVoices = <Map<String, dynamic>>[];
    for (final voice in voices) {
      if (voice is! Map) continue;
      final normalized = Map<String, dynamic>.from(voice);
      final voiceLocale = (normalized['locale'] ?? '').toString().toLowerCase();
      if (voiceLocale.startsWith(localeCode)) {
        localeVoices.add(normalized);
      }
    }
    if (localeVoices.isEmpty) return null;

    if (localeCode == 'tr') {
      for (final voice in localeVoices) {
        final key = _voiceCompositeKey(voice);
        if (key.contains(defaultTurkishVoiceName.toLowerCase())) {
          return voice;
        }
      }
    }

    for (final voice in localeVoices) {
      if (_voiceLooksMale(voice)) {
        return voice;
      }
    }
    return localeVoices.first;
  }

  String _voiceCompositeKey(Map<String, dynamic> voice) {
    final name = (voice['name'] ?? '').toString().toLowerCase();
    final locale = (voice['locale'] ?? '').toString().toLowerCase();
    final identifier = (voice['identifier'] ?? '').toString().toLowerCase();
    final shortName = (voice['shortName'] ?? '').toString().toLowerCase();
    return '$locale|$name|$identifier|$shortName';
  }

  bool _voiceLooksMale(Map<String, dynamic> voice) {
    final key = _voiceCompositeKey(voice);
    final gender = (voice['gender'] ?? '').toString().toLowerCase();
    return key.contains('male') ||
        key.contains('erkek') ||
        key.contains('man') ||
        gender == 'male';
  }
}
