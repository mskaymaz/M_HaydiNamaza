import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/reminder_audio_service.dart';
import '../../../features/daily_content/daily_content_models.dart';
import '../../../features/daily_content/daily_content_selection_models.dart';
import '../../../features/daily_content/quran_surah_names.dart';

const _dailyContentArabicLocale = Locale('ar');
const _dailyContentBasmalaAsset = 'img/Besmele.svg';
const _dailyContentTtsBasmala = 'Bismill\u00E2 hirrahm\u00E2 nirrah\u00EEm';

enum DailyContentPanelKind { ayah, hadith, esma, sifat }

class HomeDailyContentPanel extends StatefulWidget {
  final DailyContentSelectionResult? result;
  final bool isLoading;
  final bool hasError;
  final Color cizgiColor;
  final Color panelColor;
  final double? maxHeight;
  final ValueChanged<DailyContentPanelKind>? onCycleContentTap;

  const HomeDailyContentPanel({
    super.key,
    required this.result,
    required this.isLoading,
    required this.hasError,
    required this.cizgiColor,
    required this.panelColor,
    this.maxHeight,
    this.onCycleContentTap,
  });

  @override
  State<HomeDailyContentPanel> createState() => _HomeDailyContentPanelState();
}

class _HomeDailyContentPanelState extends State<HomeDailyContentPanel> {
  static const String _headingAyah = 'G\u00FCn\u00FCn Ayeti';
  static const String _headingHadith = 'G\u00FCn\u00FCn Hadisi';
  static const String _headingEsma = 'Esm\u00E2\u00FCl H\u00FCsna';
  static const String _headingSifat = 'Allah\'\u0131n S\u0131fatlar\u0131';
  static const String _labelArabic = '\u0639\u0631\u0628\u064A';
  static const String _noteLoading =
      'G\u00FCnl\u00FCk i\u00E7erik y\u00FCkleniyor...';
  static const String _noteError =
      'G\u00FCnl\u00FCk i\u00E7erik \u015Fu an g\u00F6sterilemiyor.';
  static const String _noteAyahMissing =
      'Bug\u00FCn i\u00E7in ayet i\u00E7eri\u011Fi hen\u00FCz haz\u0131r de\u011Fil.';
  static const String _noteHadithMissing =
      'Bug\u00FCn i\u00E7in hadis i\u00E7eri\u011Fi hen\u00FCz haz\u0131r de\u011Fil.';
  static const String _noteEsmaMissing =
      'Bug\u00FCn i\u00E7in esma i\u00E7eri\u011Fi hen\u00FCz haz\u0131r de\u011Fil.';
  static const String _noteSifatMissing =
      'Bug\u00FCn i\u00E7in s\u0131fat i\u00E7eri\u011Fi hen\u00FCz haz\u0131r de\u011Fil.';

  late final PageController _pageController;
  final ReminderAudioService _reminderAudioService = ReminderAudioService();
  String _activeLanguage = 'tr';
  bool _languageDefaultsApplied = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reminderAudioService.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_languageDefaultsApplied) {
      return;
    }
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'tr') {
      _activeLanguage = 'tr';
    } else if (languageCode == 'en') {
      _activeLanguage = 'en';
    } else if (languageCode == 'ar') {
      _activeLanguage = 'ar';
    }
    _languageDefaultsApplied = true;
  }

  @override
  Widget build(BuildContext context) {
    final ayah = widget.result?.ayah;
    final hadith = widget.result?.hadith;
    final esma = widget.result?.esma;
    final sifat = widget.result?.sifat;
    final frameColor =
        Color.lerp(widget.panelColor, Colors.white, 0.52) ?? widget.panelColor;
    final contentColor = widget.panelColor;
    const panelVerticalPadding = 16.0;
    const defaultPageHeight = 270.0;
    final effectiveMaxHeight = widget.maxHeight == null
        ? null
        : math.max(140.0, widget.maxHeight!);
    final pageHeight = effectiveMaxHeight == null
        ? defaultPageHeight
        : math.max(124.0, effectiveMaxHeight - panelVerticalPadding);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: effectiveMaxHeight,
        constraints: effectiveMaxHeight == null
            ? null
            : BoxConstraints(maxHeight: effectiveMaxHeight),
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        decoration: BoxDecoration(
          color: frameColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.panelColor.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          height: pageHeight.toDouble(),
          child: PageView.builder(
            clipBehavior: Clip.hardEdge,
            controller: _pageController,
            itemBuilder: (context, index) {
              final page = index % 4;
              if (page == 0) {
                return _buildPage(
                  context: context,
                  heading: _headingAyah,
                  kind: DailyContentPanelKind.ayah,
                  child: _buildAyahTab(context, ayah, contentColor),
                );
              }
              if (page == 1) {
                return _buildPage(
                  context: context,
                  heading: _headingHadith,
                  kind: DailyContentPanelKind.hadith,
                  child: _buildHadithTab(context, hadith, contentColor),
                );
              }
              if (page == 2) {
                return _buildPage(
                  context: context,
                  heading: _headingEsma,
                  kind: DailyContentPanelKind.esma,
                  child: _buildEsmaTab(
                    context,
                    esma,
                    contentColor,
                    missingText: _noteEsmaMissing,
                  ),
                );
              }
              return _buildPage(
                context: context,
                heading: _headingSifat,
                kind: DailyContentPanelKind.sifat,
                child: _buildEsmaTab(
                  context,
                  sifat,
                  contentColor,
                  missingText: _noteSifatMissing,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required String heading,
    required DailyContentPanelKind kind,
    required Widget child,
  }) {
    return ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                _buildCycleButton(kind),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    heading,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLanguageToggle(
                        label: 'TR',
                        selected: _activeLanguage == 'tr',
                        onTap: () => _toggleLanguage('tr'),
                      ),
                      const SizedBox(width: 6),
                      _buildLanguageToggle(
                        label: 'EN',
                        selected: _activeLanguage == 'en',
                        onTap: () => _toggleLanguage('en'),
                      ),
                      const SizedBox(width: 6),
                      _buildLanguageToggle(
                        label: _labelArabic,
                        selected: _activeLanguage == 'ar',
                        onTap: () => _toggleLanguage('ar'),
                        fontSize: 13,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleButton(DailyContentPanelKind kind) {
    final onTap = widget.onCycleContentTap;
    return SizedBox(
      width: 36,
      height: 36,
      child: onTap == null
          ? const SizedBox.shrink()
          : Material(
              color: Colors.white,
              shape: CircleBorder(
                side: BorderSide(
                  color: Colors.black.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: InkWell(
                onTap: () => onTap(kind),
                customBorder: const CircleBorder(),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: const Color(0xFF111111),
                ),
              ),
            ),
    );
  }

  Widget _buildLanguageToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    double fontSize = 11,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? const Color(0xFF121212) : Colors.white,
          border: Border.all(
            color: selected ? const Color(0xFF121212) : widget.cizgiColor,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (selected
                          ? Colors.black
                          : widget.cizgiColor.withValues(alpha: 0.35))
                      .withValues(alpha: selected ? 0.28 : 0.12),
              blurRadius: selected ? 8 : 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: fontSize,
            color: selected ? Colors.white : const Color(0xFF111111),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _toggleLanguage(String code) {
    if (_activeLanguage == code) return;
    setState(() {
      _activeLanguage = code;
    });
  }

  Widget _buildAyahTab(
    BuildContext context,
    DailyAyahRecord? ayah,
    Color contentColor,
  ) {
    if (widget.isLoading) {
      return _buildNote(
        context: context,
        text: _noteLoading,
        contentColor: contentColor,
      );
    }
    if (widget.hasError) {
      return _buildNote(
        context: context,
        text: _noteError,
        contentColor: contentColor,
      );
    }
    if (ayah == null) {
      return _buildNote(
        context: context,
        text: _noteAyahMissing,
        contentColor: contentColor,
      );
    }
    final activeText = _languageText(ayah, _activeLanguage);
    final isRtl = _activeLanguage == 'ar';
    return _DailyContentSection(
      title: '',
      displayText: activeText,
      isRtl: isRtl,
      reference: _ayahReference(ayah, _activeLanguage),
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFFF9A825),
      showBasmala: true,
      infoText: _infoNoteForLanguage(_activeLanguage),
      onReadTap: _activeLanguage == 'tr' && activeText.trim().isNotEmpty
          ? () => _readTurkishAyahText(activeText)
          : null,
    );
  }

  Widget _buildHadithTab(
    BuildContext context,
    DailyHadithRecord? hadith,
    Color contentColor,
  ) {
    if (widget.isLoading) {
      return _buildNote(
        context: context,
        text: _noteLoading,
        contentColor: contentColor,
      );
    }
    if (widget.hasError) {
      return _buildNote(
        context: context,
        text: _noteError,
        contentColor: contentColor,
      );
    }
    if (hadith == null) {
      return _buildNote(
        context: context,
        text: _noteHadithMissing,
        contentColor: contentColor,
      );
    }
    final activeText = _languageText(hadith, _activeLanguage);
    final isRtl = _activeLanguage == 'ar';
    return _DailyContentSection(
      title: '',
      displayText: activeText,
      isRtl: isRtl,
      reference: _hadithReference(hadith, _activeLanguage),
      bookReference: hadith.bookReferenceTr,
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFFF9A825),
      infoText: _infoNoteForLanguage(_activeLanguage),
      onReadTap: _activeLanguage == 'tr' && activeText.trim().isNotEmpty
          ? () => _readTurkishText(activeText)
          : null,
    );
  }

  String _ayahReference(DailyAyahRecord ayah, String language) {
    final surah = _formatReferenceNumber(ayah.surahNumber, language);
    final surahName = _surahNameForLanguage(ayah, language);
    final start = _formatReferenceNumber(ayah.ayahNumber, language);
    final endNumber = ayah.ayahEndNumber;
    final prefix = surahName.isEmpty ? surah : '$surah $surahName';
    if (endNumber == null || endNumber <= ayah.ayahNumber) {
      return '$prefix / $start';
    }
    final end = _formatReferenceNumber(endNumber, language);
    return '$prefix / $start-$end';
  }

  String _surahNameForLanguage(DailyAyahRecord ayah, String language) {
    final fallback = ayah.surahName.trim();
    if (language == 'ar') {
      return QuranSurahNames.arabicName(ayah.surahNumber, fallback);
    }
    if (language == 'en') {
      return QuranSurahNames.englishName(ayah.surahNumber, fallback);
    }
    return fallback;
  }

  String _formatReferenceNumber(int value, String language) {
    final formatted = value.toString().padLeft(2, '0');
    if (language == 'ar') {
      return _toArabicDigits(formatted);
    }
    return formatted;
  }

  String _hadithReference(DailyHadithRecord hadith, String language) {
    if (language == 'ar') {
      return 'رياض الصالحين ${_toArabicDigits(hadith.hadithNumber)}';
    }
    if (language == 'en') {
      return 'Riyad as-Salihin ${hadith.hadithNumber}';
    }
    return 'Riyazüs-Salihîn ${hadith.hadithNumber}';
  }

  String _toArabicDigits(String value) {
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

  Widget _buildEsmaTab(
    BuildContext context,
    DailyEsmaRecord? record,
    Color contentColor, {
    required String missingText,
  }) {
    if (widget.isLoading) {
      return _buildNote(
        context: context,
        text: _noteLoading,
        contentColor: contentColor,
      );
    }
    if (widget.hasError) {
      return _buildNote(
        context: context,
        text: _noteError,
        contentColor: contentColor,
      );
    }
    if (record == null) {
      return _buildNote(
        context: context,
        text: missingText,
        contentColor: contentColor,
      );
    }
    final activeText = _languageText(record, _activeLanguage);
    final title = _languageTitle(record, _activeLanguage);
    final isRtl = _activeLanguage == 'ar';
    return _DailyContentSection(
      title: title,
      arabicTitle: record.nameArabic,
      latinTitle: isRtl ? '' : title,
      displayText: activeText,
      isRtl: isRtl,
      reference: _esmaReference(record),
      topContentInset: 5,
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFFF9A825),
      infoText: _infoNoteForLanguage(_activeLanguage),
      onReadTap: _activeLanguage == 'tr' && activeText.trim().isNotEmpty
          ? () => _readTurkishText('$title. $activeText')
          : null,
    );
  }

  String _esmaReference(DailyEsmaRecord record) {
    if (record.kind != 'sifat') return '';
    final category = record.category.trim();
    if (category.endsWith('lar') || category.endsWith('ler')) {
      return category.substring(0, category.length - 3);
    }
    return category;
  }

  String _languageText(covariant dynamic record, String language) {
    if (language == 'tr') {
      if (record is DailyAyahRecord) return record.textTr;
      if (record is DailyHadithRecord) return record.textTr;
      final esma = record as DailyEsmaRecord;
      return _joinMeaningAndText(esma.meaningTr, esma.textTr);
    } else if (language == 'en') {
      if (record is DailyAyahRecord) return record.textEn;
      if (record is DailyHadithRecord) return record.textEn;
      final esma = record as DailyEsmaRecord;
      return _joinMeaningAndText(esma.meaningEn, esma.textEn);
    } else {
      if (record is DailyAyahRecord) return record.textAr;
      if (record is DailyHadithRecord) return record.textAr;
      final esma = record as DailyEsmaRecord;
      return _joinMeaningAndText(esma.meaningAr, esma.textAr);
    }
  }

  String _languageTitle(DailyEsmaRecord record, String language) {
    if (language == 'ar') return record.nameArabic;
    if (language == 'en') return record.nameTransliteration;
    return record.nameTurkish;
  }

  String _joinMeaningAndText(String meaning, String text) {
    final first = meaning.trim();
    final second = text.trim();
    if (first.isEmpty) return second;
    if (second.isEmpty || second == first) return first;
    return '$first\n\n$second';
  }

  String _infoNoteForLanguage(String language) {
    if (language == 'ar') return 'ستضاف المعلومات';
    if (language == 'en') return 'Information will be added';
    return 'Bilgi eklenecek';
  }

  Future<void> _readTurkishText(String text) async {
    try {
      await _reminderAudioService.speakText(
        text: text,
        selectedLocale: Localizations.localeOf(context),
      );
    } catch (_) {}
  }

  Future<void> _readTurkishAyahText(String text) {
    return _readTurkishText('$_dailyContentTtsBasmala. $text');
  }

  Widget _buildNote({
    required BuildContext context,
    required String text,
    required Color contentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: contentColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.cizgiColor.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: _isArabicText(text)
            ? TextDirection.rtl
            : TextDirection.ltr,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 17,
          color: widget.cizgiColor.withValues(alpha: 0.9),
          height: 1.35,
        ),
      ),
    );
  }

  bool _isArabicText(String value) {
    return RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    ).hasMatch(value);
  }
}

class _DailyContentSection extends StatefulWidget {
  final String title;
  final String arabicTitle;
  final String latinTitle;
  final String displayText;
  final bool isRtl;
  final String reference;
  final String bookReference;
  final Color cizgiColor;
  final Color contentColor;
  final Color referenceColor;
  final bool showBasmala;
  final double topContentInset;
  final String infoText;
  final VoidCallback? onReadTap;

  const _DailyContentSection({
    required this.title,
    this.arabicTitle = '',
    this.latinTitle = '',
    required this.displayText,
    required this.isRtl,
    required this.reference,
    this.bookReference = '',
    required this.cizgiColor,
    required this.contentColor,
    required this.referenceColor,
    this.showBasmala = false,
    this.topContentInset = 0,
    this.infoText = '',
    this.onReadTap,
  });

  @override
  State<_DailyContentSection> createState() => _DailyContentSectionState();
}

class _DailyContentSectionState extends State<_DailyContentSection> {
  bool _isInfoOpen = false;

  @override
  Widget build(BuildContext context) {
    final refStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: widget.referenceColor,
      fontWeight: FontWeight.w600,
      fontSize: 17,
    );
    final double refFontSize = refStyle?.fontSize ?? 17;
    final hasReadAction = widget.onReadTap != null;
    final infoTextTrimmed = widget.infoText.trim();
    final hasInfoAction = infoTextTrimmed.isNotEmpty;
    final textTrimmed = widget.displayText.trim();
    final isArabic = widget.isRtl && _hasArabic(textTrimmed);
    final titleTrimmed = widget.title.trim();
    final arabicTitleTrimmed = widget.arabicTitle.trim();
    final latinTitleTrimmed = widget.latinTitle.trim();
    final referenceTrimmed = widget.reference.trim();
    final bookReferenceTrimmed = widget.bookReference.trim();
    final hasReference =
        referenceTrimmed.isNotEmpty || bookReferenceTrimmed.isNotEmpty;
    final hasActions = hasInfoAction || hasReadAction;

    final TextStyle displayStyle;
    if (widget.isRtl) {
      displayStyle =
          Theme.of(context).textTheme.bodySmall?.copyWith(
            color: widget.cizgiColor.withValues(alpha: 0.9),
            fontFamily: 'Mirza',
            fontFamilyFallback: const <String>[
              'Lateef',
              'NotoNaskhArabic',
              'Amiri',
              'Arial',
            ],
            fontSize: 22,
            height: 1.45,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ) ??
          TextStyle(
            color: widget.cizgiColor.withValues(alpha: 0.9),
            fontSize: 22,
          );
    } else {
      displayStyle =
          Theme.of(context).textTheme.bodySmall?.copyWith(
            color: widget.cizgiColor.withValues(alpha: 0.85),
            height: 1.4,
            fontSize: 18,
            fontStyle: FontStyle.normal,
          ) ??
          const TextStyle(fontSize: 18);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: widget.contentColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.cizgiColor.withValues(alpha: 0.12),
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _isInfoOpen ? () => setState(() => _isInfoOpen = false) : null,
        child: SingleChildScrollView(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                  if (widget.topContentInset > 0)
                    SizedBox(height: widget.topContentInset),
                  if (arabicTitleTrimmed.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        arabicTitleTrimmed,
                        locale: _dailyContentArabicLocale,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: widget.cizgiColor.withValues(alpha: 0.9),
                              fontFamily: 'Amiri',
                              fontFamilyFallback: const <String>[
                                'NotoNaskhArabic',
                                'Lateef',
                                'Mirza',
                                'Arial',
                              ],
                              fontSize: 32,
                              height: 1.1,
                              fontWeight: FontWeight.normal,
                              letterSpacing: 0,
                            ) ??
                            TextStyle(
                              color: widget.cizgiColor.withValues(alpha: 0.9),
                              fontFamily: 'Amiri',
                              fontSize: 32,
                              height: 1.1,
                              fontWeight: FontWeight.normal,
                            ),
                      ),
                    ),
                    if (latinTitleTrimmed.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          latinTitleTrimmed,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: widget.cizgiColor.withValues(alpha: 0.85),
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                              ) ??
                              TextStyle(
                                color: widget.cizgiColor.withValues(alpha: 0.85),
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                  ] else if (titleTrimmed.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        titleTrimmed,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: widget.cizgiColor.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (textTrimmed.isNotEmpty) ...[
                    if (widget.showBasmala) ...[
                      const _BasmalaMark(),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        textTrimmed,
                        locale: widget.isRtl ? _dailyContentArabicLocale : null,
                        style: displayStyle,
                        textAlign: TextAlign.center,
                        textDirection: isArabic
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        softWrap: true,
                      ),
                    ),
                  ],
                  if (hasReference) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (referenceTrimmed.isNotEmpty)
                            Text(
                              referenceTrimmed,
                              style: refStyle,
                              textAlign: TextAlign.center,
                              textDirection: widget.isRtl
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                            ),
                          if (bookReferenceTrimmed.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              bookReferenceTrimmed,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (refFontSize - 2),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              textDirection: widget.isRtl
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (hasActions) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: hasInfoAction
                              ? _OverlayIconButton(
                                  icon: Icons.info_outline_rounded,
                                  tooltip: 'Bilgi',
                                  onTap: () => setState(() {
                                    _isInfoOpen = !_isInfoOpen;
                                  }),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: hasReadAction
                              ? _OverlayIconButton(
                                  icon: Icons.volume_up_rounded,
                                  tooltip: 'Oku',
                                  onTap: widget.onReadTap!,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                  if (_isInfoOpen && hasInfoAction) ...[
                    const SizedBox(height: 8),
                    _InlineInfoPanel(
                      message: infoTextTrimmed,
                      isRtl: widget.isRtl,
                      cizgiColor: widget.cizgiColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ),
    );
  }

  bool _hasArabic(String value) {
    return RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    ).hasMatch(value);
  }
}

class _InlineInfoPanel extends StatelessWidget {
  final String message;
  final bool isRtl;
  final Color cizgiColor;

  const _InlineInfoPanel({
    required this.message,
    required this.isRtl,
    required this.cizgiColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cizgiColor.withValues(alpha: 0.18)),
      ),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Text(
          message,
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _OverlayIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _BasmalaMark extends StatelessWidget {
  const _BasmalaMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 33,
      child: SvgPicture.asset(
        _dailyContentBasmalaAsset,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}
