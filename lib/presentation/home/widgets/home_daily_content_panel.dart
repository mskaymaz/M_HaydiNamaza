import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/reminder_audio_service.dart';
import '../../settings/voice_scan_dialog.dart';
import '../../../features/daily_content/daily_content_models.dart';
import '../../../features/daily_content/daily_content_selection_models.dart';

class HomeDailyContentPanel extends StatefulWidget {
  final DailyContentSelectionResult? result;
  final bool isLoading;
  final bool hasError;
  final Color cizgiColor;
  final Color panelColor;
  final double? maxHeight;

  const HomeDailyContentPanel({
    super.key,
    required this.result,
    required this.isLoading,
    required this.hasError,
    required this.cizgiColor,
    required this.panelColor,
    this.maxHeight,
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
  bool _showTurkish = true;
  bool _showEnglish = true;
  bool _showArabic = true;
  bool _languageDefaultsApplied = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000);
    _dumpEnglishArabicVoices();
  }

  Future<void> _dumpEnglishArabicVoices() async {
    try {
      final voices = await _reminderAudioService.loadVoiceOptions();
      final englishVoices = voices
          .where((voice) => voice.locale.toLowerCase().startsWith('en'))
          .toList();
      final arabicVoices = voices
          .where((voice) => voice.locale.toLowerCase().startsWith('ar'))
          .toList();
      debugPrint('[TTS][en] count=${englishVoices.length}');
      for (final voice in englishVoices) {
        debugPrint('[TTS][en] ${voice.label}');
      }
      debugPrint('[TTS][ar] count=${arabicVoices.length}');
      for (final voice in arabicVoices) {
        debugPrint('[TTS][ar] ${voice.label}');
      }
    } catch (error, stackTrace) {
      debugPrint('[TTS] voice dump failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
      _showTurkish = true;
      _showEnglish = false;
      _showArabic = false;
    } else if (languageCode == 'en') {
      _showTurkish = false;
      _showEnglish = true;
      _showArabic = false;
    } else if (languageCode == 'ar') {
      _showTurkish = false;
      _showEnglish = false;
      _showArabic = true;
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
              selected: _showTurkish,
              onTap: () => _toggleLanguage('tr'),
            ),
            const SizedBox(width: 8),
            _buildLanguageToggle(
              label: 'EN',
              selected: _showEnglish,
              onTap: () => _toggleLanguage('en'),
            ),
            const SizedBox(width: 8),
            _buildLanguageToggle(
              label: _labelArabic,
              selected: _showArabic,
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
    final activeCount =
        (_showTurkish ? 1 : 0) + (_showEnglish ? 1 : 0) + (_showArabic ? 1 : 0);
    final isActive = switch (code) {
      'tr' => _showTurkish,
      'en' => _showEnglish,
      'ar' => _showArabic,
      _ => false,
    };

    if (isActive && activeCount == 1) {
      return;
    }

    setState(() {
      if (code == 'tr') {
        _showTurkish = !_showTurkish;
      } else if (code == 'en') {
        _showEnglish = !_showEnglish;
      } else if (code == 'ar') {
        _showArabic = !_showArabic;
      }
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
    return _DailyContentSection(
      title: '',
      arabicText: ayah.textAr,
      turkishText: ayah.textTr,
      englishText: ayah.textEn,
      showArabic: _showArabic,
      showTurkish: _showTurkish,
      showEnglish: _showEnglish,
      reference: '${ayah.surahName} ${ayah.ayahNumber}',
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFFF9A825),
      onReadTurkishTap: _showTurkish && ayah.textTr.trim().isNotEmpty
          ? () => _readTurkishText(ayah.textTr)
          : null,
      onReadEnglishTap: _showEnglish && ayah.textEn.trim().isNotEmpty
          ? () => _readEnglishText(ayah.textEn)
          : null,
      onReadArabicTap: _showArabic && ayah.textAr.trim().isNotEmpty
        ? () => _readArabicText(ayah.textAr)
        : null,
      onScanArabicTap: _showArabic && ayah.textAr.trim().isNotEmpty
        ? () => _openArabicVoiceScanner(ayah.textAr)
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
    return _DailyContentSection(
      title: '',
      arabicText: hadith.textAr,
      turkishText: hadith.textTr,
      englishText: hadith.textEn,
      showArabic: _showArabic,
      showTurkish: _showTurkish,
      showEnglish: _showEnglish,
      reference: '${hadith.collection} ${hadith.hadithNumber}',
      cizgiColor: widget.cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFFF9A825),
      onReadTurkishTap: _showTurkish && hadith.textTr.trim().isNotEmpty
          ? () => _readTurkishText(hadith.textTr)
          : null,
      onReadEnglishTap: _showEnglish && hadith.textEn.trim().isNotEmpty
          ? () => _readEnglishText(hadith.textEn)
          : null,
      onReadArabicTap: _showArabic && hadith.textAr.trim().isNotEmpty
        ? () => _readArabicText(hadith.textAr)
        : null,
      onScanArabicTap: _showArabic && hadith.textAr.trim().isNotEmpty
        ? () => _openArabicVoiceScanner(hadith.textAr)
        : null,
    );
  }

  Future<void> _readTurkishText(String text) async {
    try {
      await _reminderAudioService.speakText(
        text: text,
        selectedLocale: Localizations.localeOf(context),
      );
    } catch (_) {}
  }

  Future<void> _readEnglishText(String text) async {
    try {
      await _reminderAudioService.speakText(
        text: text,
        selectedLocale: const Locale('en'),
      );
    } catch (_) {}
  }

  Future<void> _readArabicText(String text) async {
    try {
      await _reminderAudioService.speakText(
        text: text,
        selectedLocale: const Locale('ar'),
      );
    } catch (_) {}
  }

  Future<void> _openArabicVoiceScanner(String sampleText) async {
    try {
      final voices = await _reminderAudioService.loadVoiceOptions();
      final arabic = voices.where((v) => v.locale.toLowerCase().startsWith('ar')).toList();
      if (arabic.isEmpty) return;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => VoiceScanDialog(
          reminderAudioService: _reminderAudioService,
          arabicVoices: arabic,
          sampleText: sampleText,
        ),
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
  final String arabicText;
  final String turkishText;
  final String englishText;
  final bool showArabic;
  final bool showTurkish;
  final bool showEnglish;
  final String reference;
  final Color cizgiColor;
  final Color contentColor;
  final Color referenceColor;
  final VoidCallback? onReadTurkishTap;
  final VoidCallback? onReadEnglishTap;
  final VoidCallback? onReadArabicTap;
  final VoidCallback? onScanArabicTap;

  const _DailyContentSection({
    required this.title,
    required this.arabicText,
    required this.turkishText,
    required this.englishText,
    required this.showArabic,
    required this.showTurkish,
    required this.showEnglish,
    required this.reference,
    required this.cizgiColor,
    required this.contentColor,
    required this.referenceColor,
    required this.onReadTurkishTap,
    required this.onReadEnglishTap,
    required this.onReadArabicTap,
    required this.onScanArabicTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: cizgiColor.withValues(alpha: 0.85),
      fontWeight: FontWeight.w700,
    );
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: cizgiColor,
      height: 1.35,
      fontSize: 17,
    );
    final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: cizgiColor.withValues(alpha: 0.85),
      height: 1.3,
      fontSize: 17,
      fontStyle: FontStyle.italic,
    );
    final refStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: referenceColor,
      fontWeight: FontWeight.w600,
      fontSize: 17,
    );
    final hasTurkishReadAction = onReadTurkishTap != null;
    final hasArabicReadAction = onReadArabicTap != null;
    final hasEnglishReadAction = onReadEnglishTap != null;

    final textArIsArabic = _hasArabic(arabicText);
    final textTrIsArabic = _hasArabic(turkishText);
    final textEnIsArabic = _hasArabic(englishText);

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.trim().isNotEmpty) ...[
              Text(title, style: titleStyle),
              const SizedBox(height: 4),
            ],
            if (showArabic && arabicText.trim().isNotEmpty) ...[
              Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: hasArabicReadAction ? 24 : 0),
                    child: Text(
                      arabicText,
                      style: textStyle,
                      textAlign: TextAlign.center,
                      textDirection: textArIsArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                    ),
                  ),
                  if (hasArabicReadAction || onScanArabicTap != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.black.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: onReadArabicTap,
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
                          if (onScanArabicTap != null) ...[
                            const SizedBox(width: 6),
                            Material(
                              color: Colors.black.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: onScanArabicTap,
                                borderRadius: BorderRadius.circular(14),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (showTurkish && turkishText.trim().isNotEmpty) ...[
              if (showArabic && arabicText.trim().isNotEmpty)
                const SizedBox(height: 15),
              Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: hasTurkishReadAction ? 24 : 0),
                    child: Padding(
                      padding: EdgeInsets.only(right: hasTurkishReadAction ? 30 : 0),
                      child: Text(
                        turkishText,
                        style: subStyle,
                        textAlign: TextAlign.center,
                        textDirection: textTrIsArabic
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                      ),
                    ),
                  ),
                  if (hasTurkishReadAction)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: onReadTurkishTap,
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
            if (showEnglish && englishText.trim().isNotEmpty) ...[
              if ((showArabic && arabicText.trim().isNotEmpty) ||
                  (showTurkish && turkishText.trim().isNotEmpty))
                const SizedBox(height: 15),
              Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: hasEnglishReadAction ? 24 : 0),
                    child: Text(
                      englishText,
                      style: subStyle?.copyWith(fontStyle: FontStyle.normal),
                      textAlign: TextAlign.center,
                      textDirection: textEnIsArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                    ),
                  ),
                  if (hasEnglishReadAction)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: onReadEnglishTap,
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
            Center(child: Text(reference, style: refStyle)),
          ],
        ),
      ),
    );
  }

  bool _hasArabic(String value) {
    final arabicRegex = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    );
    return arabicRegex.hasMatch(value);
  }
}
