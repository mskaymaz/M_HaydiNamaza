import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';

class SettingsReminderOptionsSection extends StatelessWidget {
  final EdgeInsets outerPadding;
  final SurfaceStyle panelStyle;
  final Widget reminderOptionsHeader;
  final Widget vibrationHeader;
  final Widget voiceToggle;
  final Widget visualToggle;
  final Widget azanToggle;
  final Widget vibrationToggle;
  final bool sortCustomPrayersByTime;
  final ValueChanged<bool?> onSortChanged;
  final Widget vibrationDurationField;
  final Widget vibrationPauseField;

  const SettingsReminderOptionsSection({
    super.key,
    required this.outerPadding,
    required this.panelStyle,
    required this.reminderOptionsHeader,
    required this.vibrationHeader,
    required this.voiceToggle,
    required this.visualToggle,
    required this.azanToggle,
    required this.vibrationToggle,
    required this.sortCustomPrayersByTime,
    required this.onSortChanged,
    required this.vibrationDurationField,
    required this.vibrationPauseField,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: outerPadding,
      child: _SectionPanel(
        style: panelStyle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            reminderOptionsHeader,
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: voiceToggle),
                Expanded(child: visualToggle),
                Expanded(child: azanToggle),
                Expanded(child: vibrationToggle),
              ],
            ),
            const SizedBox(height: 8),
            Divider(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1,
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: sortCustomPrayersByTime,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Nafileler vakitlere göre sıralansın'),
              subtitle: const Text(
                'Kapalıysa nafileler listenin en altında kalır.',
              ),
              onChanged: onSortChanged,
            ),
            const SizedBox(height: 8),
            Divider(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1,
            ),
            const SizedBox(height: 10),
            vibrationHeader,
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: vibrationDurationField),
                const SizedBox(width: 8),
                Expanded(child: vibrationPauseField),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final SurfaceStyle style;
  final Widget child;

  const _SectionPanel({
    required this.style,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: style.borderRadius,
        boxShadow: style.shadows,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}
