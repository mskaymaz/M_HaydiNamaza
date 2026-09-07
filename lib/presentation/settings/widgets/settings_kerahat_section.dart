import 'package:flutter/material.dart';

import 'shared_settings/shared_settings_section_styles.dart';
import 'settings_reminder_fields.dart';

class SettingsKerahatSection extends StatelessWidget {
  final bool kerahatEnabled;
  final TextEditingController kerahatSunriseMinutesController;
  final TextEditingController kerahatDhuhrMinutesController;
  final TextEditingController kerahatMaghribMinutesController;
  final ValueChanged<bool> onKerahatToggleChanged;
  final ValueChanged<String> onKerahatSunriseMinutesChanged;
  final ValueChanged<String> onKerahatDhuhrMinutesChanged;
  final ValueChanged<String> onKerahatMaghribMinutesChanged;
  final Widget Function({
    required String title,
    required Color color,
    required String helpMessage,
  }) buildSubHeader;

  const SettingsKerahatSection({
    super.key,
    required this.kerahatEnabled,
    required this.kerahatSunriseMinutesController,
    required this.kerahatDhuhrMinutesController,
    required this.kerahatMaghribMinutesController,
    required this.onKerahatToggleChanged,
    required this.onKerahatSunriseMinutesChanged,
    required this.onKerahatDhuhrMinutesChanged,
    required this.onKerahatMaghribMinutesChanged,
    required this.buildSubHeader,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSubHeader(
          title: 'Kerahat Vakti Uyarısı',
          color: sharedSettingsKerahatHeader,
          helpMessage:
              'Kerahat vakitlerinde (Güneş doğarken, öğle öncesi istiva vakti ve akşam öncesi güneş sararırken) üst panelde uyarısını gösterir.',
        ),
        CheckboxListTile(
          value: kerahatEnabled,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Kerahat Vakti Uyarısı'),
          subtitle: const Text(
            'Kerahat vakti girdiğinde üst panelde yanıp sönen uyarı rozeti görüntülenir.',
          ),
          onChanged: (value) {
            onKerahatToggleChanged(value ?? true);
          },
        ),
        if (kerahatEnabled) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SettingsReminderNumberField(
                  label: 'Güneş (dk)',
                  controller: kerahatSunriseMinutesController,
                  onChanged: onKerahatSunriseMinutesChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SettingsReminderNumberField(
                  label: 'Öğle Öncesi (dk)',
                  controller: kerahatDhuhrMinutesController,
                  onChanged: onKerahatDhuhrMinutesChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SettingsReminderNumberField(
                  label: 'Akşam Öncesi (dk)',
                  controller: kerahatMaghribMinutesController,
                  onChanged: onKerahatMaghribMinutesChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Varsayılan kerahat süreleri 45 dakikadır.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
