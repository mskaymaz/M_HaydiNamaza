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
  static const double _arabicTtsRate = 0.45;
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

  /// Return a list of composite keys for available voices in format 'locale|name'.
  Future<List<String>> availableVoiceKeys() async {
    dynamic voices;
    try {
      voices = await _flutterTts.getVoices;
    } catch (_) {
      return const [];
    }
    if (voices is! List) return const [];
    final keys = <String>[];
    for (final item in voices) {
      if (item is! Map) continue;
      final name = (item['name'] ?? '').toString().trim();
      final locale = (item['locale'] ?? '').toString().trim();
      if (name.isEmpty || locale.isEmpty) continue;
      keys.add('$locale|$name');
    }
    keys.sort();
    return keys;
  }

  /// Check if a composite key 'locale|name' exists among device voices.
  Future<bool> voiceKeyExists(String compositeKey) async {
    final keys = await availableVoiceKeys();
    return keys.contains(compositeKey);
  }

  /// Persist given english/arabic voice choices and apply them immediately
  /// if they exist on the device.
  Future<void> saveSelectedLanguageVoices({
    String? englishVoiceLocale,
    String? englishVoiceName,
    String? arabicVoiceLocale,
    String? arabicVoiceName,
  }) async {
    try {
      final storage = ReminderTextSettingsStorage();
      await storage.writeSelectedLanguageVoices(
        englishVoiceLocale: englishVoiceLocale,
        englishVoiceName: englishVoiceName,
        arabicVoiceLocale: arabicVoiceLocale,
        arabicVoiceName: arabicVoiceName,
      );
      debugPrint('[TTS] Saved selected language voices to storage');

      // Try to apply immediately if present on device
      if (englishVoiceLocale != null && englishVoiceName != null) {
        final key = '\$englishVoiceLocale|\$englishVoiceName';
        final exists = await voiceKeyExists(key);
        if (exists) {
          try {
            // set normalized English language before applying
            try {
              final langLocale = _localeFromTag(englishVoiceLocale);
              final norm = _normalizeLocale(langLocale);
              await _flutterTts.setLanguage(_localeTag(norm).toLowerCase());
            } catch (_) {}
            await _flutterTts.setVoice({
              'name': englishVoiceName,
              'locale': englishVoiceLocale,
            });
            debugPrint('[TTS] Applied English voice immediately: $key');
          } catch (e) {
            debugPrint('[TTS] Failed to apply English voice immediately: $e');
          }
        } else {
          debugPrint('[TTS] English voice not present on device: $key');
        }
      }

      if (arabicVoiceLocale != null && arabicVoiceName != null) {
        final key = '\$arabicVoiceLocale|\$arabicVoiceName';
        final exists = await voiceKeyExists(key);
        if (exists) {
          try {
            // Force Arabic language tag to a region-specific variant first
            try {
              await _flutterTts.setLanguage('ar-SA');
            } catch (_) {}
            await _flutterTts.setVoice({
              'name': arabicVoiceName,
              'locale': arabicVoiceLocale,
            });
            debugPrint('[TTS] Applied Arabic voice immediately: $key');
          } catch (e) {
            debugPrint('[TTS] Failed to apply Arabic voice immediately: $e');
          }
        } else {
          debugPrint('[TTS] Arabic voice not present on device: $key');
        }
      }
    } catch (e) {
      debugPrint('[TTS] Error saving/appling selected language voices: $e');
    }
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
        await _speakWithFallback(
          _normalizeTurkishSpeechText(
            spokenText,
            selectedLocale: selectedLocale,
          ),
          selectedLocale: selectedLocale,
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

  Future<void> speakText({required String text, Locale? selectedLocale}) async {
    final spokenText = text.trim();
    if (spokenText.isEmpty) return;
    await _speakWithFallback(
      _normalizeTurkishSpeechText(
        spokenText,
        selectedLocale: selectedLocale,
      ),
      selectedLocale: selectedLocale,
    );
  }

  /// Speak with an explicit voice selection (name + locale). If [voiceName]
  /// is null the method will attempt to apply preferred voice for [selectedLocale].
  Future<void> speakTextWithVoice({
    required String text,
    String? voiceName,
    String? voiceLocale,
    Locale? selectedLocale,
  }) async {
    final spokenText = text.trim();
    if (spokenText.isEmpty) return;
    final normalizedText = _normalizeTurkishSpeechText(
      spokenText,
      selectedLocale: selectedLocale,
      voiceLocale: voiceLocale,
    );
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
        if (voiceLocale != null) {
          try {
            // Try to set language to the provided voiceLocale first.
            await _flutterTts.setLanguage(voiceLocale);
          } catch (_) {}
        } else {
          try {
            await _flutterTts.setLanguage(
                selectedLocale?.toLanguageTag() ?? WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag());
          } catch (_) {}
        }
      } catch (_) {}
      try {
        if (voiceName != null) {
          // If a voice name is provided, try to resolve the exact device
          // voice entry to get a more specific locale and apply language
          // normalization. This helps avoid letter-by-letter reading.
          try {
            final resolved = await _findVoiceByName(voiceName);
            if (resolved != null) {
              final resolvedLocale = (resolved['locale'] ?? '').toString();
              if (resolvedLocale.isNotEmpty) {
                try {
                  await _flutterTts.setLanguage(resolvedLocale);
                } catch (_) {}
              }
            }
          } catch (_) {}

          await _flutterTts.setVoice({
            'name': voiceName,
            'locale': voiceLocale ?? (selectedLocale?.toLanguageTag() ?? ''),
          });
        } else {
          await _applyPreferredVoice(selectedLocale: selectedLocale);
        }
      } catch (_) {}
      try {
        await _flutterTts.setVolume(_stableTtsVolume);
      } catch (_) {}
      try {
        await _flutterTts.setPitch(_stableTtsPitch);
      } catch (_) {}
      try {
        await _flutterTts.setSpeechRate(
          _speechRateForLocale(selectedLocale, voiceLocale: voiceLocale),
        );
      } catch (_) {}
      // If Arabic, try SSML first and fallback to chunked speaking.
      final langTag = (voiceLocale ?? selectedLocale?.toLanguageTag() ?? '').toLowerCase();
      if (langTag.startsWith('ar')) {
        final ok = await _speakArabicTextRobust(spokenText);
        if (ok) return;
      }

      final result = await _flutterTts.speak(normalizedText);
      if (result == 1 || result == null) {
        return;
      }
      await _flutterTts.setVoice(const <String, String>{});
      final retry = await _flutterTts.speak(normalizedText);
      if (retry == 1 || retry == null) {
        return;
      }
      throw Exception('tts_failed');
    } finally {
      _ttsInProgress = false;
    }
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
    final locale = _normalizeLocale(selectedLocale ?? deviceLocale);
    final localeKey = locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}-${locale.countryCode}';
    try {
      await _flutterTts.setLanguage(localeKey);
    } catch (_) {
      try {
        await _flutterTts.setLanguage(defaultTurkishVoiceLocale);
      } catch (_) {}
    }
    // For Turkish prefer the known bundled voice name. For other locales
    // first check if the user has stored explicit English/Arabic voice choices
    // and apply them if available. Otherwise rely on the fallback picker
    // which prefers male voices for the locale.
    if (locale.languageCode.toLowerCase() == 'tr') {
      try {
        await _flutterTts.setVoice(const {
          'name': defaultTurkishVoiceName,
          'locale': defaultTurkishVoiceLocale,
        });
        return;
      } catch (_) {}
    }

    try {
      // read stored settings and apply explicit en/ar voices if present
      final storage = ReminderTextSettingsStorage();
      final stored = await storage.read();
      final lang = locale.languageCode.toLowerCase();
      if (lang == 'en' && stored.selectedEnglishVoiceName != null && stored.selectedEnglishVoiceLocale != null) {
        final key = '${stored.selectedEnglishVoiceLocale}|${stored.selectedEnglishVoiceName}';
        final exists = await voiceKeyExists(key);
        if (exists) {
          try {
            debugPrint('[TTS] Applying stored English voice: $key');
            // ensure language is set for English to a normalized locale
            try {
              final langLocale = _localeFromTag(stored.selectedEnglishVoiceLocale!);
              final norm = _normalizeLocale(langLocale);
              await _flutterTts.setLanguage(_localeTag(norm).toLowerCase());
            } catch (_) {}
            await _flutterTts.setVoice({
              'name': stored.selectedEnglishVoiceName!,
              'locale': stored.selectedEnglishVoiceLocale!,
            });
            return;
          } catch (e) {
            debugPrint('[TTS] Failed to set stored English voice: $e');
          }
        } else {
          debugPrint('[TTS] Stored English voice not found on device: $key');
        }
      }
      if (lang == 'ar' && stored.selectedArabicVoiceName != null && stored.selectedArabicVoiceLocale != null) {
        final key = '${stored.selectedArabicVoiceLocale}|${stored.selectedArabicVoiceName}';
        final exists = await voiceKeyExists(key);
        if (exists) {
          try {
            debugPrint('[TTS] Applying stored Arabic voice: $key');
            // Force Arabic language to a region-specific tag to avoid
            // letter-by-letter reading in some engines.
            try {
              await _flutterTts.setLanguage('ar-SA');
            } catch (_) {}
            await _flutterTts.setVoice({
              'name': stored.selectedArabicVoiceName!,
              'locale': stored.selectedArabicVoiceLocale!,
            });
            return;
          } catch (e) {
            debugPrint('[TTS] Failed to set stored Arabic voice: $e');
          }
        } else {
          debugPrint('[TTS] Stored Arabic voice not found on device: $key');
        }
      }
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
      final appliedName = (matchedVoice['name'] ?? '').toString();
      final appliedLocale = (matchedVoice['locale'] ?? localeKey).toString();
      debugPrint('[TTS] Falling back to picked voice: $appliedLocale|$appliedName');
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
        await _flutterTts.setSpeechRate(_speechRateForLocale(selectedLocale));
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
    final localeTag = _localeTag(locale).toLowerCase();
    final preferredTags = _preferredLocaleTags(localeCode);
    final localeVoices = <Map<String, dynamic>>[];
    final preferredVoices = <Map<String, dynamic>>[];
    for (final voice in voices) {
      if (voice is! Map) continue;
      final normalized = Map<String, dynamic>.from(voice);
      final voiceLocale = (normalized['locale'] ?? '').toString().toLowerCase();
      if (voiceLocale.startsWith(localeCode)) {
        localeVoices.add(normalized);
        if (voiceLocale == localeTag || preferredTags.contains(voiceLocale)) {
          preferredVoices.add(normalized);
        }
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

    for (final voice in preferredVoices) {
      if (_voiceLooksMale(voice)) {
        return voice;
      }
    }

    for (final voice in localeVoices) {
      if (_voiceLooksMale(voice)) {
        return voice;
      }
    }
    return localeVoices.first;
  }

  String _localeTag(Locale locale) {
    final countryCode = locale.countryCode;
    if (countryCode == null || countryCode.isEmpty) {
      return locale.languageCode;
    }
    return '${locale.languageCode}-$countryCode';
  }

  List<String> _preferredLocaleTags(String localeCode) {
    switch (localeCode) {
      case 'en':
        return const [
          'en-us',
          'en-gb',
          'en-au',
          'en-ca',
          'en-in',
        ];
      case 'ar':
        return const [
          'ar-sa',
          'ar-eg',
          'ar-ae',
          'ar-jo',
        ];
      default:
        return const [];
    }
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

  Locale _normalizeLocale(Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    final countryCode = locale.countryCode;
    if (countryCode != null && countryCode.isNotEmpty) {
      return locale;
    }
    switch (languageCode) {
      case 'ar':
        return const Locale('ar', 'SA');
      case 'en':
        return const Locale('en', 'US');
      case 'tr':
        return const Locale('tr', 'TR');
      default:
        return locale;
    }
  }

  String _normalizeTurkishSpeechText(
    String text, {
    Locale? selectedLocale,
    String? voiceLocale,
  }) {
    final localeTag = (voiceLocale ?? selectedLocale?.toLanguageTag() ?? '')
        .toLowerCase();
    final languageCode = localeTag.split(RegExp('[-_]')).first;
    final fallbackLanguageCode =
        (selectedLocale ?? WidgetsBinding.instance.platformDispatcher.locale)
            .languageCode
            .toLowerCase();
    final isTurkish = languageCode == 'tr' || fallbackLanguageCode == 'tr';
    if (!isTurkish) {
      return text;
    }

    var normalized = text;
    normalized = normalized.replaceAll(
      RegExp(r'\(\s*ra\s*\)', caseSensitive: false),
      'radiyallahu anhu',
    );
    normalized = normalized.replaceAll(
      RegExp(r'\bHz\.', caseSensitive: false),
      'Hazreti',
    );
    normalized = normalized.replaceAll(
      RegExp(r'\bb\.(?=\s|$)', caseSensitive: true),
      'Bin',
    );
    return normalized;
  }

  double _speechRateForLocale(Locale? locale, {String? voiceLocale}) {
    final localeTag = (voiceLocale ?? locale?.toLanguageTag() ?? WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag())
        .toLowerCase();
    final languageCode = localeTag.split(RegExp('[-_]')).first;
    if (languageCode == 'ar') {
      return _arabicTtsRate;
    }
    final fallbackLanguageCode = (locale ?? WidgetsBinding.instance.platformDispatcher.locale)
        .languageCode
        .toLowerCase();
    if (fallbackLanguageCode == 'ar') {
      return _arabicTtsRate;
    }
    return _stableTtsRate;
  }

  Locale _localeFromTag(String tag) {
    if (tag.isEmpty) return WidgetsBinding.instance.platformDispatcher.locale;
    final parts = tag.split(RegExp('[-_]'));
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

  /// Find and return the voice Map from device voices where 'name' matches.
  Future<Map<String, dynamic>?> _findVoiceByName(String name) async {
    dynamic voices;
    try {
      voices = await _flutterTts.getVoices;
    } catch (_) {
      return null;
    }
    if (voices is! List) return null;
    for (final item in voices) {
      if (item is! Map) continue;
      final itemName = (item['name'] ?? '').toString();
      if (itemName == name) return Map<String, dynamic>.from(item);
    }
    return null;
  }

  /// Try SSML speaking for Arabic; fallback to chunked speaking if SSML
  /// doesn't work. Returns true if speaking was started successfully.
  Future<bool> _speakArabicTextRobust(String text) async {
    try {
      final escaped = text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      final ssml = '<speak><lang xml:lang="ar-SA">$escaped</lang></speak>';
      try {
        final r = await _flutterTts.speak(ssml);
        if (r == 1 || r == null) return true;
      } catch (_) {}
    } catch (_) {}

    // Fallback: split into sentences/clauses and speak one by one.
    try {
      final parts = text.split(RegExp(r'[\.\?\!\Ïî\Ïø\Ïş]'));
      for (final part in parts) {
        final p = part.trim();
        if (p.isEmpty) continue;
        try {
          await _flutterTts.speak(p);
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      return true;
    } catch (_) {}
    return false;
  }
}
