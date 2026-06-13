import 'package:flutter/material.dart';

import '../../../../app/reminder_text_settings_storage.dart';
import '../../../../core/config/config_registry.dart';
import '../../settings_audio_mode_texts.dart';
import '../settings_color_action_widgets.dart';
import '../settings_reminder_fields.dart';
import 'shared_settings_section_styles.dart';

class SettingsLegacyAccordionGroup extends StatelessWidget {
  final EdgeInsets outerPadding;
  final SurfaceStyle panelStyle;
  final bool showVoiceIcon;
  final bool showVisualIcon;
  final bool showAzanIcon;
  final bool showVibrationIcon;
  final bool sortCustomPrayersByTime;
  final TextEditingController vibrationDurationController;
  final TextEditingController vibrationPauseController;
  final ValueChanged<bool> onVoiceToggleChanged;
  final ValueChanged<bool> onVisualToggleChanged;
  final ValueChanged<bool> onAzanToggleChanged;
  final ValueChanged<bool> onVibrationToggleChanged;
  final ValueChanged<bool?> onSortChanged;
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
  final TextEditingController visualReminderController;
  final TextEditingController visualDisplayController;
  final TextEditingController visualReopenController;
  final ValueChanged<String> onVisualTextChanged;
  final ValueChanged<String> onVisualDisplayChanged;
  final ValueChanged<String> onVisualReopenChanged;
  final VoidCallback onShowPreview;
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
    required this.showVisualIcon,
    required this.showAzanIcon,
    required this.showVibrationIcon,
    required this.sortCustomPrayersByTime,
    required this.vibrationDurationController,
    required this.vibrationPauseController,
    required this.onVoiceToggleChanged,
    required this.onVisualToggleChanged,
    required this.onAzanToggleChanged,
    required this.onVibrationToggleChanged,
    required this.onSortChanged,
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
    required this.visualReminderController,
    required this.visualDisplayController,
    required this.visualReopenController,
    required this.onVisualTextChanged,
    required this.onVisualDisplayChanged,
    required this.onVisualReopenChanged,
    required this.onShowPreview,
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
          SharedSettingsSectionCard(
            title: 'Hatirlatma Secenekleri',
            headerColor: sharedSettingsReminderOptionsHeader,
            child: _sectionChild(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SettingsReminderOptionToggle(
                          label: 'Sesli',
                          value: showVoiceIcon,
                          onChanged: onVoiceToggleChanged,
                        ),
                      ),
                      Expanded(
                        child: SettingsReminderOptionToggle(
                          label: 'Gorsel',
                          value: showVisualIcon,
                          onChanged: onVisualToggleChanged,
                        ),
                      ),
                      Expanded(
                        child: SettingsReminderOptionToggle(
                          label: 'Ezan',
                          value: showAzanIcon,
                          onChanged: onAzanToggleChanged,
                        ),
                      ),
                      Expanded(
                        child: SettingsReminderOptionToggle(
                          label: 'Titresim',
                          value: showVibrationIcon,
                          onChanged: onVibrationToggleChanged,
                        ),
                      ),
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
                    title: const Text('Nafileler vakitlere gore siralansin'),
                    subtitle: const Text(
                      'Kapaliysa nafileler listenin en altinda kalir.',
                    ),
                    onChanged: onSortChanged,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SharedSettingsSectionCard(
            title: 'Titresimle Uyari Ayarlari',
            headerColor: sharedSettingsVibrationHeader,
            child: _sectionChild(
              child: Row(
                children: [
                  Expanded(
                    child: SettingsReminderNumberField(
                      label: 'Titresim Suresi (sn)',
                      controller: vibrationDurationController,
                      onChanged: onVibrationDurationChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SettingsReminderNumberField(
                      label: 'Titresim Araligi (sn)',
                      controller: vibrationPauseController,
                      onChanged: onVibrationPauseChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SharedSettingsSectionCard(
            title: 'Sesli Hatirlatma',
            headerColor: sharedSettingsVoiceHeader,
            child: _sectionChild(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<ReminderAudioMode>(
                    initialValue: selectedAudioMode,
                    decoration: const InputDecoration(
                      labelText: 'Ses Kaynagi',
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
                      label: 'Sesli Hatirlatma Metni',
                      controller: voiceReminderController,
                      hintText: 'Sesli hatirlatmada okunacak metni girin.',
                      onChanged: onVoiceTextChanged,
                    ),
                    const SizedBox(height: 8),
                    SettingsReminderNumberField(
                      label: 'Sesli Hatirlatma Periyodu (sn)',
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
                    Text(
                      audioInfoText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
              ),
            ),
          ),
          const SizedBox(height: 10),
          SharedSettingsSectionCard(
            title: 'Gorsel Hatirlatma',
            headerColor: sharedSettingsVisualHeader,
            child: _sectionChild(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsReminderTextField(
                    label: 'Gorsel Hatirlatma Metni',
                    controller: visualReminderController,
                    hintText:
                        'Buraya metin girilmezse sesli hatirlatma metni kullanilir.',
                    onChanged: onVisualTextChanged,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SettingsReminderNumberField(
                          label: 'Ekranda Kalma (sn)',
                          controller: visualDisplayController,
                          onChanged: onVisualDisplayChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SettingsReminderNumberField(
                          label: 'Kapanip Acilma (sn)',
                          controller: visualReopenController,
                          onChanged: onVisualReopenChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: onShowPreview,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Gorsel Uyariyi Goster'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SharedSettingsSectionCard(
            title: 'Arayuz ve Arkaplan Renkleri',
            headerColor: sharedSettingsMergedColorsHeader,
            child: _sectionChild(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Arayuz Renkleri',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SettingsColorActionTile(
                    title: 'Panel Rengi',
                    color: panelColor,
                    onTap: onEditPanelColor,
                  ),
                  const SizedBox(height: 8),
                  SettingsColorActionTile(
                    title: 'Yazi Rengi',
                    color: textColor,
                    onTap: onEditTextColor,
                  ),
                  const SizedBox(height: 8),
                  SettingsColorActionTile(
                    title: 'Nafile Vakit Rengi',
                    color: customPrayerLabelColor,
                    onTap: onEditCustomPrayerLabelColor,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SettingsResetIconButton(
                      onTap: onResetInterfaceColors,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Arkaplan Rengi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SettingsColorActionTile(
                    title: 'Zemin Rengi',
                    color: backgroundColor,
                    onTap: onEditBackgroundColor,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SettingsResetIconButton(
                      onTap: onResetBackgroundColors,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Not: Secimler ana sayfaya sadece Uygula butonuyla yansir.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => onResetBackgroundColors(),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Varsayilan'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: hasPendingBackgroundChanges
                            ? () => onApplyBackgroundStyle()
                            : null,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Uygula'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionChild({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: child,
    );
  }
}
