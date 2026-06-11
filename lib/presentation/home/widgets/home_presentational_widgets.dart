import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import '../../reminders/flashing_reminder_card.dart';

class HomeReminderChip extends StatelessWidget {
  final TextEditingController controller;
  final InlineChipStyle style;
  final Color cizgiColor;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;

  const HomeReminderChip({
    super.key,
    required this.controller,
    required this.style,
    required this.cizgiColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: style.width,
      child: InkWell(
        borderRadius: style.borderRadius,
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: backgroundColor,
            contentPadding: EdgeInsets.symmetric(vertical: style.verticalPadding),
            enabledBorder: OutlineInputBorder(
              borderRadius: style.borderRadius,
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: style.borderRadius,
              borderSide: BorderSide(color: cizgiColor),
            ),
          ),
          child: Text(
            controller.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cizgiColor,
              fontWeight: FontWeight.w700,
              fontSize: style.fontSize,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeIconToggle extends StatelessWidget {
  final IconData icon;
  final InlineIconStyle style;
  final bool isEnabled;
  final Color cizgiColor;
  final VoidCallback onTap;

  const HomeIconToggle({
    super.key,
    required this.icon,
    required this.style,
    required this.isEnabled,
    required this.cizgiColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isEnabled
        ? cizgiColor
        : cizgiColor.withValues(alpha: 0.4);
    final hitSize = style.size * 1.3;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: hitSize,
        height: hitSize,
        child: Center(
          child: Icon(icon, size: style.iconSize, color: iconColor),
        ),
      ),
    );
  }
}

class HomeActiveReminderPanel extends StatelessWidget {
  final String? voicePrayerLabel;
  final String? visualPrayerLabel;
  final String? visualMessage;
  final bool showVisualCard;
  final VoidCallback onCloseVoice;
  final VoidCallback onCloseVisual;

  const HomeActiveReminderPanel({
    super.key,
    required this.voicePrayerLabel,
    required this.visualPrayerLabel,
    required this.visualMessage,
    required this.showVisualCard,
    required this.onCloseVoice,
    required this.onCloseVisual,
  });

  String _toTurkishUpper(String value) {
    return value.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasVoice = (voicePrayerLabel ?? '').trim().isNotEmpty;
    final hasVisual = (visualPrayerLabel ?? '').trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasVisual && showVisualCard) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCloseVisual,
            child: FlashingReminderCard(
              prayerLabel: '${_toTurkishUpper(visualPrayerLabel!)} VAKTİ',
              message: visualMessage ?? '',
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              if (hasVoice)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCloseVoice,
                    icon: const Icon(Icons.volume_off_outlined),
                    label: Text('${voicePrayerLabel!} Sesli Kapat'),
                  ),
                ),
              if (hasVoice && hasVisual) const SizedBox(width: 8),
              if (hasVisual)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCloseVisual,
                    icon: const Icon(Icons.close_fullscreen_outlined),
                    label: Text('${visualPrayerLabel!} Görsel Kapat'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
