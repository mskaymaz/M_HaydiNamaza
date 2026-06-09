import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/reminder_audio_service.dart';
import '../../../features/daily_content/daily_content_models.dart';
import '../../../features/daily_content/daily_content_selection_models.dart';

const _dailyContentArabicLocale = Locale('ar');

class HomeDailyContentPanel extends StatefulWidget {
  final DailyContentSelectionResult? result;
  final bool isLoading;
  final bool hasError;
  final Color cizgiColor;
  final Color panelColor;
  final double? maxHeight;
  final VoidCallback? onCycleContentTap;

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
  static const String _labelArabic = '\u0639\u0631\u0628\u064A';
  static const String _noteLoading =
      'G\u00FCnl\u00FCk i\u00E7erik y\u00FCkleniyor...';
  static const String _noteError =
      'G\u00FCnl\u00FCk i\u00E7erik \u015Fu an g\u00F6sterilemiyor.';
  static const String _noteAyahMissing =
      'Bug\u00FCn i\u00E7in ayet i\u00E7eri\u011Fi hen\u00FCz haz\u0131r de\u011Fil.';
  static const String _noteHadithMissing =
      'Bug\u00FCn i\u00E7in hadis i\u00E7eri\u011Fi hen\u00FCz haz\u0131r de\u011Fil.';

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
    final frameColor =
        Color.lerp(widget.panelColor, Colors.white, 0.52) ?? widget.panelColor;
    final contentColor = widget.panelColor;
    const panelVerticalPadding = 20.0;
    const defaultPageHeight = 270.0;
    final effectiveMaxHeight = widget.maxHeight == null
        ? null
        : math.max(140.0, widget.maxHeight!);
    final pageHeight = effectiveMaxHeight == null
        ? defaultPageHeight
        : (effectiveMaxHeight - panelVerticalPadding).clamp(140.0, 270.0);

    return Container(
      width: double.infinity,
      constraints: effectiveMaxHeight == null
          ? null
          : BoxConstraints(maxHeight: effectiveMaxHeight),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.panelColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.onCycleContentTap != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: widget.onCycleContentTap,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.shuffle_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            height: pageHeight.toDouble(),
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) {
                final showAyah = index.isEven;
                if (showAyah) {
                  return _buildPage(
                    context: context,
                    heading: _headingAyah,
                    child: _buildAyahTab(context, ayah, contentColor),
                  );
                }
                return _buildPage(
                  context: context,
                  heading: _headingHadith,
                  child: _buildHadithTab(context, hadith, contentColor),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required String heading,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                heading,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
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
        const SizedBox(height: 10),
        Expanded(child: child),
      ],
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
      reference: '${ayah.surahName} ${ayah.ayahNumber}',
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFFF9A825),
      onReadTap: _activeLanguage == 'tr' && activeText.trim().isNotEmpty
          ? () => _readTurkishText(activeText)
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
      reference: '${hadith.collection} ${hadith.hadithNumber}',
      bookReference: hadith.bookReferenceTr,
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFFF9A825),
      onReadTap: _activeLanguage == 'tr' && activeText.trim().isNotEmpty
          ? () => _readTurkishText(activeText)
          : null,
    );
  }

  String _languageText(covariant dynamic record, String language) {
    if (language == 'tr') {
      return (record is DailyAyahRecord) ? record.textTr : (record as DailyHadithRecord).textTr;
    } else if (language == 'en') {
      return (record is DailyAyahRecord) ? record.textEn : (record as DailyHadithRecord).textEn;
    } else {
      return (record is DailyAyahRecord) ? record.textAr : (record as DailyHadithRecord).textAr;
    }
  }

  Future<void> _readTurkishText(String text) async {
    try {
      await _reminderAudioService.speakText(
        text: text,
        selectedLocale: Localizations.localeOf(context),
      );
    } catch (_) {}
  }

  Widget _buildNote({
    required BuildContext context,
    required String text,
    required Color contentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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

class _DailyContentSection extends StatelessWidget {
  final String title;
  final String displayText;
  final bool isRtl;
  final String reference;
  final String bookReference;
  final Color cizgiColor;
  final Color contentColor;
  final Color referenceColor;
  final VoidCallback? onReadTap;

  const _DailyContentSection({
    required this.title,
    required this.displayText,
    required this.isRtl,
    required this.reference,
    this.bookReference = '',
    required this.cizgiColor,
    required this.contentColor,
    required this.referenceColor,
    this.onReadTap,
  });

  @override
  Widget build(BuildContext context) {
    final refStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: referenceColor,
      fontWeight: FontWeight.w600,
      fontSize: 17,
    );
    final double refFontSize = refStyle?.fontSize ?? 17;
    final hasReadAction = onReadTap != null;
    final textTrimmed = displayText.trim();
    final isArabic = isRtl && _hasArabic(textTrimmed);

    final TextStyle displayStyle;
    if (isRtl) {
      displayStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        fontFamily: 'Mirza',
        fontFamilyFallback: const <String>[
          'Lateef', 'NotoNaskhArabic', 'Amiri', 'Arial',
        ],
        fontSize: 22,
        height: 1.45,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ) ?? const TextStyle(fontSize: 22);
    } else {
      displayStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
        color: cizgiColor.withValues(alpha: 0.85),
        height: 1.4,
        fontSize: 18,
        fontStyle: FontStyle.normal,
      ) ?? const TextStyle(fontSize: 18);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: contentColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cizgiColor.withValues(alpha: 0.12)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (title.trim().isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cizgiColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (textTrimmed.isNotEmpty) ...[
              Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: hasReadAction ? 24 : 0,
                      right: hasReadAction ? 30 : 0,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        textTrimmed,
                        locale: isRtl ? _dailyContentArabicLocale : null,
                        style: displayStyle,
                        textAlign: TextAlign.center,
                        textDirection: isArabic
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        softWrap: true,
                      ),
                    ),
                  ),
                  if (hasReadAction)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: onReadTap,
                          borderRadius: BorderRadius.circular(14),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.volume_up_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(reference, style: refStyle),
                  if (bookReference.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      bookReference,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (refFontSize - 2),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
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
