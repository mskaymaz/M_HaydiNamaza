import 'package:flutter/material.dart';

import '../../../features/daily_content/daily_content_models.dart';
import '../../../features/daily_content/daily_content_selection_models.dart';

class HomeDailyContentPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ayah = result?.ayah;
    final hadith = result?.hadith;
    final frameColor = Color.lerp(panelColor, Colors.white, 0.42) ?? panelColor;
    final contentColor = panelColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: panelColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 240,
            child: PageView.builder(
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
        Text(
          heading,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildAyahTab(
    BuildContext context,
    DailyAyahRecord? ayah,
    Color contentColor,
  ) {
    if (isLoading) {
      return _buildNote(
        context: context,
        text: 'Günlük içerik yükleniyor...',
        contentColor: contentColor,
      );
    }
    if (hasError) {
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
      text: ayah.text,
      subText: ayah.translation,
      reference: '${ayah.surahName} ${ayah.ayahNumber}',
      cizgiColor: cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFF1B5E20),
    );
  }

  Widget _buildHadithTab(
    BuildContext context,
    DailyHadithRecord? hadith,
    Color contentColor,
  ) {
    if (isLoading) {
      return _buildNote(
        context: context,
        text: 'Günlük içerik yükleniyor...',
        contentColor: contentColor,
      );
    }
    if (hasError) {
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
      text: hadith.text,
      subText: hadith.translation,
      reference: '${hadith.collection} ${hadith.hadithNumber}',
      cizgiColor: cizgiColor,
      contentColor: contentColor,
      referenceColor: const Color(0xFF0D1B5E),
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
        border: Border.all(color: cizgiColor.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 15,
          color: cizgiColor.withValues(alpha: 0.9),
          height: 1.35,
        ),
      ),
    );
  }
}

class _DailyContentSection extends StatelessWidget {
  final String title;
  final String text;
  final String subText;
  final String reference;
  final Color cizgiColor;
  final Color contentColor;
  final Color referenceColor;

  const _DailyContentSection({
    required this.title,
    required this.text,
    required this.subText,
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
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(
      color: cizgiColor,
      height: 1.35,
      fontSize: 15,
    );
    final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: cizgiColor.withValues(alpha: 0.85),
      height: 1.3,
      fontSize: 15,
      fontStyle: FontStyle.italic,
    );
    final refStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: referenceColor,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );

    final textIsArabic = _hasArabic(text);
    final subTextIsArabic = _hasArabic(subText);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.trim().isNotEmpty) ...[
              Text(title, style: titleStyle),
              const SizedBox(height: 4),
            ],
            Text(
              text,
              style: textStyle,
              textAlign: textIsArabic ? TextAlign.right : TextAlign.left,
            ),
            if (subText.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subText,
                style: subStyle,
                textAlign: subTextIsArabic ? TextAlign.right : TextAlign.left,
              ),
            ],
            const SizedBox(height: 10),
            Center(child: Text(reference, style: refStyle)),
          ],
        ),
      ),
    );
  }

  bool _hasArabic(String value) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(value);
  }
}
