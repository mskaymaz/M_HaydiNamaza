part of 'home_daily_content_panel.dart';

extension _HomeDailyContentPanelTabs on _HomeDailyContentPanelState {
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
                        label: _HomeDailyContentPanelState._labelArabic,
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
    _setPanelState(() {
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
        text: _HomeDailyContentPanelState._noteLoading,
        contentColor: contentColor,
      );
    }
    if (widget.hasError) {
      return _buildNote(
        context: context,
        text: _HomeDailyContentPanelState._noteError,
        contentColor: contentColor,
      );
    }
    if (ayah == null) {
      return _buildNote(
        context: context,
        text: _HomeDailyContentPanelState._noteAyahMissing,
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
        text: _HomeDailyContentPanelState._noteLoading,
        contentColor: contentColor,
      );
    }
    if (widget.hasError) {
      return _buildNote(
        context: context,
        text: _HomeDailyContentPanelState._noteError,
        contentColor: contentColor,
      );
    }
    if (hadith == null) {
      return _buildNote(
        context: context,
        text: _HomeDailyContentPanelState._noteHadithMissing,
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
        text: _HomeDailyContentPanelState._noteLoading,
        contentColor: contentColor,
      );
    }
    if (widget.hasError) {
      return _buildNote(
        context: context,
        text: _HomeDailyContentPanelState._noteError,
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
