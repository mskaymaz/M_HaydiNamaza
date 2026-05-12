import 'package:flutter/material.dart';

import '../../../features/daily_content/daily_content_selection_models.dart';

class HomeDailyContentPanel extends StatelessWidget {
  final DailyContentSelectionResult? result;
  final bool isLoading;
  final bool hasError;
  final Color cizgiColor;

  const HomeDailyContentPanel({
    super.key,
    required this.result,
    required this.isLoading,
    required this.hasError,
    required this.cizgiColor,
  });

  @override
  Widget build(BuildContext context) {
    final ayah = result?.ayah;
    final hadith = result?.hadith;
    final hasContent = ayah != null || hadith != null;
    final hasWarnings =
        (result?.warnings.isNotEmpty ?? false) || (result?.skippedCount ?? 0) > 0;
    final bodyStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(height: 1.35, color: cizgiColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cizgiColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gunluk Ayet ve Hadis',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: cizgiColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (isLoading)
            _buildNote(
              context: context,
              text: 'Gunluk icerik yukleniyor...',
            )
          else if (hasError)
            _buildNote(
              context: context,
              text: 'Gunluk icerik su an gosterilemiyor.',
            )
          else if (!hasContent)
            _buildNote(
              context: context,
              text: 'Bugun icin onayli icerik henuz hazir degil.',
            )
          else ...[
            if (ayah != null)
              _DailyContentSection(
                title: 'Ayet',
                text: ayah.text,
                subText: ayah.translation,
                reference: '${ayah.surahName} ${ayah.ayahNumber}',
                cizgiColor: cizgiColor,
              ),
            if (ayah != null && hadith != null) const SizedBox(height: 8),
            if (hadith != null)
              _DailyContentSection(
                title: 'Hadis',
                text: hadith.text,
                subText: hadith.translation,
                reference: '${hadith.collection} ${hadith.hadithNumber}',
                cizgiColor: cizgiColor,
              ),
            if (hasWarnings) ...[
              const SizedBox(height: 8),
              Text(
                'Icerik notlari bulundu; secim guvenli sekilde gosteriliyor.',
                style: bodyStyle?.copyWith(
                  fontSize: 11,
                  color: cizgiColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildNote({required BuildContext context, required String text}) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: cizgiColor.withValues(alpha: 0.85)),
    );
  }
}

class _DailyContentSection extends StatelessWidget {
  final String title;
  final String text;
  final String subText;
  final String reference;
  final Color cizgiColor;

  const _DailyContentSection({
    required this.title,
    required this.text,
    required this.subText,
    required this.reference,
    required this.cizgiColor,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: cizgiColor.withValues(alpha: 0.85),
      fontWeight: FontWeight.w700,
    );
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: cizgiColor, height: 1.35);
    final subStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: cizgiColor.withValues(alpha: 0.85),
      height: 1.3,
      fontSize: 11,
      fontStyle: FontStyle.italic,
    );
    final refStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: cizgiColor.withValues(alpha: 0.75),
      fontWeight: FontWeight.w600,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cizgiColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 4),
          Text(text, style: textStyle, maxLines: 4, overflow: TextOverflow.ellipsis),
          if (subText.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subText,
              style: subStyle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(reference, style: refStyle),
        ],
      ),
    );
  }
}
