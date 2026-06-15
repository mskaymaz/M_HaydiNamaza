import 'package:flutter/material.dart';

import 'home_daily_content_helpers.dart';

class DailyContentNote extends StatelessWidget {
  final String text;
  final Color cizgiColor;
  final Color contentColor;

  const DailyContentNote({
    super.key,
    required this.text,
    required this.cizgiColor,
    required this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: contentColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cizgiColor.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        textDirection: dailyContentHasArabic(text)
            ? TextDirection.rtl
            : TextDirection.ltr,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 17,
          color: cizgiColor.withValues(alpha: 0.9),
          height: 1.35,
        ),
      ),
    );
  }
}
