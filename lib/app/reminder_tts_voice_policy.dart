import 'package:flutter/material.dart';

class ReminderVoiceOption {
  final String name;
  final String locale;

  const ReminderVoiceOption({required this.name, required this.locale});

  String get key => '$locale|$name';
  String get label => '$name ($locale)';
}

class ReminderTtsVoicePolicy {
  static const String defaultTurkishVoiceName = 'tr-tr-x-tmc-network';
  static const String defaultTurkishVoiceLocale = 'tr-TR';
  static const Set<String> supportedLanguageCodes = {'tr', 'en', 'ar'};

  const ReminderTtsVoicePolicy._();

  static bool isSupportedLanguageCode(String languageCode) {
    return supportedLanguageCodes.contains(languageCode.toLowerCase());
  }

  static String languageCodeFromTag(String? tag) {
    final trimmed = tag?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp('[-_]')).first.toLowerCase();
  }

  static Locale normalizeLocale(Locale locale) {
    final languageCode = locale.languageCode.toLowerCase();
    final countryCode = locale.countryCode;
    if (countryCode != null && countryCode.isNotEmpty) return locale;
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

  static Locale localeFromTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty)
      return WidgetsBinding.instance.platformDispatcher.locale;
    final parts = trimmed.split(RegExp('[-_]'));
    if (parts.length == 1) return Locale(parts[0]);
    return Locale(parts[0], parts[1]);
  }

  static String localeTag(Locale locale) {
    final countryCode = locale.countryCode;
    if (countryCode == null || countryCode.isEmpty) return locale.languageCode;
    return '${locale.languageCode}-$countryCode';
  }

  static List<String> preferredLocaleTags(String localeCode) {
    switch (localeCode.toLowerCase()) {
      case 'en':
        return const ['en-us', 'en-gb', 'en-au', 'en-ca', 'en-in'];
      case 'ar':
        return const ['ar-sa', 'ar-eg', 'ar-ae', 'ar-jo'];
      case 'tr':
        return const ['tr-tr'];
      default:
        return const [];
    }
  }

  static Map<String, dynamic>? normalizeVoice(dynamic voice) {
    if (voice is! Map) return null;
    final name = (voice['name'] ?? '').toString().trim();
    final locale = (voice['locale'] ?? '').toString().trim();
    if (name.isEmpty || locale.isEmpty) return null;
    return Map<String, dynamic>.from(voice);
  }

  static ReminderVoiceOption? optionFromVoice(
    dynamic voice, {
    String? languageCode,
    bool requireMale = true,
  }) {
    final normalized = normalizeVoice(voice);
    if (normalized == null) return null;
    final voiceLocale = (normalized['locale'] ?? '').toString();
    final voiceLanguage = languageCodeFromTag(voiceLocale);
    final requestedLanguage = languageCode?.toLowerCase();
    if (requestedLanguage != null && requestedLanguage.isNotEmpty) {
      if (voiceLanguage != requestedLanguage) return null;
    } else if (!isSupportedLanguageCode(voiceLanguage)) {
      return null;
    }
    if (requireMale && !isConfidentMale(normalized)) return null;
    return ReminderVoiceOption(
      name: (normalized['name'] ?? '').toString().trim(),
      locale: voiceLocale.trim(),
    );
  }

  static String voiceCompositeKey(Map<String, dynamic> voice) {
    final name = (voice['name'] ?? '').toString().toLowerCase();
    final locale = (voice['locale'] ?? '').toString().toLowerCase();
    final identifier = (voice['identifier'] ?? '').toString().toLowerCase();
    final shortName = (voice['shortName'] ?? '').toString().toLowerCase();
    final gender = (voice['gender'] ?? '').toString().toLowerCase();
    return '$locale|$name|$identifier|$shortName|$gender';
  }

  static bool isConfidentMale(Map<String, dynamic> voice) {
    final gender = (voice['gender'] ?? '').toString().trim().toLowerCase();
    if (_femaleTokens.contains(gender)) return false;
    if (_maleTokens.contains(gender)) return true;

    final key = voiceCompositeKey(voice);
    if (_matchesDefaultTurkishMaleVoice(voice)) return true;

    final tokens = key
        .split(RegExp(r'[^a-z0-9ğüşöçıİ]+', unicode: true))
        .map((token) => token.trim().toLowerCase())
        .where((token) => token.isNotEmpty)
        .toSet();
    if (tokens.any(_femaleTokens.contains)) return false;
    return tokens.any(_maleTokens.contains);
  }

  static Map<String, dynamic>? findExactMaleVoice({
    required List voices,
    required String name,
    required String locale,
  }) {
    for (final item in voices) {
      final voice = normalizeVoice(item);
      if (voice == null) continue;
      if ((voice['name'] ?? '').toString() != name) continue;
      if ((voice['locale'] ?? '').toString() != locale) continue;
      if (!isConfidentMale(voice)) return null;
      final languageCode = languageCodeFromTag(locale);
      if (!isSupportedLanguageCode(languageCode)) return null;
      return voice;
    }
    return null;
  }

  static Map<String, dynamic>? findMaleVoiceByName({
    required List voices,
    required String name,
    String? locale,
  }) {
    for (final item in voices) {
      final voice = normalizeVoice(item);
      if (voice == null) continue;
      if ((voice['name'] ?? '').toString() != name) continue;
      if (locale != null && (voice['locale'] ?? '').toString() != locale) {
        continue;
      }
      if (!isConfidentMale(voice)) continue;
      final languageCode = languageCodeFromTag(
        (voice['locale'] ?? '').toString(),
      );
      if (!isSupportedLanguageCode(languageCode)) continue;
      return voice;
    }
    return null;
  }

  static Map<String, dynamic>? pickBestMaleVoice({
    required List voices,
    required Locale locale,
  }) {
    final normalizedLocale = normalizeLocale(locale);
    final localeCode = normalizedLocale.languageCode.toLowerCase();
    if (!isSupportedLanguageCode(localeCode)) return null;
    final localeTagValue = localeTag(normalizedLocale).toLowerCase();
    final preferredTags = preferredLocaleTags(localeCode);
    final localeVoices = <Map<String, dynamic>>[];
    final preferredVoices = <Map<String, dynamic>>[];

    for (final item in voices) {
      final voice = normalizeVoice(item);
      if (voice == null) continue;
      final voiceLocale = (voice['locale'] ?? '').toString().toLowerCase();
      if (languageCodeFromTag(voiceLocale) != localeCode) continue;
      if (!isConfidentMale(voice)) continue;
      localeVoices.add(voice);
      if (voiceLocale == localeTagValue ||
          preferredTags.contains(voiceLocale)) {
        preferredVoices.add(voice);
      }
    }
    if (localeVoices.isEmpty) return null;

    if (localeCode == 'tr') {
      for (final voice in localeVoices) {
        if (_matchesDefaultTurkishMaleVoice(voice)) return voice;
      }
    }
    if (preferredVoices.isNotEmpty) return preferredVoices.first;
    return localeVoices.first;
  }

  static bool _matchesDefaultTurkishMaleVoice(Map<String, dynamic> voice) {
    final name = (voice['name'] ?? '').toString().toLowerCase();
    final locale = (voice['locale'] ?? '').toString().toLowerCase();
    return name == defaultTurkishVoiceName && locale.startsWith('tr');
  }

  static const Set<String> _maleTokens = {
    'male',
    'masculine',
    'man',
    'erkek',
    'ahmet',
  };

  static const Set<String> _femaleTokens = {
    'female',
    'feminine',
    'woman',
    'women',
    'kadin',
    'kadın',
    'girl',
  };
}
