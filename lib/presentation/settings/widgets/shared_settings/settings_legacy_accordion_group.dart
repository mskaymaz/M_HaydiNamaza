import 'package:flutter/material.dart';

import '../../../../app/background/patterned_background.dart';
import '../../../../app/reminder_text_settings_storage.dart';
import '../../../../core/config/config_registry.dart';
import '../../settings_audio_mode_texts.dart';
import '../settings_color_action_widgets.dart';
import '../settings_reminder_fields.dart';
import 'shared_settings_section_styles.dart';
import '../../voice_test_screen.dart';

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
  final Color backgroundColor;
  final Color backgroundLineColor;
  final String selectedBackgroundPatternAssetPath;
  final double backgroundPatternScale;
  final double backgroundPatternOpacity;
  final bool hasPendingBackgroundChanges;
  final VoidCallback onEditPanelColor;
  final VoidCallback onEditTextColor;
  final VoidCallback onEditBackgroundColor;
  final VoidCallback onEditBackgroundLineColor;
  final Future<void> Function() onResetInterfaceColors;
  final Future<void> Function() onResetBackgroundColors;
  final Future<void> Function() onApplyBackgroundStyle;
  final ValueChanged<String> onBackgroundPatternChanged;
  final ValueChanged<double> onBackgroundPatternScaleChanged;
  final ValueChanged<double> onBackgroundPatternOpacityChanged;
  final List<DropdownMenuItem<String?>> voiceItems;
  final String? selectedEnglishVoiceKey;
  final String? selectedArabicVoiceKey;
  final ValueChanged<String?> onEnglishVoiceChanged;
  final ValueChanged<String?> onArabicVoiceChanged;

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
    required this.backgroundColor,
    required this.backgroundLineColor,
    required this.selectedBackgroundPatternAssetPath,
    required this.backgroundPatternScale,
    required this.backgroundPatternOpacity,
    required this.hasPendingBackgroundChanges,
    required this.onEditPanelColor,
    required this.onEditTextColor,
    required this.onEditBackgroundColor,
    required this.onEditBackgroundLineColor,
    required this.onResetInterfaceColors,
    required this.onResetBackgroundColors,
    required this.onApplyBackgroundStyle,
    required this.onBackgroundPatternChanged,
    required this.onBackgroundPatternScaleChanged,
    required this.onBackgroundPatternOpacityChanged,
    required this.voiceItems,
    required this.selectedEnglishVoiceKey,
    required this.selectedArabicVoiceKey,
    required this.onEnglishVoiceChanged,
    required this.onArabicVoiceChanged,
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
                    DropdownButtonFormField<String?>(
                      initialValue: selectedEnglishVoiceKey,
                      decoration: const InputDecoration(
                        labelText: 'English Voice (Tercih)',
                        border: OutlineInputBorder(),
                      ),
                      items: voiceItems,
                      onChanged: onEnglishVoiceChanged,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedArabicVoiceKey,
                      decoration: const InputDecoration(
                        labelText: 'Arabic Voice (Tercih)',
                        border: OutlineInputBorder(),
                      ),
                      items: voiceItems,
                      onChanged: onArabicVoiceChanged,
                    ),
                    const SizedBox(height: 8),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: onVoiceTest,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Sesli Test'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => VoiceTestScreen(voiceItems: voiceItems),
                            ));
                          },
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Ses Tespit'),
                        ),
                      ],
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
                    'Arkaplan Renkleri',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SettingsColorActionTile(
                    title: 'Zemin Rengi',
                    color: backgroundColor,
                    onTap: onEditBackgroundColor,
                  ),
                  const SizedBox(height: 8),
                  SettingsColorActionTile(
                    title: 'Cizgi Rengi',
                    color: backgroundLineColor,
                    onTap: onEditBackgroundLineColor,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SettingsResetIconButton(
                      onTap: onResetBackgroundColors,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Arkaplan Deseni',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: BackgroundPatternRegistry.patterns.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final pattern =
                            BackgroundPatternRegistry.patterns[index];
                        final isSelected =
                            pattern.assetPath ==
                            selectedBackgroundPatternAssetPath;
                        return SizedBox(
                          width: 108,
                          child: _PatternChoiceCard(
                            pattern: pattern,
                            backgroundColor: backgroundColor,
                            backgroundLineColor: backgroundLineColor,
                            backgroundPatternOpacity: backgroundPatternOpacity,
                            isSelected: isSelected,
                            onTap: () =>
                                onBackgroundPatternChanged(pattern.assetPath),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Olcek: ${backgroundPatternScale.toStringAsFixed(2)}x',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Slider(
                    value: backgroundPatternScale.clamp(0.6, 1.8),
                    min: 0.6,
                    max: 1.8,
                    divisions: 12,
                    label: backgroundPatternScale.toStringAsFixed(2),
                    onChanged: onBackgroundPatternScaleChanged,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Desen Seffafligi: ${(backgroundPatternOpacity * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Slider(
                    value: backgroundPatternOpacity.clamp(0.0, 1.0),
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: '${(backgroundPatternOpacity * 100).round()}%',
                    onChanged: onBackgroundPatternOpacityChanged,
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

class _PatternChoiceCard extends StatelessWidget {
  final BackgroundPatternDefinition pattern;
  final Color backgroundColor;
  final Color backgroundLineColor;
  final double backgroundPatternOpacity;
  final bool isSelected;
  final VoidCallback onTap;

  const _PatternChoiceCard({
    required this.pattern,
    required this.backgroundColor,
    required this.backgroundLineColor,
    required this.backgroundPatternOpacity,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? backgroundLineColor.withValues(alpha: 0.95)
                  : Colors.black.withValues(alpha: 0.08),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Positioned.fill(
                  child: PatternedBackground(
                    backgroundColor: backgroundColor,
                    patternColor: backgroundLineColor,
                    patternAssetPath: pattern.assetPath,
                    patternScale: 0.72,
                    patternOpacity: backgroundPatternOpacity,
                    child: const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Text(
                            pattern.label,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
