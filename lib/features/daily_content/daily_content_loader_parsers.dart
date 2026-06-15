part of 'daily_content_loader.dart';

extension DailyContentLoaderRecordParsers on DailyContentLoader {
  DailyAyahRecord? _parseAyahRecord(
    Map<String, dynamic> json,
    String path,
    int index,
    List<String> warnings,
  ) {
    final id = _readRequiredString(json, 'id');
    final type =
        _readRequiredString(json, 'type') ??
        _readRequiredString(json, 'kind') ??
        'ayah';
    final surahName = _readRequiredString(json, 'surah_name');
    final surahNumber = _readRequiredInt(json, 'surah_number');
    final ayahNumber = _readRequiredInt(json, 'ayah_number');
    final rawAyahEndNumber = _readRequiredInt(json, 'ayah_end_number');
    final textAr =
        _readRequiredString(json, 'text_ar') ??
        _readRequiredString(json, 'ar') ??
        _readRequiredString(json, 'text');
    final textTr =
        _readRequiredString(json, 'text_tr') ??
        _readRequiredString(json, 'tr') ??
        _readRequiredString(json, 'translation');
    final textEn =
        _readRequiredString(json, 'text_en') ?? _readRequiredString(json, 'en');
    final sourceAr =
        _readRequiredString(json, 'source_ar') ?? 'local approved payload';
    final sourceTr =
        _readRequiredString(json, 'source_tr') ?? 'local approved payload';
    final sourceEn =
        _readRequiredString(json, 'source_en') ?? 'local approved payload';
    final mealSource =
        _readRequiredString(json, 'meal_source') ?? 'source_based';
    final sourceNote = _readRequiredString(json, 'source_note') ?? '';
    final topics =
        _readRequiredStringList(json, 'topics') ?? const ['ayah_approved_pool'];
    final status = _readOptionalString(json, 'status') ?? 'approved';
    final approval = _parseApprovalOrDefault(json);

    if (id == null ||
        surahName == null ||
        surahNumber == null ||
        ayahNumber == null ||
        textAr == null ||
        textTr == null ||
        textEn == null) {
      warnings.add('$path[$index]: ayah kaydi zorunlu alanlari eksik.');
      return null;
    }

    if (type != 'ayah') {
      warnings.add('$path[$index]: type ayah olmali.');
      return null;
    }
    if (status != 'approved') {
      warnings.add('$path[$index]: status approved olmadigi icin atlandi.');
      return null;
    }

    final ayahEndNumber =
        rawAyahEndNumber ??
        _readAyahEndNumberFromReference(
          _readOptionalString(json, 'ref') ?? id,
          ayahNumber,
        ) ??
        _readAyahEndNumberFromText([textAr, textTr, textEn], ayahNumber);

    return DailyAyahRecord(
      id: id,
      type: type,
      surahName: surahName,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      ayahEndNumber: ayahEndNumber,
      textAr: textAr,
      textTr: textTr,
      textEn: textEn,
      sourceAr: sourceAr,
      sourceTr: sourceTr,
      sourceEn: sourceEn,
      mealSource: mealSource,
      sourceNote: sourceNote,
      topics: topics,
      status: status,
      approval: approval,
    );
  }

  DailyHadithRecord? _parseHadithRecord(
    Map<String, dynamic> json,
    String path,
    int index,
    List<String> warnings,
  ) {
    final id = _readRequiredString(json, 'id');
    final sourceInfo = _readMap(json, 'sourceInfo');
    final display = _readNestedMap(sourceInfo, 'display');
    final primaryCollection = _readNestedMap(sourceInfo, 'primaryCollection');
    final chapter = _readNestedMap(sourceInfo, 'chapter');
    final type =
        _readRequiredString(json, 'type') ??
        _readRequiredString(json, 'kind') ??
        'hadith';
    final collection =
        _readRequiredString(json, 'collection') ??
        _readStringFromMap(primaryCollection, 'title_tr') ??
        _readStringFromMap(primaryCollection, 'title_en') ??
        _readRequiredString(json, 'groupKey') ??
        'Riyazus Salihin';
    final book =
        _readRequiredString(json, 'book') ??
        _readStringFromMap(chapter, 'diyanet_tr') ??
        _readStringFromMap(chapter, 'sunnah') ??
        '';
    final hadithNumber =
        _readRequiredString(json, 'hadith_number') ??
        _readRequiredString(json, 'hadithNo') ??
        _readRequiredString(json, 'epubNo');
    final narrator =
        _readRequiredString(json, 'narrator') ?? 'requires verification';
    final textAr =
        _readRequiredString(json, 'text_ar') ??
        _readRequiredString(json, 'ar') ??
        _readNestedText(json, 'ar') ??
        _readRequiredString(json, 'text');
    final rawTextTr =
        _readRequiredString(json, 'text_tr') ??
        _readRequiredString(json, 'tr') ??
        _readNestedText(json, 'tr') ??
        _readRequiredString(json, 'text');
    final textEn =
        _readRequiredString(json, 'text_en') ??
        _readRequiredString(json, 'en') ??
        _readNestedText(json, 'en') ??
        _readRequiredString(json, 'translation');
    final sourceAr =
        _readRequiredString(json, 'source_ar') ??
        _readStringFromMap(display, 'ar') ??
        'local approved payload';
    final sourceTr =
        _readRequiredString(json, 'source_tr') ??
        _readStringFromMap(display, 'tr') ??
        'local approved payload';
    final sourceEn =
        _readRequiredString(json, 'source_en') ??
        _readStringFromMap(display, 'en') ??
        'local approved payload';
    final grade =
        _readRequiredString(json, 'grade') ?? 'riyad_as_salihin_selection';
    final bookReferenceTr =
        _readOptionalString(json, 'book_reference_tr') ??
        _readStringFromMap(display, 'tr') ??
        '';
    final sourceNote = _readRequiredString(json, 'source_note') ?? '';
    final topics =
        _readRequiredStringList(json, 'topics') ??
        const ['hadis_approved_pool'];
    final status = _readOptionalString(json, 'status') ?? 'approved';
    final approval = _parseApprovalOrDefault(json);

    if (id == null ||
        hadithNumber == null ||
        textAr == null ||
        rawTextTr == null ||
        textEn == null) {
      warnings.add('$path[$index]: hadith kaydi zorunlu alanlari eksik.');
      return null;
    }

    if (type != 'hadith') {
      warnings.add('$path[$index]: type hadith olmali.');
      return null;
    }
    if (status != 'approved') {
      warnings.add('$path[$index]: status approved olmadigi icin atlandi.');
      return null;
    }

    final turkishTextAndReference = _normalizeTurkishHadithTextAndReference(
      rawText: rawTextTr,
      explicitBookReferenceTr: bookReferenceTr,
    );

    return DailyHadithRecord(
      id: id,
      type: type,
      collection: collection,
      book: book,
      hadithNumber: hadithNumber,
      narrator: narrator,
      textAr: textAr,
      textTr: turkishTextAndReference.textTr,
      textEn: textEn,
      sourceAr: sourceAr,
      sourceTr: sourceTr,
      sourceEn: sourceEn,
      bookReferenceTr: turkishTextAndReference.bookReferenceTr,
      grade: grade,
      sourceNote: sourceNote,
      topics: topics,
      status: status,
      approval: approval,
    );
  }

  DailyEsmaRecord? _parseEsmaRecord(
    Map<String, dynamic> json,
    String path,
    int index,
    List<String> warnings,
  ) {
    final id = _readRequiredString(json, 'id');
    final type = _readRequiredString(json, 'type') ?? 'esma';
    final kind = _readRequiredString(json, 'kind');
    final category = _readRequiredString(json, 'category') ?? '';
    final sourceId =
        _readRequiredInt(json, 'source_id') ??
        _readRequiredInt(json, 'esma_number');
    final displayOrder = _readRequiredInt(json, 'display_order') ?? sourceId;
    final ref = _readRequiredString(json, 'ref') ?? id;
    final nameArabic =
        _readRequiredString(json, 'name_arabic') ??
        _readRequiredString(json, 'arabic_name');
    final nameTurkish =
        _readRequiredString(json, 'name_turkish') ??
        _readRequiredString(json, 'latin_tr');
    final nameTransliteration =
        _readRequiredString(json, 'name_transliteration') ??
        _readRequiredString(json, 'latin_en');
    final textAr =
        _readRequiredString(json, 'text_ar') ??
        _readRequiredString(json, 'ar') ??
        _readRequiredString(json, 'descriptionAr');
    final textTr =
        _readRequiredString(json, 'text_tr') ??
        _readRequiredString(json, 'tr') ??
        _readRequiredString(json, 'descriptionTr');
    final textEn =
        _readRequiredString(json, 'text_en') ??
        _readRequiredString(json, 'en') ??
        _readRequiredString(json, 'descriptionEn');
    final meaningAr = _readRequiredString(json, 'meaning_ar') ?? '';
    final meaningTr = _readRequiredString(json, 'meaning_tr') ?? '';
    final meaningEn = _readRequiredString(json, 'meaning_en') ?? '';
    final sourceNote = _readRequiredString(json, 'source_note') ?? '';
    final topics = _readRequiredStringList(json, 'topics') ?? const <String>[];
    final status = _readOptionalString(json, 'status') ?? 'approved';
    final approval = _parseApprovalOrDefault(json);

    if (id == null ||
        kind == null ||
        sourceId == null ||
        displayOrder == null ||
        ref == null ||
        nameArabic == null ||
        nameTurkish == null ||
        nameTransliteration == null ||
        textAr == null ||
        textTr == null ||
        textEn == null) {
      warnings.add('$path[$index]: esma kaydi zorunlu alanlari eksik.');
      return null;
    }

    if (type != 'esma') {
      warnings.add('$path[$index]: type esma olmali.');
      return null;
    }
    if (kind != 'esma' && kind != 'sifat') {
      warnings.add('$path[$index]: kind esma veya sifat olmali.');
      return null;
    }
    if (status != 'approved') {
      warnings.add('$path[$index]: status approved olmadigi icin atlandi.');
      return null;
    }

    return DailyEsmaRecord(
      id: id,
      type: type,
      kind: kind,
      category: category,
      sourceId: sourceId,
      displayOrder: displayOrder,
      ref: ref,
      nameArabic: nameArabic,
      nameTurkish: nameTurkish,
      nameTransliteration: nameTransliteration,
      textAr: textAr,
      textTr: textTr,
      textEn: textEn,
      meaningAr: meaningAr,
      meaningTr: meaningTr,
      meaningEn: meaningEn,
      sourceNote: sourceNote,
      topics: topics,
      status: status,
      approval: approval,
    );
  }

  _TurkishHadithTextAndReference _normalizeTurkishHadithTextAndReference({
    required String rawText,
    required String explicitBookReferenceTr,
  }) {
    final explicitReference = explicitBookReferenceTr.trim();
    final normalizedText = rawText.replaceAll('\r\n', '\n');
    if (explicitReference.isNotEmpty) {
      final text = _stripTrailingExactReference(
        text: normalizedText,
        reference: explicitReference,
      );
      return _TurkishHadithTextAndReference(
        textTr: text,
        bookReferenceTr: explicitReference,
      );
    }

    final extractedReference = _extractTrailingReferenceLine(normalizedText);
    if (extractedReference != null) {
      final text = _stripTrailingExactReference(
        text: normalizedText,
        reference: extractedReference,
      );
      return _TurkishHadithTextAndReference(
        textTr: text,
        bookReferenceTr: extractedReference,
      );
    }

    return _TurkishHadithTextAndReference(
      textTr: normalizedText,
      bookReferenceTr: '',
    );
  }

  String _stripTrailingExactReference({
    required String text,
    required String reference,
  }) {
    final trimmedRightText = text.trimRight();
    if (!trimmedRightText.endsWith(reference)) {
      return text;
    }
    final withoutReference = trimmedRightText.substring(
      0,
      trimmedRightText.length - reference.length,
    );
    return withoutReference.trimRight();
  }

  String? _extractTrailingReferenceLine(String text) {
    final lines = text.split('\n');
    var lastNonEmptyIndex = -1;
    for (var i = lines.length - 1; i >= 0; i--) {
      if (lines[i].trim().isNotEmpty) {
        lastNonEmptyIndex = i;
        break;
      }
    }
    if (lastNonEmptyIndex < 0) {
      return null;
    }
    final candidate = lines[lastNonEmptyIndex].trim();
    if (candidate.startsWith('(') &&
        candidate.contains(')') &&
        RegExp(r'[A-Z][0-9]{2,}').hasMatch(candidate)) {
      return candidate;
    }
    return null;
  }
}
