import '../../../features/daily_content/daily_content_models.dart';
import '../../../features/daily_content/quran_surah_names.dart';

String dailyContentAyahReference(DailyAyahRecord ayah, String language) {
  final surah = dailyContentFormatReferenceNumber(ayah.surahNumber, language);
  final surahName = dailyContentSurahNameForLanguage(ayah, language);
  final start = dailyContentFormatReferenceNumber(ayah.ayahNumber, language);
  final endNumber = ayah.ayahEndNumber;
  final prefix = surahName.isEmpty ? surah : '$surah $surahName';
  if (endNumber == null || endNumber <= ayah.ayahNumber) {
    return '$prefix / $start';
  }
  final end = dailyContentFormatReferenceNumber(endNumber, language);
  return '$prefix / $start-$end';
}

String dailyContentSurahNameForLanguage(DailyAyahRecord ayah, String language) {
  final fallback = ayah.surahName.trim();
  if (language == 'ar') {
    return QuranSurahNames.arabicName(ayah.surahNumber, fallback);
  }
  if (language == 'en') {
    return QuranSurahNames.englishName(ayah.surahNumber, fallback);
  }
  return fallback;
}

String dailyContentFormatReferenceNumber(int value, String language) {
  final formatted = value.toString().padLeft(2, '0');
  return language == 'ar' ? dailyContentToArabicDigits(formatted) : formatted;
}

String dailyContentHadithReference(DailyHadithRecord hadith, String language) {
  if (language == 'ar') {
    return 'رياض الصالحين ${dailyContentToArabicDigits(hadith.hadithNumber)}';
  }
  if (language == 'en') return 'Riyad as-Salihin ${hadith.hadithNumber}';
  return 'Riyazüs-Salihîn ${hadith.hadithNumber}';
}

String dailyContentToArabicDigits(String value) {
  const digits = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };
  return value.split('').map((char) => digits[char] ?? char).join();
}

String dailyContentEsmaReference(DailyEsmaRecord record) {
  if (record.kind != 'sifat') return '';
  final category = record.category.trim();
  if (category.endsWith('lar') || category.endsWith('ler')) {
    return category.substring(0, category.length - 3);
  }
  return category;
}

String dailyContentLanguageText(dynamic record, String language) {
  if (language == 'tr') {
    if (record is DailyAyahRecord) return record.textTr;
    if (record is DailyHadithRecord) return record.textTr;
    final esma = record as DailyEsmaRecord;
    return dailyContentJoinMeaningAndText(esma.meaningTr, esma.textTr);
  }
  if (language == 'en') {
    if (record is DailyAyahRecord) return record.textEn;
    if (record is DailyHadithRecord) return record.textEn;
    final esma = record as DailyEsmaRecord;
    return dailyContentJoinMeaningAndText(esma.meaningEn, esma.textEn);
  }
  if (record is DailyAyahRecord) return record.textAr;
  if (record is DailyHadithRecord) return record.textAr;
  final esma = record as DailyEsmaRecord;
  return dailyContentJoinMeaningAndText(esma.meaningAr, esma.textAr);
}

String dailyContentLanguageTitle(DailyEsmaRecord record, String language) {
  if (language == 'ar') return record.nameArabic;
  if (language == 'en') return record.nameTransliteration;
  return record.nameTurkish;
}

String dailyContentJoinMeaningAndText(String meaning, String text) {
  final first = meaning.trim();
  final second = text.trim();
  if (first.isEmpty) return second;
  if (second.isEmpty || second == first) return first;
  return '$first\n\n$second';
}

String dailyContentInfoNoteForLanguage(String language) {
  if (language == 'ar') {
    return '\u0633\u064a\u0636\u0627\u0641 \u0627\u0644\u0645\u062d\u062a\u0648\u0649';
  }
  if (language == 'en') return 'Content will be added';
  return '\u0130\u00e7erik Eklenecek';
}

bool dailyContentHasArabic(String value) {
  return RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  ).hasMatch(value);
}
