import 'package:flutter/material.dart';

import '../../../../app/adhan_catalog.dart';
import '../../../../app/reminder_text_settings_storage.dart';
import '../../../../core/config/config_registry.dart';
import '../../settings_audio_mode_texts.dart';
import '../settings_color_action_widgets.dart';
import '../settings_reminder_fields.dart';
import '../settings_adhan_selection_section.dart';
import 'shared_settings_section_styles.dart';

class SettingsLegacyAccordionGroup extends StatelessWidget {
  final EdgeInsets outerPadding;
  final SurfaceStyle panelStyle;
  final bool showVoiceIcon;
  final bool showAzanIcon;
  final bool showVibrationIcon;
  final bool sortCustomPrayersByTime;
  final bool showHelpBalloons;
  final Map<String, AdhanSelection> adhanSelections;
  final Set<String> downloadingAdhanPrayerKeys;
  final TextEditingController vibrationDurationController;
  final TextEditingController vibrationPauseController;
  final ValueChanged<String> onUseDefaultAdhan;
  final Future<void> Function(String prayerKey, AdhanCatalogOption option)
      onDownloadAdhan;
  final Future<void> Function(String prayerKey) onPickLocalAdhan;
  final ValueChanged<bool> onVoiceToggleChanged;
  final ValueChanged<bool> onAzanToggleChanged;
  final ValueChanged<bool> onVibrationToggleChanged;
  final ValueChanged<bool?> onSortChanged;
  final ValueChanged<bool?> onHelpToggleChanged;
  final ValueChanged<String> onVibrationDurationChanged;
  final ValueChanged<String> onVibrationPauseChanged;
  final ReminderAudioMode selectedAudioMode;
  final ValueChanged<ReminderAudioMode?> onAudioModeChanged;
  final VoidCallback onPickAudio;
  final String audioPickerButtonLabel;
  final String audioInfoText;
  final VoidCallback onVoiceTest;
  final TextEditingController voiceReminderController;
  final TextEditingController voiceRepeatController;
  final ValueChanged<String> onVoiceTextChanged;
  final ValueChanged<String> onVoiceRepeatChanged;
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

  const SettingsLegacyAccordionGroup({
    super.key,
    required this.outerPadding,
    required this.panelStyle,
    required this.showVoiceIcon,
    required this.showAzanIcon,
    required this.showVibrationIcon,
    required this.sortCustomPrayersByTime,
    required this.showHelpBalloons,
    required this.adhanSelections,
    required this.downloadingAdhanPrayerKeys,
    required this.vibrationDurationController,
    required this.vibrationPauseController,
    required this.onUseDefaultAdhan,
    required this.onDownloadAdhan,
    required this.onPickLocalAdhan,
    required this.onVoiceToggleChanged,
    required this.onAzanToggleChanged,
    required this.onVibrationToggleChanged,
    required this.onSortChanged,
    required this.onHelpToggleChanged,
    required this.onVibrationDurationChanged,
    required this.onVibrationPauseChanged,
    required this.selectedAudioMode,
    required this.onAudioModeChanged,
    required this.onPickAudio,
    required this.audioPickerButtonLabel,
    required this.audioInfoText,
    required this.onVoiceTest,
    required this.voiceReminderController,
    required this.voiceRepeatController,
    required this.onVoiceTextChanged,
    required this.onVoiceRepeatChanged,
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
    return Padding(
      padding: outerPadding,
      child: Column(
        children: [
          _warningSettingsCard(context),
          const SizedBox(height: 20),
          _colorsCard(context),
        ],
      ),
    );
  }

  Widget _warningSettingsCard(BuildContext context) {
    return SharedSettingsSectionCard(
      title: 'Hatırlatma Ayarları',
      headerColor: sharedSettingsReminderOptionsHeader,
      child: _sectionChild(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _subHeader('Hatırlatma Seçenekleri', sharedSettingsReminderOptionsHeader),
            Row(
              children: [
                Expanded(child: _toggle('Sesli', showVoiceIcon, onVoiceToggleChanged)),
                const SizedBox(width: 10),
                Expanded(child: _toggle('Ezan', showAzanIcon, onAzanToggleChanged)),
                const SizedBox(width: 10),
                Expanded(child: _toggle('Titreşim', showVibrationIcon, onVibrationToggleChanged)),
              ],
            ),
            const SizedBox(height: 18),
            _subHeader('Titreşimle Uyarı Ayarları', sharedSettingsVibrationHeader),
            Row(
              children: [
                Expanded(
                  child: SettingsReminderNumberField(
                    label: 'Titreşim Süresi (sn)',
                    controller: vibrationDurationController,
                    onChanged: onVibrationDurationChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SettingsReminderNumberField(
                    label: 'Titreşim Aralığı (sn)',
                    controller: vibrationPauseController,
                    onChanged: onVibrationPauseChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _subHeader('Sesli Hatırlatma', sharedSettingsVoiceHeader),
            _voiceSettings(context),
            const SizedBox(height: 18),
            _subHeader('Ezan Okuma', sharedSettingsVisualHeader),
            SettingsAdhanSelectionSection(
              selections: adhanSelections,
              downloadingPrayerKeys: downloadingAdhanPrayerKeys,
              onUseDefault: onUseDefaultAdhan,
              onDownloadOption: onDownloadAdhan,
              onPickLocalFile: onPickLocalAdhan,
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<ReminderAudioMode>(
          initialValue: selectedAudioMode,
          decoration: const InputDecoration(
            labelText: 'Ses Kaynağı',
            border: OutlineInputBorder(),
          ),
          items: ReminderAudioMode.values
              .map(
                (mode) => DropdownMenuItem<ReminderAudioMode>(
                  value: mode,
                  child: Text(audioModeLabel(mode)),
                ),
              )
              .toList(growable: false),
          onChanged: onAudioModeChanged,
        ),
        if (selectedAudioMode == ReminderAudioMode.textToSpeech) ...[
          const SizedBox(height: 10),
          SettingsReminderTextField(
            label: 'Sesli Hatırlatma Metni',
            controller: voiceReminderController,
            hintText: 'Sesli hatırlatmada okunacak metni girin.',
            onChanged: onVoiceTextChanged,
          ),
          const SizedBox(height: 8),
          SettingsReminderNumberField(
            label: 'Sesli Hatırlatma Periyodu (sn)',
            controller: voiceRepeatController,
            onChanged: onVoiceRepeatChanged,
          ),
        ] else ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPickAudio,
            icon: const Icon(Icons.library_music_outlined),
            label: Text(audioPickerButtonLabel),
          ),
          const SizedBox(height: 8),
          Text(audioInfoText, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: onVoiceTest,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Sesli Test'),
          ),
        ),
      ],
    );
  }

  Widget _colorsCard(BuildContext context) {
    return SharedSettingsSectionCard(
      title: 'Arayüz Ayarları',
      headerColor: sharedSettingsMergedColorsHeader,
      child: _sectionChild(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: showHelpBalloons,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Yardımları Göster'),
              subtitle: const Text('Soru işareti ikonları ve kısa kullanım açıklamalarını gösterir.'),
              onChanged: onHelpToggleChanged,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: SettingsColorActionTile(title: 'Panel Rengi', color: panelColor, onTap: onEditPanelColor)),
                const SizedBox(width: 10),
                Expanded(child: SettingsColorActionTile(title: 'Yazı Rengi', color: textColor, onTap: onEditTextColor)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: SettingsColorActionTile(title: 'Nafile Vakit Rengi', color: customPrayerLabelColor, onTap: onEditCustomPrayerLabelColor)),
                const SizedBox(width: 10),
                Expanded(child: SettingsColorActionTile(title: 'Zemin Rengi', color: backgroundColor, onTap: onEditBackgroundColor)),
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
                onPressed: hasPendingBackgroundChanges
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

  SettingsReminderOptionToggle _toggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SettingsReminderOptionToggle(
      label: label,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _subHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _sectionChild({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: child,
    );
  }
}
