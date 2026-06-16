import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/reminder_audio_service.dart';
import '../../../features/daily_content/daily_content_models.dart';
import '../../../features/daily_content/daily_content_selection_models.dart';
import 'home_daily_content_helpers.dart';
import 'home_daily_content_note.dart';
import 'home_daily_content_section.dart';

part 'home_daily_content_panel_tabs.dart';

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

  void _setPanelState(VoidCallback action) {
    if (!mounted) return;
    setState(action);
  }

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
}
