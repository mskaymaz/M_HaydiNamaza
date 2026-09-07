import 'package:flutter/material.dart';

import 'settings_color_action_widgets.dart';
import 'shared_settings/shared_settings_section_styles.dart';

class SettingsInterfaceColorsCard extends StatelessWidget {
  final bool showHelpBalloons;
  final ValueChanged<bool?> onHelpToggleChanged;
  final Color panelColor;
  final Color textColor;
  final Color customPrayerLabelColor;
  final Color backgroundColor;
  final bool hasPendingBackgroundChanges;
  final VoidCallback onEditPanelColor;
  final VoidCallback onEditTextColor;
  final VoidCallback onEditCustomPrayerLabelColor;
  final VoidCallback onEditBackgroundColor;
  final Future<void> Function() onResetInterfaceColors;
  final Future<void> Function() onResetBackgroundColors;
  final Future<void> Function() onApplyBackgroundStyle;

  const SettingsInterfaceColorsCard({
    super.key,
    required this.showHelpBalloons,
    required this.onHelpToggleChanged,
    required this.panelColor,
    required this.textColor,
    required this.customPrayerLabelColor,
    required this.backgroundColor,
    required this.hasPendingBackgroundChanges,
    required this.onEditPanelColor,
    required this.onEditTextColor,
    required this.onEditCustomPrayerLabelColor,
    required this.onEditBackgroundColor,
    required this.onResetInterfaceColors,
    required this.onResetBackgroundColors,
    required this.onApplyBackgroundStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SharedSettingsSectionCard(
      title: 'Arayüz Ayarları',
      headerColor: sharedSettingsMergedColorsHeader,
      showHelpBalloons: showHelpBalloons,
      helpMessage:
          'Bu bölüm ana ekran renklerini ve yardım ikonlarının görünürlüğünü düzenler. Renk değişiklikleri ana sayfaya Uygula düğmesiyle yansır.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: showHelpBalloons,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Yardımları Göster'),
              subtitle: const Text(
                'Soru işareti ikonları ve kısa kullanım açıklamalarını gösterir.',
              ),
              onChanged: onHelpToggleChanged,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SettingsColorActionTile(
                    title: 'Panel Rengi',
                    color: panelColor,
                    onTap: onEditPanelColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SettingsColorActionTile(
                    title: 'Yazı Rengi',
                    color: textColor,
                    onTap: onEditTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SettingsColorActionTile(
                    title: 'Nafile Vakit Rengi',
                    color: customPrayerLabelColor,
                    onTap: onEditCustomPrayerLabelColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SettingsColorActionTile(
                    title: 'Zemin Rengi',
                    color: backgroundColor,
                    onTap: onEditBackgroundColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Not: Seçimler ana sayfaya sadece Uygula butonuyla yansır.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await onResetInterfaceColors();
                  await onResetBackgroundColors();
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Renkleri Varsayılan Yap'),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed:
                    hasPendingBackgroundChanges
                        ? () => onApplyBackgroundStyle()
                        : null,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Uygula'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
