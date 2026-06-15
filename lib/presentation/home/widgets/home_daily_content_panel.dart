import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/reminder_audio_service.dart';
import '../../../features/daily_content/daily_content_models.dart';
import '../../../features/daily_content/daily_content_selection_models.dart';
import 'home_daily_content_helpers.dart';
import 'home_daily_content_note.dart';
import 'home_daily_content_section.dart';

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
    const minPanelHeight = 140.0;
    const defaultPanelHeight = 270.0;
    final requestedPanelHeight = widget.maxHeight == null
        ? defaultPanelHeight
        : math.max(minPanelHeight, widget.maxHeight!);

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelHeight = constraints.hasBoundedHeight
            ? math.max(
                0.0,
                math.min(requestedPanelHeight, constraints.maxHeight),
              )
            : requestedPanelHeight;
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            height: panelHeight,
            constraints: BoxConstraints(maxHeight: panelHeight),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            decoration: BoxDecoration(
              color: frameColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.panelColor.withValues(alpha: 0.35),
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: SizedBox.expand(
              child: PageView.builder(
                clipBehavior: Clip.hardEdge,
                controller: _pageController,
                itemBuilder: (context, index) {
                  final page = index % 4;
                  if (page == 0) {
                    return _buildPage(
                      context: context,
                      kind: DailyContentPanelKind.ayah,
                      child: _buildAyahTab(context, ayah, contentColor),
                    );
                  }
                  if (page == 1) {
                    return _buildPage(
                      context: context,
                      kind: DailyContentPanelKind.hadith,
                      child: _buildHadithTab(context, hadith, contentColor),
                    );
                  }
                  if (page == 2) {
                    return _buildPage(
                      context: context,
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
      },
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required DailyContentPanelKind kind,
    required Widget child,
  }) {
    final heading = _headingFor(kind);
    return ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 36,
            child: Row(
              children: [
                const SizedBox(width: 25),
                Expanded(
                  child: Text(
                    heading,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: _activeLanguage == 'ar' ? 23 : 20,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCycleButton(kind),
                      const SizedBox(width: 6),
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

  String _headingFor(DailyContentPanelKind kind) {
    switch (_activeLanguage) {
      case 'en':
        return switch (kind) {
          DailyContentPanelKind.ayah => 'Daily Ayah',
          DailyContentPanelKind.hadith => 'Daily Hadith',
          DailyContentPanelKind.esma => 'Asma al-Husna',
          DailyContentPanelKind.sifat => 'Attributes of Allah',
        };
      case 'ar':
        return switch (kind) {
          DailyContentPanelKind.ayah => 'آية اليوم',
          DailyContentPanelKind.hadith => 'حديث اليوم',
          DailyContentPanelKind.esma => 'أسماء الله الحسنى',
          DailyContentPanelKind.sifat => 'صفات الله',
        };
      default:
        return switch (kind) {
          DailyContentPanelKind.ayah => 'Günün Ayeti',
          DailyContentPanelKind.hadith => 'Günün Hadisi',
          DailyContentPanelKind.esma => 'Esmâül Hüsnâ',
          DailyContentPanelKind.sifat => 'Allah\'ın Sıfatları',
        };
    }
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
    final activeText = dailyContentLanguageText(ayah, _activeLanguage);
    final isRtl = _activeLanguage == 'ar';
    return DailyContentSection(
      title: '',
      displayText: activeText,
      isRtl: isRtl,
      reference: dailyContentAyahReference(ayah, _activeLanguage),
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFFF9A825),
      showBasmala: true,
      infoText: dailyContentInfoNoteForLanguage(_activeLanguage),
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
    final activeText = dailyContentLanguageText(hadith, _activeLanguage);
    final isRtl = _activeLanguage == 'ar';
    return DailyContentSection(
      title: '',
      displayText: activeText,
      isRtl: isRtl,
      reference: dailyContentHadithReference(hadith, _activeLanguage),
      bookReference: hadith.bookReferenceTr,
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFFF9A825),
      showBasmala: true,
      infoText: dailyContentInfoNoteForLanguage(_activeLanguage),
      onReadTap: _activeLanguage == 'tr' && activeText.trim().isNotEmpty
          ? () => _readTurkishText(activeText)
          : null,
    );
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
    final activeText = dailyContentLanguageText(record, _activeLanguage);
    final title = dailyContentLanguageTitle(record, _activeLanguage);
    final isRtl = _activeLanguage == 'ar';
    return DailyContentSection(
      title: title,
      arabicTitle: record.nameArabic,
      latinTitle: isRtl ? '' : title,
      displayText: activeText,
      isRtl: isRtl,
      reference: dailyContentEsmaReference(record),
      topContentInset: 5,
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFFF9A825),
      showBasmala: true,
      infoText: dailyContentInfoNoteForLanguage(_activeLanguage),
      onReadTap: _activeLanguage == 'tr' && activeText.trim().isNotEmpty
          ? () => _readTurkishText('$title. $activeText')
          : null,
    );
  }

  Future<void> _readTurkishText(String text) async {
    try {
      await _reminderAudioService.speakText(
        text: text,
        selectedLocale: const Locale('tr', 'TR'),
      );
    } catch (_) {}
  }

  Future<void> _readTurkishAyahText(String text) {
    final cleanedText = _stripAyahNumberMarkersForTts(text);
    return _readTurkishText('$_dailyContentTtsBasmala. $cleanedText');
  }

  String _stripAyahNumberMarkersForTts(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'(^|\n)\s*\([0-9٠-٩۰-۹]+\)\s*'),
          (match) => match.group(1) ?? '',
        )
        .trim();
  }

  Widget _buildNote({
    required BuildContext context,
    required String text,
    required Color contentColor,
  }) {
    return DailyContentNote(
      text: text,
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
    );
  }
}
