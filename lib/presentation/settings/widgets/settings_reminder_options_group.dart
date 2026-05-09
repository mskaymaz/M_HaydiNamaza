import 'package:flutter/material.dart';

import '../../../core/config/config_registry.dart';
import 'settings_reminder_fields.dart';
import 'settings_reminder_options_section.dart';
import 'settings_section_header.dart';

class SettingsReminderOptionsGroup extends StatelessWidget {
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

  const SettingsReminderOptionsGroup({
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
  });

  @override
  Widget build(BuildContext context) {
    return SettingsReminderOptionsSection(
      outerPadding: outerPadding,
      panelStyle: panelStyle,
      reminderOptionsHeader: const SettingsSectionHeader(
        title: 'Hatırlatma Seçenekleri',
        tooltip:
            'Buradaki seçimler vakitler panelinde hangi hatırlatıcı ikonlarının görüneceğini belirler.',
      ),
      vibrationHeader: const SettingsSectionHeader(
        title: 'Titreşimle Uyarı Ayarları',
        tooltip: 'Titreşim süresi ve tekrar aralığı bu bölümden ayarlanır.',
      ),
      voiceToggle: SettingsReminderOptionToggle(
        label: 'Sesli',
        value: showVoiceIcon,
        onChanged: onVoiceToggleChanged,
      ),
      visualToggle: SettingsReminderOptionToggle(
        label: 'Görsel',
        value: showVisualIcon,
        onChanged: onVisualToggleChanged,
      ),
      azanToggle: SettingsReminderOptionToggle(
        label: 'Ezan',
        value: showAzanIcon,
        onChanged: onAzanToggleChanged,
      ),
      vibrationToggle: SettingsReminderOptionToggle(
        label: 'Titreşim',
        value: showVibrationIcon,
        onChanged: onVibrationToggleChanged,
      ),
      sortCustomPrayersByTime: sortCustomPrayersByTime,
      onSortChanged: onSortChanged,
      vibrationDurationField: SettingsReminderNumberField(
        label: 'Titreşim Süresi (sn)',
        controller: vibrationDurationController,
        onChanged: onVibrationDurationChanged,
      ),
      vibrationPauseField: SettingsReminderNumberField(
        label: 'Titreşim Aralığı (sn)',
        controller: vibrationPauseController,
        onChanged: onVibrationPauseChanged,
      ),
    );
  }
}
