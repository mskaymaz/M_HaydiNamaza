import 'package:flutter/material.dart';

import '../../../app/reminder_text_settings_storage.dart';
import '../../../core/config/config_registry.dart';
import '../settings_audio_mode_texts.dart';
import 'settings_reminder_fields.dart';
import 'settings_reminder_options_group.dart';
import 'settings_section_header.dart';
import 'settings_visual_reminder_section.dart';
import 'settings_voice_reminder_section.dart';

class SettingsReminderSectionsGroup extends StatelessWidget {
  final EdgeInsets screenPadding;
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
  final String? selectedVoiceKey;
  final List<DropdownMenuItem<String?>> voiceItems;
  final ValueChanged<String?> onVoiceChanged;
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

  const SettingsReminderSectionsGroup({
    super.key,
    required this.screenPadding,
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
    required this.selectedVoiceKey,
    required this.voiceItems,
    required this.onVoiceChanged,
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsReminderOptionsGroup(
          outerPadding: screenPadding,
          panelStyle: panelStyle,
          showVoiceIcon: showVoiceIcon,
          showVisualIcon: showVisualIcon,
          showAzanIcon: showAzanIcon,
          showVibrationIcon: showVibrationIcon,
          sortCustomPrayersByTime: sortCustomPrayersByTime,
          vibrationDurationController: vibrationDurationController,
          vibrationPauseController: vibrationPauseController,
          onVoiceToggleChanged: onVoiceToggleChanged,
          onVisualToggleChanged: onVisualToggleChanged,
          onAzanToggleChanged: onAzanToggleChanged,
          onVibrationToggleChanged: onVibrationToggleChanged,
          onSortChanged: onSortChanged,
          onVibrationDurationChanged: onVibrationDurationChanged,
          onVibrationPauseChanged: onVibrationPauseChanged,
        ),
        SettingsVoiceReminderSection(
          outerPadding: screenPadding.copyWith(top: 0),
          panelStyle: panelStyle,
          header: const SettingsSectionHeader(
            title: 'Sesli Hatırlatma',
            tooltip:
                'Metni Oku açıldığında sesli hatırlatma metni ve sistem sesi seçimi görünür. Seçilen ses sesli testte ve hatırlatma okumasında kullanılır.',
          ),
          selectedAudioMode: selectedAudioMode,
          audioModeItems: ReminderAudioMode.values
              .map(
                (mode) => DropdownMenuItem<ReminderAudioMode>(
                  value: mode,
                  child: Text(audioModeLabel(mode)),
                ),
              )
              .toList(),
          onAudioModeChanged: onAudioModeChanged,
          selectedVoiceKey: selectedVoiceKey,
          voiceItems: voiceItems,
          onVoiceChanged: onVoiceChanged,
          onPickAudio: onPickAudio,
          audioPickerButtonLabel: audioPickerButtonLabel,
          audioInfoText: audioInfoText,
          onVoiceTest: onVoiceTest,
          voiceTextField: SettingsReminderTextField(
            label: 'Sesli Hatırlatma Metni',
            controller: voiceReminderController,
            hintText: 'Sesli hatırlatmada okunacak metni girin.',
            onChanged: onVoiceTextChanged,
          ),
          voiceRepeatField: SettingsReminderNumberField(
            label: 'Sesli Hatırlatma Periyodu (sn)',
            controller: voiceRepeatController,
            onChanged: onVoiceRepeatChanged,
          ),
        ),
        SettingsVisualReminderSection(
          outerPadding: screenPadding.copyWith(top: 0),
          panelStyle: panelStyle,
          header: const SettingsSectionHeader(
            title: 'Görsel Hatırlatma',
            tooltip:
                'Görsel hatırlatma ayrı tutulur. Bu alan boşsa sesli hatırlatma metni kullanılır.',
          ),
          visualTextField: SettingsReminderTextField(
            label: 'Görsel Hatırlatma Metni',
            controller: visualReminderController,
            hintText:
                'Buraya herhangi bir metin girilmediğinde sesli hatırlatmadaki metin kullanılacaktır.',
            onChanged: onVisualTextChanged,
            maxLines: 3,
          ),
          visualDisplayField: SettingsReminderNumberField(
            label: 'Ekranda Kalma (sn)',
            controller: visualDisplayController,
            onChanged: onVisualDisplayChanged,
          ),
          visualReopenField: SettingsReminderNumberField(
            label: 'Kapanıp Açılma (sn)',
            controller: visualReopenController,
            onChanged: onVisualReopenChanged,
          ),
          onShowPreview: onShowPreview,
        ),
      ],
    );
  }
}
