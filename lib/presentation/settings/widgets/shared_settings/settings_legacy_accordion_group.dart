import 'package:flutter/material.dart';

import '../../../../app/adhan_catalog.dart';
import '../../../../app/reminder_text_settings_storage.dart';
import '../../../../core/config/config_registry.dart';
import '../../settings_audio_mode_texts.dart';
import '../../../shared/app_help_tooltip.dart';
import '../settings_reminder_fields.dart';
import '../settings_adhan_selection_section.dart';
import '../settings_kerahat_section.dart';
import '../settings_interface_colors_card.dart';
import 'shared_settings_section_styles.dart';

class SettingsLegacyAccordionGroup extends StatelessWidget {
  final EdgeInsets outerPadding;
  final SurfaceStyle panelStyle;
  final bool showVoiceIcon;
  final bool showAzanIcon;
  final bool showVibrationIcon;
  final bool prayerSilenceEnabled;
  final bool kerahatEnabled;
  final bool sortCustomPrayersByTime;
  final bool showHelpBalloons;
  final Map<String, AdhanSelection> adhanSelections;
  final Map<String, String> downloadedAdhanPaths;
  final Set<String> downloadingAdhanPrayerKeys;
  final String? activeAdhanPreviewKey;
  final TextEditingController vibrationDurationController;
  final TextEditingController vibrationPauseController;
  final TextEditingController prayerSilenceStartMinutesController;
  final TextEditingController prayerSilenceDurationMinutesController;
  final TextEditingController kerahatSunriseMinutesController;
  final TextEditingController kerahatDhuhrMinutesController;
  final TextEditingController kerahatMaghribMinutesController;
  final ValueChanged<bool> onKerahatToggleChanged;
  final ValueChanged<String> onKerahatSunriseMinutesChanged;
  final ValueChanged<String> onKerahatDhuhrMinutesChanged;
  final ValueChanged<String> onKerahatMaghribMinutesChanged;
  final ValueChanged<String> onUseDefaultAdhan;
  final Future<void> Function(String prayerKey, AdhanCatalogOption option)
      onDownloadAdhan;
  final Future<void> Function(String prayerKey, AdhanCatalogOption option)
      onSelectDownloadedAdhan;
  final Future<void> Function(String prayerKey) onPickLocalAdhan;
  final Future<void> Function() onPreviewDefaultAdhan;
  final Future<void> Function(AdhanCatalogOption option) onPreviewDownloadedAdhan;
  final Future<void> Function(String prayerKey) onPreviewLocalAdhan;
  final Future<void> Function() onStopAdhanPreview;
  final Future<void> Function(AdhanCatalogOption option) onDeleteDownloadedAdhan;
  final Future<void> Function(String prayerKey) onClearLocalAdhan;
  final ValueChanged<bool> onVoiceToggleChanged;
  final ValueChanged<bool> onAzanToggleChanged;
  final ValueChanged<bool> onVibrationToggleChanged;
  final ValueChanged<bool> onPrayerSilenceToggleChanged;
  final ValueChanged<bool?> onSortChanged;
  final ValueChanged<bool?> onHelpToggleChanged;
  final ValueChanged<String> onVibrationDurationChanged;
  final ValueChanged<String> onVibrationPauseChanged;
  final ValueChanged<String> onPrayerSilenceStartMinutesChanged;
  final ValueChanged<String> onPrayerSilenceDurationMinutesChanged;
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
    required this.prayerSilenceEnabled,
    required this.kerahatEnabled,
    required this.sortCustomPrayersByTime,
    required this.showHelpBalloons,
    required this.adhanSelections,
    required this.downloadedAdhanPaths,
    required this.downloadingAdhanPrayerKeys,
    required this.activeAdhanPreviewKey,
    required this.vibrationDurationController,
    required this.vibrationPauseController,
    required this.prayerSilenceStartMinutesController,
    required this.prayerSilenceDurationMinutesController,
    required this.kerahatSunriseMinutesController,
    required this.kerahatDhuhrMinutesController,
    required this.kerahatMaghribMinutesController,
    required this.onKerahatToggleChanged,
    required this.onKerahatSunriseMinutesChanged,
    required this.onKerahatDhuhrMinutesChanged,
    required this.onKerahatMaghribMinutesChanged,
    required this.onUseDefaultAdhan,
    required this.onDownloadAdhan,
    required this.onSelectDownloadedAdhan,
    required this.onPickLocalAdhan,
    required this.onPreviewDefaultAdhan,
    required this.onPreviewDownloadedAdhan,
    required this.onPreviewLocalAdhan,
    required this.onStopAdhanPreview,
    required this.onDeleteDownloadedAdhan,
    required this.onClearLocalAdhan,
    required this.onVoiceToggleChanged,
    required this.onAzanToggleChanged,
    required this.onVibrationToggleChanged,
    required this.onPrayerSilenceToggleChanged,
    required this.onSortChanged,
    required this.onHelpToggleChanged,
    required this.onVibrationDurationChanged,
    required this.onVibrationPauseChanged,
    required this.onPrayerSilenceStartMinutesChanged,
    required this.onPrayerSilenceDurationMinutesChanged,
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
          SettingsInterfaceColorsCard(
            showHelpBalloons: showHelpBalloons,
            onHelpToggleChanged: onHelpToggleChanged,
            panelColor: panelColor,
            textColor: textColor,
            customPrayerLabelColor: customPrayerLabelColor,
            backgroundColor: backgroundColor,
            hasPendingBackgroundChanges: hasPendingBackgroundChanges,
            onEditPanelColor: onEditPanelColor,
            onEditTextColor: onEditTextColor,
            onEditCustomPrayerLabelColor: onEditCustomPrayerLabelColor,
            onEditBackgroundColor: onEditBackgroundColor,
            onResetInterfaceColors: onResetInterfaceColors,
            onResetBackgroundColors: onResetBackgroundColors,
            onApplyBackgroundStyle: onApplyBackgroundStyle,
          ),
        ],
      ),
    );
  }

  Widget _warningSettingsCard(BuildContext context) {
    return SharedSettingsSectionCard(
      title: 'Hatırlatma Ayarları',
      headerColor: sharedSettingsReminderOptionsHeader,
      showHelpBalloons: showHelpBalloons,
      helpMessage:
          'Bu bölüm vakit satırlarında görünen sesli hatırlatma, ezan ve titreşim seçeneklerini yönetir. Her vakit için ayrı ezan seçebilir, sesli hatırlatma ve titreşim sürelerini buradan ayarlayabilirsiniz.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _subHeader(
              title: 'Hatırlatma Seçenekleri',
              color: sharedSettingsReminderOptionsHeader,
              helpMessage:
                  'Ana ekrandaki vakit satırlarında sesli hatırlatma, ezan ve titreşim simgelerinin görünüp görünmeyeceğini belirler.',
            ),
            Row(
              children: [
                Expanded(
                  child: SettingsReminderOptionToggle(
                    label: 'Ses & Titreşim',
                    value: showVoiceIcon || showVibrationIcon,
                    onChanged: (value) {
                      onVoiceToggleChanged(value);
                      onVibrationToggleChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SettingsReminderOptionToggle(
                    label: 'Ezan',
                    value: showAzanIcon,
                    onChanged: onAzanToggleChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _subHeader(
              title: 'Namaz Vaktinde Sessiz Kal',
              color: sharedSettingsVibrationHeader,
              helpMessage:
                  'İşaretlendiğinde ana ekrandaki sessiz ikonları vakit bazında etkinleştirebilirsiniz. Sessize alma telefon ayarlarını süre sonunda geri yüklemeyi dener.',
            ),
            CheckboxListTile(
              value: prayerSilenceEnabled,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Namaz Vaktinde Sessiz Kal'),
              subtitle: const Text(
                'Ana ayar kapalıysa vakit satırlarındaki sessiz ikonları kullanamazsınız.',
              ),
              onChanged: (value) {
                onPrayerSilenceToggleChanged(value ?? false);
              },
            ),
            if (prayerSilenceEnabled) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SettingsReminderNumberField(
                      label: 'Kaç dakika önce',
                      controller: prayerSilenceStartMinutesController,
                      onChanged: onPrayerSilenceStartMinutesChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SettingsReminderNumberField(
                      label: 'Kaç dakika sessiz',
                      controller: prayerSilenceDurationMinutesController,
                      onChanged: onPrayerSilenceDurationMinutesChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Varsayılan: vakitten 5 dakika önce başlar, 20 dakika sürer.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 18),
            _subHeader(
              title: 'Titreşimle Uyarı Ayarları',
              color: sharedSettingsVibrationHeader,
              helpMessage:
                  'Titreşimin kaç saniye süreceğini ve tekrarlar arasındaki bekleme süresini buradan ayarlayabilirsiniz.',
            ),
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
            SettingsKerahatSection(
              kerahatEnabled: kerahatEnabled,
              kerahatSunriseMinutesController: kerahatSunriseMinutesController,
              kerahatDhuhrMinutesController: kerahatDhuhrMinutesController,
              kerahatMaghribMinutesController: kerahatMaghribMinutesController,
              onKerahatToggleChanged: onKerahatToggleChanged,
              onKerahatSunriseMinutesChanged: onKerahatSunriseMinutesChanged,
              onKerahatDhuhrMinutesChanged: onKerahatDhuhrMinutesChanged,
              onKerahatMaghribMinutesChanged: onKerahatMaghribMinutesChanged,
              buildSubHeader: _subHeader,
            ),
            const SizedBox(height: 18),
            _subHeader(
              title: 'Sesli Hatırlatma',
              color: sharedSettingsVoiceHeader,
              helpMessage:
                  'Sesli hatırlatma için metinden sese okuma veya seçtiğiniz yerel ses dosyasını kullanabilirsiniz. Sesli Test düğmesi ayarı denemenizi sağlar.',
            ),
            _voiceSettings(context),
            const SizedBox(height: 18),
            _subHeader(
              title: 'Ezan Okuma',
              color: sharedSettingsVisualHeader,
              helpMessage:
                  'Önce vakti seçin. Sonra varsayılan ezanı, telefondan seçeceğiniz yerel dosyayı veya indirilebilir ezan kütüphanesindeki seçenekleri o vakit için kullanabilirsiniz.',
            ),
            SettingsAdhanSelectionSection(
              selections: adhanSelections,
              downloadedAdhanPaths: downloadedAdhanPaths,
              downloadingPrayerKeys: downloadingAdhanPrayerKeys,
              activePreviewKey: activeAdhanPreviewKey,
              onUseDefault: onUseDefaultAdhan,
              onDownloadOption: onDownloadAdhan,
              onSelectDownloaded: onSelectDownloadedAdhan,
              onPickLocalFile: onPickLocalAdhan,
              onPreviewDefault: onPreviewDefaultAdhan,
              onPreviewDownloaded: onPreviewDownloadedAdhan,
              onPreviewLocalFile: onPreviewLocalAdhan,
              onStopPreview: onStopAdhanPreview,
              onDeleteDownloaded: onDeleteDownloadedAdhan,
              onClearLocalFile: onClearLocalAdhan,
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

  Widget _subHeader({
    required String title,
    required Color color,
    required String helpMessage,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          AppHelpTooltip(
            visible: showHelpBalloons,
            title: title,
            message: helpMessage,
            iconSize: 18,
            tapSize: 30,
          ),
        ],
      ),
    );
  }
}

