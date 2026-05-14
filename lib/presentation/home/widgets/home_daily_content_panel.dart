import 'package:flutter/material.dart';

import '../../../features/daily_content/daily_content_models.dart';
import '../../../features/daily_content/daily_content_selection_models.dart';

class HomeDailyContentPanel extends StatefulWidget {
  final DailyContentSelectionResult? result;
  final bool isLoading;
  final bool hasError;
  final Color cizgiColor;
  final Color panelColor;

  const HomeDailyContentPanel({
    super.key,
    required this.result,
    required this.isLoading,
    required this.hasError,
    required this.cizgiColor,
    required this.panelColor,
  });

  @override
  State<HomeDailyContentPanel> createState() => _HomeDailyContentPanelState();
}

class _HomeDailyContentPanelState extends State<HomeDailyContentPanel> {
  late final PageController _pageController;
  bool _showTurkish = true;
  bool _showEnglish = true;
  bool _showArabic = true;
  bool _languageDefaultsApplied = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        Color.lerp(widget.panelColor, Colors.white, 0.42) ?? widget.panelColor;
    final contentColor = widget.panelColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.panelColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) {
                final showAyah = index.isEven;
                if (showAyah) {
                  return _buildPage(
                    context: context,
                    heading: 'Günün Ayeti',
                    child: _buildAyahTab(context, ayah, contentColor),
                  );
                }
                return _buildPage(
                  context: context,
                  heading: 'Günün Hadisi',
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
              label: 'عربي',
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
              color: (selected
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
        text: 'Günlük içerik yükleniyor...',
        contentColor: contentColor,
      );
    }
    if (widget.hasError) {
      return _buildNote(
        context: context,
        text: 'Günlük içerik şu an gösterilemiyor.',
        contentColor: contentColor,
      );
    }
    if (ayah == null) {
      return _buildNote(
        context: context,
        text: 'Bugün için ayet içeriği henüz hazır değil.',
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
        text: 'Günlük içerik yükleniyor...',
        contentColor: contentColor,
      );
    }
    if (widget.hasError) {
      return _buildNote(
        context: context,
        text: 'Günlük içerik şu an gösterilemiyor.',
        contentColor: contentColor,
      );
    }
    if (hadith == null) {
      return _buildNote(
        context: context,
        text: 'Bugün için hadis içeriği henüz hazır değil.',
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
    );
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
              Text(
                arabicText,
                style: textStyle,
                textAlign: TextAlign.center,
                textDirection: textArIsArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
            ],
            if (showTurkish && turkishText.trim().isNotEmpty) ...[
              if (showArabic && arabicText.trim().isNotEmpty)
                const SizedBox(height: 15),
              Text(
                turkishText,
                style: subStyle,
                textAlign: TextAlign.center,
                textDirection: textTrIsArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
              ),
            ],
            if (showEnglish && englishText.trim().isNotEmpty) ...[
              if (
                  (showArabic && arabicText.trim().isNotEmpty) ||
                      (showTurkish && turkishText.trim().isNotEmpty))
              const SizedBox(height: 15),
              Text(
                englishText,
                style: subStyle?.copyWith(fontStyle: FontStyle.normal),
                textAlign: TextAlign.center,
                textDirection: textEnIsArabic
                    ? TextDirection.rtl
                    : TextDirection.ltr,
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
