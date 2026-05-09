import 'package:flutter/material.dart';

import '../../../app/reminder_text_settings_storage.dart';
import '../../../core/config/config_registry.dart';

class SettingsVoiceReminderSection extends StatelessWidget {
  final EdgeInsets outerPadding;
  final SurfaceStyle panelStyle;
  final Widget header;
  final ReminderAudioMode selectedAudioMode;
  final List<DropdownMenuItem<ReminderAudioMode>> audioModeItems;
  final ValueChanged<ReminderAudioMode?> onAudioModeChanged;
  final String? selectedVoiceKey;
  final List<DropdownMenuItem<String?>> voiceItems;
  final ValueChanged<String?> onVoiceChanged;
  final VoidCallback onPickAudio;
  final String audioPickerButtonLabel;
  final String audioInfoText;
  final VoidCallback onVoiceTest;
  final Widget voiceTextField;
  final Widget voiceRepeatField;

  const SettingsVoiceReminderSection({
    super.key,
    required this.outerPadding,
    required this.panelStyle,
    required this.header,
    required this.selectedAudioMode,
    required this.audioModeItems,
    required this.onAudioModeChanged,
    required this.selectedVoiceKey,
    required this.voiceItems,
    required this.onVoiceChanged,
    required this.onPickAudio,
    required this.audioPickerButtonLabel,
    required this.audioInfoText,
    required this.onVoiceTest,
    required this.voiceTextField,
    required this.voiceRepeatField,
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
            header,
            const SizedBox(height: 6),
            DropdownButtonFormField<ReminderAudioMode>(
              initialValue: selectedAudioMode,
              decoration: const InputDecoration(
                labelText: 'Ses Kaynağı',
                border: OutlineInputBorder(),
              ),
              items: audioModeItems,
              onChanged: onAudioModeChanged,
            ),
            if (selectedAudioMode == ReminderAudioMode.textToSpeech) ...[
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                initialValue: selectedVoiceKey,
                decoration: const InputDecoration(
                  labelText: 'Sistem Sesi',
                  border: OutlineInputBorder(),
                ),
                items: voiceItems,
                onChanged: onVoiceChanged,
              ),
              const SizedBox(height: 10),
              voiceTextField,
              const SizedBox(height: 8),
              voiceRepeatField,
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
