import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/adhan_catalog.dart';
import '../../app/adhan_selection_storage.dart';
import '../../app/calculation_method_storage.dart';
import '../../app/kerahat_settings_storage.dart';
import '../../app/locale_controller.dart';
import '../../app/location_favorites_storage.dart';
import '../../app/location_storage.dart';
import '../../app/native_adhan_downloader.dart';
import '../../app/native_prayer_notification_scheduler.dart';
import '../../app/reminder_audio_service.dart';
import '../../app/reminder_text_settings_storage.dart';
import '../../app/ui_palette_controller.dart';
import '../../core/config/config_registry.dart';
import 'calculation_method_screen.dart';
import 'location_screen.dart';
import 'settings_audio_mode_texts.dart';
import 'settings_dialog_helpers.dart';
import 'settings_dropdown_decoration.dart';
import 'settings_favorite_matcher.dart';
import 'settings_reminder_snapshot.dart';
import 'settings_ui_mappers.dart';
import 'widgets/settings_top_settings_section.dart';
import 'widgets/shared_settings/settings_legacy_accordion_group.dart';
import 'widgets/settings_shared_sections_list.dart';

part 'settings_adhan_controller.dart';
part 'settings_reminder_controller.dart';

class SettingsScreen extends StatefulWidget {
  final LocaleController localeController;
  final UiPaletteController uiPaletteController;

  const SettingsScreen({
    super.key,
    required this.localeController,
    required this.uiPaletteController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocationStorage _locationStorage = LocationStorage();
  final LocationFavoritesStorage _favoritesStorage = LocationFavoritesStorage();
  final CalculationMethodStorage _methodStorage = CalculationMethodStorage();
  final ReminderTextSettingsStorage _reminderTextStorage = ReminderTextSettingsStorage();
  final KerahatSettingsStorage _kerahatSettingsStorage = KerahatSettingsStorage();
  final ReminderAudioService _reminderAudioService = ReminderAudioService();
  final AdhanSelectionStorage _adhanSelectionStorage = AdhanSelectionStorage();
  final NativeAdhanDownloader _adhanDownloader = NativeAdhanDownloader();
  final NativePrayerNotificationScheduler _nativeNotificationScheduler =
      NativePrayerNotificationScheduler();
  final TextEditingController _voiceReminderController = TextEditingController();
  final TextEditingController _visualReminderController = TextEditingController();
  final TextEditingController _voiceRepeatController = TextEditingController();
  final TextEditingController _vibrationDurationController = TextEditingController();
  final TextEditingController _vibrationPauseController = TextEditingController();
  final TextEditingController _prayerSilenceStartMinutesController =
      TextEditingController();
  final TextEditingController _prayerSilenceDurationMinutesController =
      TextEditingController();
  final TextEditingController _kerahatSunriseMinutesController =
      TextEditingController();
  final TextEditingController _kerahatDhuhrMinutesController =
      TextEditingController();
  final TextEditingController _kerahatMaghribMinutesController =
      TextEditingController();
  final TextEditingController _visualDisplayController = TextEditingController();
  final TextEditingController _visualReopenController = TextEditingController();

  LocationData? _location;
  List<LocationFavorite> _favorites = [];
  LocationFavorite? _selectedFavorite;
  String? _methodCode;
  ReminderAudioMode _selectedAudioMode = ReminderAudioMode.textToSpeech;
  String? _selectedAudioPath;
  String? _selectedAudioLabel;
  Map<String, AdhanSelection> _adhanSelections = defaultAdhanSelections();
  Map<String, String> _downloadedAdhanPaths = <String, String>{};
  final Set<String> _downloadingAdhanPrayerKeys = <String>{};
  String? _activeAdhanPreviewKey;
  String? _selectedVoiceName;
  String? _selectedVoiceLocale;
  String? _selectedEnglishVoiceName;
  String? _selectedEnglishVoiceLocale;
  String? _selectedArabicVoiceName;
  String? _selectedArabicVoiceLocale;
  bool _showVoiceIcon = true;
  bool _showVisualIcon = false;
  bool _showAzanIcon = true;
  bool _showVibrationIcon = true;
  bool _prayerSilenceEnabled = false;
  bool _kerahatEnabled = true;
  bool _sortCustomPrayersByTime = true;
  bool _showHelpBalloons = true;
  Color? _draftBackgroundColor;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadFavorites();
    _loadMethod();
    _loadReminderTexts();
    _loadKerahatSettings();
    _loadAdhanSelections();
  }

  Future<void> _loadLocation() async {
    final data = await _locationStorage.read();
    if (!mounted) return;
    final matched = matchFavorite(data, _favorites);
    setState(() {
      _location = data;
      _selectedFavorite = matched;
    });
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesStorage.read();
    if (!mounted) return;
    final matched = matchFavorite(_location, favorites);
    setState(() {
      _favorites = favorites;
      _selectedFavorite =
          _selectedFavorite != null && favorites.contains(_selectedFavorite)
          ? _selectedFavorite
          : matched;
    });
  }

  Future<void> _loadMethod() async {
    var code = await _methodStorage.readCode();
    if (code == null) {
      code = CalculationMethodStorage.defaultCode;
      await _methodStorage.writeCode(code);
    }
    if (!mounted) return;
    setState(() {
      _methodCode = code;
    });
  }

  Future<void> _loadReminderTexts() async {
    final settings = await _reminderTextStorage.read();
    _voiceReminderController.text = settings.voiceText;
    _visualReminderController.text = settings.visualText;
    _voiceRepeatController.text = settings.voiceRepeatSeconds.toString();
    _vibrationDurationController.text = settings.vibrationDurationSeconds
        .toString();
    _vibrationPauseController.text = settings.vibrationPauseSeconds.toString();
    _prayerSilenceStartMinutesController.text =
        settings.prayerSilenceStartMinutes.toString();
    _prayerSilenceDurationMinutesController.text =
        settings.prayerSilenceDurationMinutes.toString();
    _visualDisplayController.text = settings.visualDisplaySeconds.toString();
    _visualReopenController.text = settings.visualReopenSeconds.toString();
    _selectedAudioMode = settings.audioMode;
    _selectedAudioPath = settings.selectedAudioPath;
    _selectedAudioLabel = settings.selectedAudioLabel;
    _selectedVoiceName = settings.selectedVoiceName;
    _selectedVoiceLocale = settings.selectedVoiceLocale;
    _selectedEnglishVoiceName = settings.selectedEnglishVoiceName;
    _selectedEnglishVoiceLocale = settings.selectedEnglishVoiceLocale;
    _selectedArabicVoiceName = settings.selectedArabicVoiceName;
    _selectedArabicVoiceLocale = settings.selectedArabicVoiceLocale;
    _showVoiceIcon = settings.showVoiceIcon;
    _showVisualIcon = false;
    _showAzanIcon = settings.showAzanIcon;
    _showVibrationIcon = settings.showVibrationIcon;
    _prayerSilenceEnabled = settings.prayerSilenceEnabled;
    _sortCustomPrayersByTime = settings.sortCustomPrayersByTime;
    _showHelpBalloons = settings.showHelpBalloons;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadKerahatSettings() async {
    final record = await _kerahatSettingsStorage.read();
    if (!mounted) return;
    setState(() {
      _kerahatEnabled = record.enabled;
      _kerahatSunriseMinutesController.text = record.sunriseMinutes.toString();
      _kerahatDhuhrMinutesController.text = record.dhuhrMinutes.toString();
      _kerahatMaghribMinutesController.text = record.maghribMinutes.toString();
    });
  }

  Future<void> _persistKerahatSettings() async {
    final record = KerahatSettingsRecord(
      enabled: _kerahatEnabled,
      sunriseMinutes: int.tryParse(_kerahatSunriseMinutesController.text) ?? 45,
      dhuhrMinutes: int.tryParse(_kerahatDhuhrMinutesController.text) ?? 45,
      maghribMinutes: int.tryParse(_kerahatMaghribMinutesController.text) ?? 45,
    );
    await _kerahatSettingsStorage.write(record);
  }

  void _updateSettingsState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  @override
  void dispose() {
    _voiceReminderController.dispose();
    _visualReminderController.dispose();
    _voiceRepeatController.dispose();
    _vibrationDurationController.dispose();
    _vibrationPauseController.dispose();
    _prayerSilenceStartMinutesController.dispose();
    _prayerSilenceDurationMinutesController.dispose();
    _kerahatSunriseMinutesController.dispose();
    _kerahatDhuhrMinutesController.dispose();
    _kerahatMaghribMinutesController.dispose();
    _visualDisplayController.dispose();
    _visualReopenController.dispose();
    _reminderAudioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = widget.localeController.value;
    final palette = widget.uiPaletteController.value;
    _syncBackgroundDraftWithPalette(palette);
    final draftBackgroundColor =
        _draftBackgroundColor ?? palette.backgroundZeminColor;
    final hasPendingBackgroundChanges = _hasPendingBackgroundChanges(palette);
    final ui = ConfigRegistry.settingsPanelsFor(palette);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          SettingsTopSettingsSection(
            initialLanguageCode: codeForLocale(current),
            languageDecoration: settingsDropdownDecoration(
              palette: palette,
              label: 'Uygulama Dili',
            ),
            languageSystemLabel: l10n.languageSystem,
            languageTurkishLabel: l10n.languageTurkish,
            languageEnglishLabel: l10n.languageEnglish,
            languageArabicLabel: l10n.languageArabic,
            onLanguageChanged: (value) async {
              await widget.localeController.setLocale(localeForCode(value));
            },
            onOpenLocation: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => LocationScreen(
                    initial: _location,
                    uiPaletteController: widget.uiPaletteController,
                    showHelpBalloons: _showHelpBalloons,
                  ),
                ),
              );
              if (changed == true) {
                await _loadLocation();
              }
            },
            calculationItemPanelStyle: ui.itemPanel,
            calculationTitle: l10n.calculationMethodLabel,
            calculationSubtitle: methodSubtitleForCode(_methodCode, l10n),
            showHelpBalloons: _showHelpBalloons,
            onOpenCalculationMethod: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      CalculationMethodScreen(initialCode: _methodCode),
                ),
              );
              if (changed == true) {
                await _loadMethod();
              }
            },
            sortCustomPrayersByTime: _sortCustomPrayersByTime,
            onSortChanged: (value) {
              setState(() => _sortCustomPrayersByTime = value ?? true);
              _persistReminderTexts();
            },
          ),
          SettingsLegacyAccordionGroup(
            outerPadding: ui.screenPadding.copyWith(top: 0),
            panelStyle: ui.panel,
            showVoiceIcon: _showVoiceIcon,
            showAzanIcon: _showAzanIcon,
            showVibrationIcon: _showVibrationIcon,
            prayerSilenceEnabled: _prayerSilenceEnabled,
            kerahatEnabled: _kerahatEnabled,
            sortCustomPrayersByTime: _sortCustomPrayersByTime,
            showHelpBalloons: _showHelpBalloons,
            adhanSelections: _adhanSelections,
            downloadedAdhanPaths: _downloadedAdhanPaths,
            downloadingAdhanPrayerKeys: _downloadingAdhanPrayerKeys,
            onUseDefaultAdhan: _useDefaultAdhan,
            onDownloadAdhan: _downloadAdhan,
            onSelectDownloadedAdhan: _selectDownloadedAdhan,
            onPickLocalAdhan: _pickLocalAdhan,
            activeAdhanPreviewKey: _activeAdhanPreviewKey,
            onPreviewDefaultAdhan: _previewDefaultAdhan,
            onPreviewDownloadedAdhan: _previewDownloadedAdhan,
            onPreviewLocalAdhan: _previewLocalAdhan,
            onStopAdhanPreview: _stopAdhanPreview,
            onDeleteDownloadedAdhan: _deleteDownloadedAdhan,
            onClearLocalAdhan: _clearLocalAdhan,
            onHelpToggleChanged: (value) {
              setState(() => _showHelpBalloons = value ?? true);
              _persistReminderTexts();
            },
            vibrationDurationController: _vibrationDurationController,
            vibrationPauseController: _vibrationPauseController,
            prayerSilenceStartMinutesController:
                _prayerSilenceStartMinutesController,
            prayerSilenceDurationMinutesController:
                _prayerSilenceDurationMinutesController,
            kerahatSunriseMinutesController: _kerahatSunriseMinutesController,
            kerahatDhuhrMinutesController: _kerahatDhuhrMinutesController,
            kerahatMaghribMinutesController: _kerahatMaghribMinutesController,
            onKerahatToggleChanged: (value) {
              setState(() => _kerahatEnabled = value);
              _persistKerahatSettings();
            },
            onKerahatSunriseMinutesChanged: (_) => _persistKerahatSettings(),
            onKerahatDhuhrMinutesChanged: (_) => _persistKerahatSettings(),
            onKerahatMaghribMinutesChanged: (_) => _persistKerahatSettings(),
            onVoiceToggleChanged: (value) {
              setState(() => _showVoiceIcon = value);
              _persistReminderTexts();
            },
            onAzanToggleChanged: (value) {
              setState(() => _showAzanIcon = value);
              _persistReminderTexts();
            },
            onVibrationToggleChanged: (value) {
              setState(() => _showVibrationIcon = value);
              _persistReminderTexts();
            },
            onPrayerSilenceToggleChanged: (value) {
              setState(() => _prayerSilenceEnabled = value);
              _persistReminderTexts();
              if (value) {
                _nativeNotificationScheduler
                    .openNotificationPolicySettings()
                    .then((_) {}, onError: (_) {});
              }
            },
            onSortChanged: (value) {
              setState(() => _sortCustomPrayersByTime = value ?? true);
              _persistReminderTexts();
            },
            onVibrationDurationChanged: (_) => _persistReminderTexts(),
            onVibrationPauseChanged: (_) => _persistReminderTexts(),
            onPrayerSilenceStartMinutesChanged: (_) =>
                _persistReminderTexts(),
            onPrayerSilenceDurationMinutesChanged: (_) =>
                _persistReminderTexts(),
            selectedAudioMode: _selectedAudioMode,
            onAudioModeChanged: (value) {
              if (value == null) return;
              setState(() => _selectedAudioMode = value);
              _persistReminderTexts();
            },
            onPickAudio: () => _pickReminderAudio(context),
            audioPickerButtonLabel: audioPickerButtonLabel(_selectedAudioMode),
            audioInfoText: audioInfoTextForSelection(
              selectedAudioLabel: _selectedAudioLabel,
              selectedAudioMode: _selectedAudioMode,
            ),
            onVoiceTest: () => _playVoiceReminderTest(context, l10n),
            voiceReminderController: _voiceReminderController,
            voiceRepeatController: _voiceRepeatController,
            onVoiceTextChanged: (_) => _persistReminderTexts(),
            onVoiceRepeatChanged: (_) => _persistReminderTexts(),
            panelColor: palette.zeminColor,
            textColor: palette.cizgiColor,
            customPrayerLabelColor: palette.customPrayerLabelColor,
            backgroundColor: draftBackgroundColor,
            hasPendingBackgroundChanges: hasPendingBackgroundChanges,
            onEditPanelColor: () => _editColor(
              context: context,
              title: 'Panel Rengi',
              initialColor: palette.zeminColor,
              onApply: widget.uiPaletteController.setZeminColor,
            ),
            onEditTextColor: () => _editColor(
              context: context,
              title: 'Yaz\u0131 Rengi',
              initialColor: palette.cizgiColor,
              onApply: widget.uiPaletteController.setCizgiColor,
            ),
            onEditCustomPrayerLabelColor: () => _editColor(
              context: context,
              title: 'Nafile Vakit',
              initialColor: palette.customPrayerLabelColor,
              onApply: widget.uiPaletteController.setCustomPrayerLabelColor,
            ),
            onEditBackgroundColor: () => _editColor(
              context: context,
              title: 'Arka Plan Zemini',
              initialColor: draftBackgroundColor,
              onApply: (color) async {
                setState(() {
                  _draftBackgroundColor = color;
                });
              },
            ),
            onApplyBackgroundStyle: () async {
              await _applyBackgroundDraft();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Arka plan se\u00e7imleri ana sayfaya uyguland\u0131.'),
                ),
              );
            },
            onResetInterfaceColors: () async {
              await widget.uiPaletteController.setZeminColor(
                ConfigRegistry.defaultPalette.zeminColor,
              );
              await widget.uiPaletteController.setCizgiColor(
                ConfigRegistry.defaultPalette.cizgiColor,
              );
              await widget.uiPaletteController.setCustomPrayerLabelColor(
                ConfigRegistry.defaultPalette.customPrayerLabelColor,
              );
              if (!context.mounted) return;
              setState(() {});
            },
            onResetBackgroundColors: () async {
              setState(() {
                _setBackgroundDraftFromPalette(ConfigRegistry.defaultPalette);
              });
            },
          ),
          Padding(
            padding: ui.screenPadding.copyWith(top: 0),
            child: SettingsSharedSectionsList(
              showHelpBalloons: _showHelpBalloons,
            ),
          ),
        ],
      ),
    );
  }
}
