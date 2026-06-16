import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'reminder_text_settings_storage.dart';
import 'reminder_tts_voice_policy.dart';
export 'reminder_tts_voice_policy.dart' show ReminderVoiceOption;
class ReminderAudioService {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  static const String defaultTurkishVoiceName =
      ReminderTtsVoicePolicy.defaultTurkishVoiceName;
  static const String defaultTurkishVoiceLocale =
      ReminderTtsVoicePolicy.defaultTurkishVoiceLocale;
  static const double _stableTtsPitch = 1.0;
  static const double _turkishTtsRate = 0.42;
  static const double _stableTtsRate = 0.52;
  static const double _arabicTtsRate = 0.45;
  static const double _stableTtsVolume = 1.0;
  static const Duration _ttsRestartGap = Duration(milliseconds: 80);
  static const Duration _ttsDebounce = Duration(milliseconds: 400);
  bool _ttsInProgress = false;
  DateTime? _lastTtsStartAt;
  Future<List<ReminderVoiceOption>> loadVoiceOptions({
    bool onlyTurkishMale = false,
    String? languageCode,
  }) async {
    final voices = await _readDeviceVoices();
    if (voices == null) return const [];
    final requestedLanguage = onlyTurkishMale ? 'tr' : languageCode;
    final options = <ReminderVoiceOption>[];
    for (final voice in voices) {
      final option = ReminderTtsVoicePolicy.optionFromVoice(
        voice,
        languageCode: requestedLanguage,
      );
      if (option == null) continue;
      options.add(option);
    }
    options.sort((a, b) => a.label.compareTo(b.label));
    return options;
  }
  Future<List<String>> availableVoiceKeys() async {
    final voices = await _readDeviceVoices();
    if (voices == null) return const [];
    final keys = <String>[];
    for (final voice in voices) {
      final option = ReminderTtsVoicePolicy.optionFromVoice(voice);
      if (option != null) keys.add(option.key);
    }
    keys.sort();
    return keys;
  }
  Future<bool> voiceKeyExists(String compositeKey) async {
    final parsed = _parseVoiceKey(compositeKey);
    if (parsed == null) return false;
    final voices = await _readDeviceVoices();
    if (voices == null) return false;
    return ReminderTtsVoicePolicy.findExactMaleVoice(
          voices: voices,
          locale: parsed.locale,
          name: parsed.name,
        ) !=
        null;
  }
  Future<void> saveSelectedLanguageVoices({
    String? englishVoiceLocale,
    String? englishVoiceName,
    String? arabicVoiceLocale,
    String? arabicVoiceName,
  }) async {
    try {
      final storage = ReminderTextSettingsStorage();
      final current = await storage.read();
      final voices = await _readDeviceVoices();
      final english = _resolvePersistableVoice(
        voices: voices,
        providedName: englishVoiceName,
        providedLocale: englishVoiceLocale,
        currentName: current.selectedEnglishVoiceName,
        currentLocale: current.selectedEnglishVoiceLocale,
        languageCode: 'en',
      );
      final arabic = _resolvePersistableVoice(
        voices: voices,
        providedName: arabicVoiceName,
        providedLocale: arabicVoiceLocale,
        currentName: current.selectedArabicVoiceName,
        currentLocale: current.selectedArabicVoiceLocale,
        languageCode: 'ar',
      );
      await storage.writeSelectedLanguageVoices(
        englishVoiceName: english?.name,
        englishVoiceLocale: english?.locale,
        arabicVoiceName: arabic?.name,
        arabicVoiceLocale: arabic?.locale,
      );
      debugPrint('[TTS] Saved male-only selected language voices.');

      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final languageCode = locale.languageCode.toLowerCase();
      if (languageCode == 'en' && english != null) {
        await _applyExactMaleVoice(english.name, english.locale);
      } else if (languageCode == 'ar' && arabic != null) {
        await _applyExactMaleVoice(arabic.name, arabic.locale);
      }
    } catch (e) {
      debugPrint('[TTS] Error saving/applying selected language voices: $e');
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
        await _speakWithMaleVoice(
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
        if (audioPath.isEmpty) throw Exception('audio_file_missing');
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(audioPath));
        return;
    }
  }

  Future<void> playAlert() async {
    // Prayer-time adhan alerts must not play the phone's default system sound.
  }

  Future<void> speakText({required String text, Locale? selectedLocale}) async {
    final spokenText = text.trim();
    if (spokenText.isEmpty) return;
    await _speakWithMaleVoice(
      _normalizeTurkishSpeechText(spokenText, selectedLocale: selectedLocale),
      selectedLocale: selectedLocale,
    );
  }

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
    await _speakWithMaleVoice(
      normalizedText,
      selectedLocale: selectedLocale,
      voiceName: voiceName,
      voiceLocale: voiceLocale,
    );
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

  Future<void> _speakWithMaleVoice(
    String spokenText, {
    required Locale? selectedLocale,
    String? voiceName,
    String? voiceLocale,
  }) async {
    final now = DateTime.now();
    final last = _lastTtsStartAt;
    if (_ttsInProgress) return;
    if (last != null && now.difference(last) < _ttsDebounce) return;

    _ttsInProgress = true;
    _lastTtsStartAt = now;
    try {
      await _prepareTtsEngine();
      final voiceApplied = voiceName != null || voiceLocale != null
          ? await _applyRequestedMaleVoice(voiceName, voiceLocale)
          : await _applyPreferredMaleVoice(selectedLocale: selectedLocale);
      if (!voiceApplied) {
        debugPrint('[TTS] Male voice not found; speech skipped.');
        return;
      }
      await _applyStableSpeechSettings(
        selectedLocale,
        voiceLocale: voiceLocale,
      );
      final languageCode = _languageCodeForSpeech(selectedLocale, voiceLocale);
      if (languageCode == 'ar') {
        final ok = await _speakArabicTextRobust(spokenText);
        if (ok) return;
      }
      final result = await _flutterTts.speak(spokenText);
      if (result == 1 || result == null) return;
      throw Exception('tts_failed');
    } finally {
      _ttsInProgress = false;
    }
  }

  Future<void> _prepareTtsEngine() async {
    await _flutterTts.stop();
    await Future<void>.delayed(_ttsRestartGap);
    try {
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (_) {}
    try {
      await _flutterTts.setQueueMode(0);
    } catch (_) {}
  }

  Future<void> _applyStableSpeechSettings(
    Locale? selectedLocale, {
    String? voiceLocale,
  }) async {
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
  }

  Future<bool> _applyRequestedMaleVoice(
    String? voiceName,
    String? locale,
  ) async {
    if (voiceName == null || locale == null) return false;
    return _applyExactMaleVoice(voiceName, locale);
  }

  Future<bool> _applyPreferredMaleVoice({
    required Locale? selectedLocale,
  }) async {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final locale = ReminderTtsVoicePolicy.normalizeLocale(
      selectedLocale ?? deviceLocale,
    );
    final languageCode = locale.languageCode.toLowerCase();
    if (!ReminderTtsVoicePolicy.isSupportedLanguageCode(languageCode)) {
      return false;
    }
    final stored = await _storedMaleVoiceForLanguage(languageCode);
    if (stored != null &&
        await _applyExactMaleVoice(stored.name, stored.locale)) {
      return true;
    }
    final voices = await _readDeviceVoices();
    if (voices == null) return false;
    final selected = ReminderTtsVoicePolicy.pickBestMaleVoice(
      voices: voices,
      locale: locale,
    );
    if (selected == null) return false;
    final name = (selected['name'] ?? '').toString();
    final voiceLocale = (selected['locale'] ?? '').toString();
    return _setMaleVoice(name: name, locale: voiceLocale);
  }

  Future<_VoiceSelection?> _storedMaleVoiceForLanguage(
    String languageCode,
  ) async {
    if (languageCode != 'en' && languageCode != 'ar') return null;
    final storage = ReminderTextSettingsStorage();
    final stored = await storage.read();
    final name = languageCode == 'en'
        ? stored.selectedEnglishVoiceName
        : stored.selectedArabicVoiceName;
    final locale = languageCode == 'en'
        ? stored.selectedEnglishVoiceLocale
        : stored.selectedArabicVoiceLocale;
    if (name == null || locale == null) return null;
    final voices = await _readDeviceVoices();
    if (voices == null) return null;
    final exact = ReminderTtsVoicePolicy.findExactMaleVoice(
      voices: voices,
      name: name,
      locale: locale,
    );
    if (exact == null) return null;
    return _VoiceSelection(name: name, locale: locale);
  }

  Future<bool> _applyExactMaleVoice(String name, String locale) async {
    final voices = await _readDeviceVoices();
    if (voices == null) return false;
    final exact = ReminderTtsVoicePolicy.findExactMaleVoice(
      voices: voices,
      name: name,
      locale: locale,
    );
    if (exact == null) return false;
    return _setMaleVoice(name: name, locale: locale);
  }

  Future<bool> _setMaleVoice({
    required String name,
    required String locale,
  }) async {
    try {
      final normalized = ReminderTtsVoicePolicy.normalizeLocale(
        ReminderTtsVoicePolicy.localeFromTag(locale),
      );
      await _flutterTts.setLanguage(
        ReminderTtsVoicePolicy.localeTag(normalized).toLowerCase(),
      );
    } catch (_) {}
    try {
      await _flutterTts.setVoice({'name': name, 'locale': locale});
      return true;
    } catch (e) {
      debugPrint('[TTS] Failed to apply male voice $locale|$name: $e');
      return false;
    }
  }

  _VoiceSelection? _resolvePersistableVoice({
    required List? voices,
    required String? providedName,
    required String? providedLocale,
    required String? currentName,
    required String? currentLocale,
    required String languageCode,
  }) {
    if (voices == null) {
      if (currentName == null || currentLocale == null) return null;
      return _VoiceSelection(name: currentName, locale: currentLocale);
    }
    final provided = _validatedSelection(
      voices: voices,
      name: providedName,
      locale: providedLocale,
      languageCode: languageCode,
    );
    if (provided != null) return provided;
    return _validatedSelection(
      voices: voices,
      name: currentName,
      locale: currentLocale,
      languageCode: languageCode,
    );
  }

  _VoiceSelection? _validatedSelection({
    required List voices,
    required String? name,
    required String? locale,
    required String languageCode,
  }) {
    if (name == null || locale == null) return null;
    if (ReminderTtsVoicePolicy.languageCodeFromTag(locale) != languageCode) {
      return null;
    }
    final exact = ReminderTtsVoicePolicy.findExactMaleVoice(
      voices: voices,
      name: name,
      locale: locale,
    );
    if (exact == null) return null;
    return _VoiceSelection(name: name, locale: locale);
  }

  _VoiceSelection? _parseVoiceKey(String compositeKey) {
    final parts = compositeKey.split('|');
    if (parts.length < 2) return null;
    return _VoiceSelection(name: parts.sublist(1).join('|'), locale: parts[0]);
  }

  Future<List?> _readDeviceVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return voices is List ? voices : null;
    } catch (_) {
      return null;
    }
  }

  String _normalizeTurkishSpeechText(
    String text, {
    Locale? selectedLocale,
    String? voiceLocale,
  }) {
    final languageCode = _languageCodeForSpeech(selectedLocale, voiceLocale);
    if (languageCode != 'tr') return text;
    var normalized = text;
    final replacements = <MapEntry<Pattern, String>>[
      MapEntry(
        RegExp(r'\(\s*r\.?\s*a\.?\s*\)', caseSensitive: false),
        'radiyallahû anhû',
      ),
      MapEntry(
        RegExp(r'\(\s*a\.?\s*s\.?\s*\)', caseSensitive: false),
        'âleyhisselâm',
      ),
      MapEntry(
        RegExp(
          r'\(\s*(?:s\.?\s*a\.?\s*v\.?|s\.?\s*a\.?)\s*\)',
          caseSensitive: false,
        ),
        'Sallallahu aleyhi ve sellem',
      ),
      MapEntry(RegExp(r'\bHz\.', caseSensitive: false), 'Hazreti'),
      MapEntry(RegExp(r'\bb\.(?=\s|$)', caseSensitive: true), 'Bin'),
      MapEntry(RegExp(r"\bKa['’`]be\b", caseSensitive: false), 'Kâbe'),
      MapEntry(RegExp(r'\bAvf\b', caseSensitive: false), 'Avuf'),
      MapEntry(RegExp(r'\bAmr\b', caseSensitive: false), 'Amır'),
    ];
    for (final replacement in replacements) {
      normalized = normalized.replaceAll(replacement.key, replacement.value);
    }
    return normalized;
  }

  double _speechRateForLocale(Locale? locale, {String? voiceLocale}) {
    final languageCode = _languageCodeForSpeech(locale, voiceLocale);
    if (languageCode == 'ar') return _arabicTtsRate;
    if (languageCode == 'tr') return _turkishTtsRate;
    return _stableTtsRate;
  }

  String _languageCodeForSpeech(Locale? locale, String? voiceLocale) {
    final fromVoice = ReminderTtsVoicePolicy.languageCodeFromTag(voiceLocale);
    if (fromVoice.isNotEmpty) return fromVoice;
    return (locale ?? WidgetsBinding.instance.platformDispatcher.locale)
        .languageCode
        .toLowerCase();
  }

  Future<bool> _speakArabicTextRobust(String text) async {
    try {
      final escaped = text
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;');
      final ssml = '<speak><lang xml:lang="ar-SA">$escaped</lang></speak>';
      try {
        final result = await _flutterTts.speak(ssml);
        if (result == 1 || result == null) return true;
      } catch (_) {}
    } catch (_) {}

    try {
      final parts = text.split(RegExp(r'[\.\?\!،؛]'));
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

class _VoiceSelection {
  final String name;
  final String locale;

  const _VoiceSelection({required this.name, required this.locale});
}
