import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/calculation_method_storage.dart';
import '../../app/locale_controller.dart';
import '../../app/location_favorites_storage.dart';
import '../../app/location_storage.dart';
import '../../app/reminder_audio_service.dart';
import '../../app/reminder_text_settings_storage.dart';
import '../../app/ui_palette_controller.dart';
import '../../core/config/config_registry.dart';
import '../reminders/flashing_reminder_card.dart';
import 'calculation_method_screen.dart';
import 'location_screen.dart';
import 'widgets/settings_color_picker_widgets.dart';
import 'widgets/settings_color_sections_group.dart';
import 'widgets/settings_shared_modules_group.dart';
import 'settings_audio_mode_texts.dart';
import 'settings_color_formatters.dart';
import 'settings_favorite_matcher.dart';
import 'settings_reminder_runtime_helpers.dart';
import 'settings_reminder_snapshot.dart';
import 'settings_text_formatters.dart';
import 'settings_ui_mappers.dart';
import 'settings_voice_key.dart';
import 'widgets/settings_reminder_sections_group.dart';
import 'widgets/settings_top_settings_section.dart';

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
  final ReminderTextSettingsStorage _reminderTextStorage =
      ReminderTextSettingsStorage();
  final ReminderAudioService _reminderAudioService = ReminderAudioService();
  final TextEditingController _voiceReminderController =
      TextEditingController();
  final TextEditingController _visualReminderController =
      TextEditingController();
  final TextEditingController _voiceRepeatController = TextEditingController();
  final TextEditingController _vibrationDurationController =
      TextEditingController();
  final TextEditingController _vibrationPauseController =
      TextEditingController();
  final TextEditingController _visualDisplayController =
      TextEditingController();
  final TextEditingController _visualReopenController = TextEditingController();
  final List<_VoiceOption> _voiceOptions = [];
  LocationData? _location;
  List<LocationFavorite> _favorites = [];
  LocationFavorite? _selectedFavorite;
  String? _methodCode;
  ReminderAudioMode _selectedAudioMode = ReminderAudioMode.textToSpeech;
  String? _selectedVoiceKey;
  String? _selectedAudioPath;
  String? _selectedAudioLabel;
  bool _showVoiceIcon = true;
  bool _showVisualIcon = true;
  bool _showAzanIcon = true;
  bool _showVibrationIcon = true;
  bool _sortCustomPrayersByTime = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadFavorites();
    _loadMethod();
    _loadReminderTexts();
    _loadVoiceOptions();
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
      code = 'turkey';
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
    _visualDisplayController.text = settings.visualDisplaySeconds.toString();
    _visualReopenController.text = settings.visualReopenSeconds.toString();
    _selectedAudioMode = settings.audioMode;
    _selectedAudioPath = settings.selectedAudioPath;
    _selectedAudioLabel = settings.selectedAudioLabel;
    _showVoiceIcon = settings.showVoiceIcon;
    _showVisualIcon = settings.showVisualIcon;
    _showAzanIcon = settings.showAzanIcon;
    _showVibrationIcon = settings.showVibrationIcon;
    _sortCustomPrayersByTime = settings.sortCustomPrayersByTime;
    if (settings.selectedVoiceName != null &&
        settings.selectedVoiceLocale != null) {
      _selectedVoiceKey = voiceKey(
        settings.selectedVoiceName!,
        settings.selectedVoiceLocale!,
      );
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadVoiceOptions() async {
    final options = await _reminderAudioService.loadVoiceOptions();
    if (!mounted) return;
    setState(() {
      _voiceOptions
        ..clear()
        ..addAll(
          options.map(
            (voice) => _VoiceOption(name: voice.name, locale: voice.locale),
          ),
        );
      if (_selectedVoiceKey != null &&
          !_voiceOptions.any((voice) => voice.key == _selectedVoiceKey)) {
        _selectedVoiceKey = null;
      }
    });
  }

  @override
  void dispose() {
    _voiceReminderController.dispose();
    _visualReminderController.dispose();
    _voiceRepeatController.dispose();
    _vibrationDurationController.dispose();
    _vibrationPauseController.dispose();
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
    final ui = ConfigRegistry.settingsPanelsFor(palette);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          SettingsTopSettingsSection(
            initialLanguageCode: codeForLocale(current),
            languageDecoration: _dropdownDecoration('Uygulama Dili'),
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
            onOpenCalculationMethod: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CalculationMethodScreen(initialCode: _methodCode),
                ),
              );
              if (changed == true) {
                await _loadMethod();
              }
            },
          ),
          SettingsReminderSectionsGroup(
            screenPadding: ui.screenPadding,
            panelStyle: ui.panel,
            showVoiceIcon: _showVoiceIcon,
            showVisualIcon: _showVisualIcon,
            showAzanIcon: _showAzanIcon,
            showVibrationIcon: _showVibrationIcon,
            sortCustomPrayersByTime: _sortCustomPrayersByTime,
            vibrationDurationController: _vibrationDurationController,
            vibrationPauseController: _vibrationPauseController,
            onVoiceToggleChanged: (value) {
              setState(() {
                _showVoiceIcon = value;
              });
              _persistReminderTexts();
            },
            onVisualToggleChanged: (value) {
              setState(() {
                _showVisualIcon = value;
              });
              _persistReminderTexts();
            },
            onAzanToggleChanged: (value) {
              setState(() {
                _showAzanIcon = value;
              });
              _persistReminderTexts();
            },
            onVibrationToggleChanged: (value) {
              setState(() {
                _showVibrationIcon = value;
              });
              _persistReminderTexts();
            },
            onSortChanged: (value) {
              setState(() {
                _sortCustomPrayersByTime = value ?? true;
              });
              _persistReminderTexts();
            },
            onVibrationDurationChanged: (_) => _persistReminderTexts(),
            onVibrationPauseChanged: (_) => _persistReminderTexts(),
            selectedAudioMode: _selectedAudioMode,
            onAudioModeChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedAudioMode = value;
              });
              _persistReminderTexts();
            },
            selectedVoiceKey: _selectedVoiceKey,
            voiceItems: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Sistem Varsayılanı'),
              ),
              ..._voiceOptions.map(
                (voice) => DropdownMenuItem<String?>(
                  value: voice.key,
                  child: Text(voice.label),
                ),
              ),
            ],
            onVoiceChanged: (value) {
              setState(() {
                _selectedVoiceKey = value;
              });
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
            visualReminderController: _visualReminderController,
            visualDisplayController: _visualDisplayController,
            visualReopenController: _visualReopenController,
            onVisualTextChanged: (_) => _persistReminderTexts(),
            onVisualDisplayChanged: (_) => _persistReminderTexts(),
            onVisualReopenChanged: (_) => _persistReminderTexts(),
            onShowPreview: () => _showVisualReminderPreview(context, l10n),
          ),
          SettingsColorSectionsGroup(
            outerPadding: ui.screenPadding.copyWith(top: 0),
            panelStyle: ui.panel,
            panelColor: palette.zeminColor,
            textColor: palette.cizgiColor,
            backgroundColor: palette.backgroundZeminColor,
            backgroundLineColor: palette.backgroundCizgiColor,
            onEditPanelColor: () => _editColor(
              context: context,
              title: 'Panel Rengi',
              initialColor: palette.zeminColor,
              onApply: widget.uiPaletteController.setZeminColor,
            ),
            onEditTextColor: () => _editColor(
              context: context,
              title: 'Yazı Rengi',
              initialColor: palette.cizgiColor,
              onApply: widget.uiPaletteController.setCizgiColor,
            ),
            onEditBackgroundColor: () => _editColor(
              context: context,
              title: 'Arka Plan Zemin',
              initialColor: palette.backgroundZeminColor,
              onApply: widget.uiPaletteController.setBackgroundZeminColor,
            ),
            onEditBackgroundLineColor: () => _editColor(
              context: context,
              title: 'Arka Plan Çizgi Rengi',
              initialColor: palette.backgroundCizgiColor,
              onApply: widget.uiPaletteController.setBackgroundCizgiColor,
            ),
            onResetInterfaceColors: () async {
              await widget.uiPaletteController.setZeminColor(
                ConfigRegistry.defaultPalette.zeminColor,
              );
              await widget.uiPaletteController.setCizgiColor(
                ConfigRegistry.defaultPalette.cizgiColor,
              );
              if (!context.mounted) return;
              setState(() {});
            },
            onResetBackgroundColors: () async {
              await widget.uiPaletteController.setBackgroundZeminColor(
                ConfigRegistry.defaultPalette.backgroundZeminColor,
              );
              await widget.uiPaletteController.setBackgroundCizgiColor(
                ConfigRegistry.defaultPalette.backgroundCizgiColor,
              );
              if (!context.mounted) return;
              setState(() {});
            },
          ),
          SettingsSharedModulesGroup(
            outerPadding: ui.screenPadding.copyWith(top: 0),
            panelStyle: ui.panel,
          ),
        ],
      ),
    );
  }

  Future<void> _persistReminderTexts() async {
    await _reminderTextStorage.write(_currentReminderSettingsSnapshot());
  }

  Future<void> _playVoiceReminderTest(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final settings = _currentReminderSettingsSnapshot();
    if (settings.audioMode != ReminderAudioMode.textToSpeech &&
        (settings.selectedAudioPath?.trim().isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test için önce bir ses dosyası seçin.'),
        ),
      );
      return;
    }
    try {
      await _reminderAudioService.playReminder(
        settings: settings,
        selectedLocale: widget.localeController.value,
        prayerLabel: l10n.prayerDhuhr,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesli test başlatılamadı.')),
      );
    }
  }

  ReminderTextSettings _currentReminderSettingsSnapshot() {
    final selectedVoice = selectedVoiceOption<_VoiceOption>(
      selectedVoiceKey: _selectedVoiceKey,
      voiceOptions: _voiceOptions,
      keyOf: (voice) => voice.key,
    );
    return buildReminderSettingsSnapshot(
      voiceText: _voiceReminderController.text,
      visualText: _visualReminderController.text,
      audioMode: _selectedAudioMode,
      showVoiceIcon: _showVoiceIcon,
      showVisualIcon: _showVisualIcon,
      showAzanIcon: _showAzanIcon,
      showVibrationIcon: _showVibrationIcon,
      sortCustomPrayersByTime: _sortCustomPrayersByTime,
      voiceRepeatSecondsText: _voiceRepeatController.text,
      vibrationDurationSecondsText: _vibrationDurationController.text,
      vibrationPauseSecondsText: _vibrationPauseController.text,
      visualDisplaySecondsText: _visualDisplayController.text,
      visualReopenSecondsText: _visualReopenController.text,
      selectedVoiceName: selectedVoice?.name,
      selectedVoiceLocale: selectedVoice?.locale,
      selectedAudioPath: _selectedAudioPath,
      selectedAudioLabel: _selectedAudioLabel,
    );
  }

  Future<void> _showVisualReminderPreview(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final effectiveText = effectiveVisualReminderText(
      visualText: _visualReminderController.text,
      voiceText: _voiceReminderController.text,
    ).trim();
    if (effectiveText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görsel önizleme için önce metin girin.'),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          content: FlashingReminderCard(
            prayerLabel: '${toTurkishUpper(l10n.prayerDhuhr)} VAKTİ',
            message: effectiveText,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickReminderAudio(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: _selectedAudioMode == ReminderAudioMode.mp3File
          ? FileType.custom
          : FileType.audio,
      allowedExtensions: _selectedAudioMode == ReminderAudioMode.mp3File
          ? const ['mp3']
          : null,
    );
    final file = result == null || result.files.isEmpty
        ? null
        : result.files.first;
    final path = file?.path?.trim() ?? '';
    if (path.isEmpty) return;
    setState(() {
      _selectedAudioPath = path;
      _selectedAudioLabel = file?.name ?? path.split('\\').last;
    });
    await _persistReminderTexts();
  }

  InputDecoration _dropdownDecoration(String label) {
    final palette = widget.uiPaletteController.value;
    final ui = ConfigRegistry.settingsPanelsFor(palette);
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: ui.itemPanel.color,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: ui.itemPanel.borderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: ui.itemPanel.borderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: ui.itemPanel.borderRadius,
        borderSide: BorderSide(color: palette.zeminColor),
      ),
    );
  }

  Future<void> _editColor({
    required BuildContext context,
    required String title,
    required Color initialColor,
    required Future<void> Function(Color color) onApply,
  }) async {
    var draft = HSVColor.fromColor(initialColor);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('$title Rengi'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: draft.toColor(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        hexColor(draft.toColor()),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: draft.value > 0.6
                              ? Colors.black87
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 220,
                      child: Row(
                        children: [
                          Expanded(
                            child: ColorSpectrum(
                              hsv: draft,
                              onChanged: (saturation, value) {
                                setState(() {
                                  draft = draft
                                      .withSaturation(saturation)
                                      .withValue(value);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          HueStrip(
                            hue: draft.hue,
                            onChanged: (hue) {
                              setState(() {
                                draft = draft.withHue(hue);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () async {
                    await onApply(draft.toColor());
                    if (mounted) {
                      setState(() {});
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Uygula'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}

class _VoiceOption {
  final String name;
  final String locale;

  const _VoiceOption({required this.name, required this.locale});

  String get key => '$locale|$name';
  String get label => '$name ($locale)';
}


