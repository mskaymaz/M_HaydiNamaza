import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'widgets/settings_calculation_method_row.dart';
import 'widgets/settings_language_location_row.dart';
import 'widgets/settings_reminder_options_section.dart';
import 'widgets/settings_visual_reminder_section.dart';
import 'widgets/settings_voice_reminder_section.dart';

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
    final matched = _matchFavorite(data, _favorites);
    setState(() {
      _location = data;
      _selectedFavorite = matched;
    });
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesStorage.read();
    if (!mounted) return;
    final matched = _matchFavorite(_location, favorites);
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
      _selectedVoiceKey = _voiceKey(
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

    String methodSubtitle() {
        switch (_methodCode) {
        case 'turkey':
          return 'Türkiye (Diyanet)';
        case 'diyanet_tabanli':
          return 'Diyanet tabanlı';
        case 'aladhan':
          return l10n.methodAladhan;
        case 'muslim_world_league':
          return l10n.methodMuslimWorldLeague;
        case 'umm_al_qura':
          return l10n.methodUmmAlQura;
        case 'dubai':
          return l10n.methodDubai;
        case 'kuwait':
          return l10n.methodKuwait;
        case 'qatar':
          return l10n.methodQatar;
        case 'singapore':
          return l10n.methodSingapore;
        case 'tehran':
          return l10n.methodTehran;
        case 'moonsighting':
          return l10n.methodMoonsighting;
        case 'north_america':
          return l10n.methodNorthAmerica;
        case 'egyptian':
          return l10n.methodEgyptian;
        case 'karachi':
          return l10n.methodKarachi;
        case 'other':
          return l10n.methodOther;
        default:
          return l10n.methodNotSet;
      }
    }

    String codeFor(Locale? locale) => locale?.languageCode ?? 'system';

    Locale? localeFor(String code) {
      switch (code) {
        case 'tr':
          return const Locale('tr');
        case 'en':
          return const Locale('en');
        case 'ar':
          return const Locale('ar');
        case 'system':
        default:
          return null;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          SettingsLanguageLocationRow(
            initialLanguageCode: codeFor(current),
            languageDecoration: _dropdownDecoration('Uygulama Dili'),
            languageSystemLabel: l10n.languageSystem,
            languageTurkishLabel: l10n.languageTurkish,
            languageEnglishLabel: l10n.languageEnglish,
            languageArabicLabel: l10n.languageArabic,
            onLanguageChanged: (value) async {
              await widget.localeController.setLocale(localeFor(value));
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
          ),
          SettingsCalculationMethodRow(
            itemPanelStyle: ui.itemPanel,
            title: l10n.calculationMethodLabel,
            subtitle: methodSubtitle(),
            onTap: () async {
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
          const Divider(height: 32),
          SettingsReminderOptionsSection(
            outerPadding: ui.screenPadding,
            panelStyle: ui.panel,
            reminderOptionsHeader: const _SectionHeader(
              title: 'Hatırlatma Seçenekleri',
              tooltip:
                  'Buradaki seçimler vakitler panelinde hangi hatırlatıcı ikonlarının görüneceğini belirler.',
            ),
            vibrationHeader: const _SectionHeader(
              title: 'Titreşimle Uyarı Ayarları',
              tooltip:
                  'Titreşim süresi ve tekrar aralığı bu bölümden ayarlanır.',
            ),
            voiceToggle: _ReminderOptionToggle(
              label: 'Sesli',
              value: _showVoiceIcon,
              onChanged: (value) {
                setState(() {
                  _showVoiceIcon = value;
                });
                _persistReminderTexts();
              },
            ),
            visualToggle: _ReminderOptionToggle(
              label: 'Görsel',
              value: _showVisualIcon,
              onChanged: (value) {
                setState(() {
                  _showVisualIcon = value;
                });
                _persistReminderTexts();
              },
            ),
            azanToggle: _ReminderOptionToggle(
              label: 'Ezan',
              value: _showAzanIcon,
              onChanged: (value) {
                setState(() {
                  _showAzanIcon = value;
                });
                _persistReminderTexts();
              },
            ),
            vibrationToggle: _ReminderOptionToggle(
              label: 'Titreşim',
              value: _showVibrationIcon,
              onChanged: (value) {
                setState(() {
                  _showVibrationIcon = value;
                });
                _persistReminderTexts();
              },
            ),
            sortCustomPrayersByTime: _sortCustomPrayersByTime,
            onSortChanged: (value) {
              setState(() {
                _sortCustomPrayersByTime = value ?? true;
              });
              _persistReminderTexts();
            },
            vibrationDurationField: _ReminderNumberField(
              label: 'Titreşim Süresi (sn)',
              controller: _vibrationDurationController,
              onChanged: (_) => _persistReminderTexts(),
            ),
            vibrationPauseField: _ReminderNumberField(
              label: 'Titreşim Aralığı (sn)',
              controller: _vibrationPauseController,
              onChanged: (_) => _persistReminderTexts(),
            ),
          ),
          SettingsVoiceReminderSection(
            outerPadding: ui.screenPadding.copyWith(top: 0),
            panelStyle: ui.panel,
            header: const _SectionHeader(
              title: 'Sesli Hatırlatma',
              tooltip:
                  'Metni Oku açıldığında sesli hatırlatma metni ve sistem sesi seçimi görünür. Seçilen ses sesli testte ve hatırlatma okumasında kullanılır.',
            ),
            selectedAudioMode: _selectedAudioMode,
            audioModeItems: ReminderAudioMode.values
                .map(
                  (mode) => DropdownMenuItem<ReminderAudioMode>(
                    value: mode,
                    child: Text(_audioModeLabel(mode)),
                  ),
                )
                .toList(),
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
            audioPickerButtonLabel: _audioPickerButtonLabel(_selectedAudioMode),
            audioInfoText: _selectedAudioLabel?.trim().isNotEmpty == true
                ? 'Seçilen dosya: '
                : _audioPickerHelpText(_selectedAudioMode),
            onVoiceTest: () => _playVoiceReminderTest(context, l10n),
            voiceTextField: _ReminderTextField(
              label: 'Sesli Hatırlatma Metni',
              controller: _voiceReminderController,
              hintText: 'Sesli hatırlatmada okunacak metni girin.',
              onChanged: (_) => _persistReminderTexts(),
            ),
            voiceRepeatField: _ReminderNumberField(
              label: 'Sesli Hatırlatma Periyodu (sn)',
              controller: _voiceRepeatController,
              onChanged: (_) => _persistReminderTexts(),
            ),
          ),
          SettingsVisualReminderSection(
            outerPadding: ui.screenPadding.copyWith(top: 0),
            panelStyle: ui.panel,
            header: const _SectionHeader(
              title: 'Görsel Hatırlatma',
              tooltip:
                  'Görsel hatırlatma ayrı tutulur. Bu alan boşsa sesli hatırlatma metni kullanılır.',
            ),
            visualTextField: _ReminderTextField(
              label: 'Görsel Hatırlatma Metni',
              controller: _visualReminderController,
              hintText:
                  'Buraya herhangi bir metin girilmediğinde sesli hatırlatmadaki metin kullanılacaktır.',
              onChanged: (_) => _persistReminderTexts(),
              maxLines: 3,
            ),
            visualDisplayField: _ReminderNumberField(
              label: 'Ekranda Kalma (sn)',
              controller: _visualDisplayController,
              onChanged: (_) => _persistReminderTexts(),
            ),
            visualReopenField: _ReminderNumberField(
              label: 'Kapanıp Açılma (sn)',
              controller: _visualReopenController,
              onChanged: (_) => _persistReminderTexts(),
            ),
            onShowPreview: () => _showVisualReminderPreview(context, l10n),
          ),
          Padding(
            padding: ui.screenPadding.copyWith(top: 0),
            child: _SettingsPanel(
              style: ui.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'Arayüz Renkleri',
                    tooltip: 'Panel ve yazı renklerini değiştir.',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ColorActionTile(
                          title: 'Panel Rengi',
                          color: palette.zeminColor,
                          onTap: () => _editColor(
                            context: context,
                            title: 'Panel Rengi',
                            initialColor: palette.zeminColor,
                            onApply: widget.uiPaletteController.setZeminColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _ColorActionTile(
                          title: 'Yazı Rengi',
                          color: palette.cizgiColor,
                          onTap: () => _editColor(
                            context: context,
                            title: 'Yazı Rengi',
                            initialColor: palette.cizgiColor,
                            onApply: widget.uiPaletteController.setCizgiColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _ResetIconButton(
                        onTap: () async {
                          await widget.uiPaletteController.setZeminColor(
                            ConfigRegistry.defaultPalette.zeminColor,
                          );
                          await widget.uiPaletteController.setCizgiColor(
                            ConfigRegistry.defaultPalette.cizgiColor,
                          );
                          if (!context.mounted) return;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: ui.screenPadding.copyWith(top: 0),
            child: _SettingsPanel(
              style: ui.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: 'Arka Plan Renkleri',
                    tooltip:
                        'Geometrik arka planın zemin ve çizgi renklerini değiştir.',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ColorActionTile(
                          title: 'Zemin Rengi',
                          color: palette.backgroundZeminColor,
                          onTap: () => _editColor(
                            context: context,
                            title: 'Arka Plan Zemin',
                            initialColor: palette.backgroundZeminColor,
                            onApply: widget
                                .uiPaletteController
                                .setBackgroundZeminColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _ColorActionTile(
                          title: 'Çizgi Rengi',
                          color: palette.backgroundCizgiColor,
                          onTap: () => _editColor(
                            context: context,
                            title: 'Arka Plan Çizgi Rengi',
                            initialColor: palette.backgroundCizgiColor,
                            onApply: widget
                                .uiPaletteController
                                .setBackgroundCizgiColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _ResetIconButton(
                        onTap: () async {
                          await widget.uiPaletteController
                              .setBackgroundZeminColor(
                                ConfigRegistry
                                    .defaultPalette
                                    .backgroundZeminColor,
                              );
                          await widget.uiPaletteController
                              .setBackgroundCizgiColor(
                                ConfigRegistry
                                    .defaultPalette
                                    .backgroundCizgiColor,
                              );
                          if (!context.mounted) return;
                          setState(() {});
                        },
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

  Future<void> _persistReminderTexts() async {
    final selectedVoice = _selectedVoice();
    await _reminderTextStorage.write(
      ReminderTextSettings(
        voiceText: _voiceReminderController.text.trim(),
        visualText: _visualReminderController.text.trim(),
        audioMode: _selectedAudioMode,
        showVoiceIcon: _showVoiceIcon,
        showVisualIcon: _showVisualIcon,
        showAzanIcon: _showAzanIcon,
        showVibrationIcon: _showVibrationIcon,
        sortCustomPrayersByTime: _sortCustomPrayersByTime,
        voiceRepeatSeconds: _readSeconds(_voiceRepeatController, fallback: 15),
        vibrationDurationSeconds: _readSeconds(
          _vibrationDurationController,
          fallback: 3,
        ),
        vibrationPauseSeconds: _readSeconds(
          _vibrationPauseController,
          fallback: 5,
        ),
        visualDisplaySeconds: _readSeconds(
          _visualDisplayController,
          fallback: 6,
        ),
        visualReopenSeconds: _readSeconds(_visualReopenController, fallback: 4),
        selectedVoiceName: selectedVoice?.name,
        selectedVoiceLocale: selectedVoice?.locale,
        selectedAudioPath: _selectedAudioPath,
        selectedAudioLabel: _selectedAudioLabel,
      ),
    );
  }

  String _effectiveVisualReminderText() {
    final visualText = _visualReminderController.text.trim();
    if (visualText.isNotEmpty) return visualText;
    return _voiceReminderController.text.trim();
  }

  String _toTurkishUpper(String value) {
    return value.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }

  Future<void> _playVoiceReminderTest(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final settings = ReminderTextSettings(
      voiceText: _voiceReminderController.text.trim(),
      visualText: _visualReminderController.text.trim(),
      audioMode: _selectedAudioMode,
      showVoiceIcon: _showVoiceIcon,
      showVisualIcon: _showVisualIcon,
      showAzanIcon: _showAzanIcon,
      showVibrationIcon: _showVibrationIcon,
      sortCustomPrayersByTime: _sortCustomPrayersByTime,
      voiceRepeatSeconds: _readSeconds(_voiceRepeatController, fallback: 15),
      vibrationDurationSeconds: _readSeconds(
        _vibrationDurationController,
        fallback: 3,
      ),
      vibrationPauseSeconds: _readSeconds(
        _vibrationPauseController,
        fallback: 5,
      ),
      visualDisplaySeconds: _readSeconds(_visualDisplayController, fallback: 6),
      visualReopenSeconds: _readSeconds(_visualReopenController, fallback: 4),
      selectedVoiceName: _selectedVoice()?.name,
      selectedVoiceLocale: _selectedVoice()?.locale,
      selectedAudioPath: _selectedAudioPath,
      selectedAudioLabel: _selectedAudioLabel,
    );
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

  Future<void> _showVisualReminderPreview(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final effectiveText = _effectiveVisualReminderText().trim();
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
            prayerLabel: '${_toTurkishUpper(l10n.prayerDhuhr)} VAKTİ',
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

  String _voiceKey(String name, String locale) => '$locale|$name';

  _VoiceOption? _selectedVoice() {
    final key = _selectedVoiceKey;
    if (key == null) return null;
    for (final voice in _voiceOptions) {
      if (voice.key == key) {
        return voice;
      }
    }
    return null;
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

  String _audioModeLabel(ReminderAudioMode mode) {
    switch (mode) {
      case ReminderAudioMode.textToSpeech:
        return 'Metni Oku';
      case ReminderAudioMode.deviceAudio:
        return 'Telefon Melodisi';
      case ReminderAudioMode.mp3File:
        return 'MP3 Dosyasi';
    }
  }

  String _audioPickerButtonLabel(ReminderAudioMode mode) {
    switch (mode) {
      case ReminderAudioMode.textToSpeech:
        return 'Ses Dosyasi Sec';
      case ReminderAudioMode.deviceAudio:
        return 'Telefon Melodisi Sec';
      case ReminderAudioMode.mp3File:
        return 'MP3 Dosyasi Sec';
    }
  }

  String _audioPickerHelpText(ReminderAudioMode mode) {
    switch (mode) {
      case ReminderAudioMode.textToSpeech:
        return '';
      case ReminderAudioMode.deviceAudio:
        return 'Telefonunuzdaki ses dosyalarindan bir melodi secin.';
      case ReminderAudioMode.mp3File:
        return 'Yalniz mp3 dosyasi secilir.';
    }
  }

  int _readSeconds(TextEditingController controller, {required int fallback}) {
    final parsed = int.tryParse(controller.text.trim());
    if (parsed == null) return fallback;
    if (fallback == 0) {
      return parsed.clamp(0, 3600);
    }
    return parsed.clamp(1, 3600);
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
                        _hexColor(draft.toColor()),
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
                            child: _ColorSpectrum(
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
                          _HueStrip(
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

  String _normalizeSpacing(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _hexColor(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  LocationFavorite? _matchFavorite(
    LocationData? data,
    List<LocationFavorite> favorites,
  ) {
    if (data == null) return null;
    for (final favorite in favorites) {
      final sameCountry = (favorite.countryId ?? '') == (data.countryId ?? '');
      final sameProvince =
          _normalizeSpacing(favorite.province).toUpperCase() ==
          _normalizeSpacing(data.province).toUpperCase();
      final sameDistrict =
          _normalizeSpacing(favorite.district).toUpperCase() ==
          _normalizeSpacing(data.district).toUpperCase();
      if (sameCountry && sameProvince && sameDistrict) {
        return favorite;
      }
    }
    return null;
  }
}

class _SettingsPanel extends StatelessWidget {
  final SurfaceStyle style;
  final Widget child;

  const _SettingsPanel({required this.style, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: style.borderRadius,
        boxShadow: style.shadows,
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String tooltip;

  const _SectionHeader({required this.title, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(title),
                  content: Text(tooltip),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Tamam'),
                    ),
                  ],
                );
              },
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.info_outline, size: 19.2),
          ),
        ),
      ],
    );
  }
}

class _ColorActionTile extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ColorActionTile({
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
      ),
    );
  }
}

class _ResetIconButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const _ResetIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: const Icon(Icons.restart_alt_rounded),
      ),
    );
  }
}

class _ReminderTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const _ReminderTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: maxLines,
      maxLines: maxLines,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF4F1EA),
        hintStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
        labelStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ReminderNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _ReminderNumberField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF4F1EA),
        labelStyle: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _ReminderOptionToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReminderOptionToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: (next) => onChanged(next ?? false)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.black87),
        ),
      ],
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

class _FlashingReminderPreview extends StatefulWidget {
  final String prayerLabel;
  final String message;

  const _FlashingReminderPreview({
    required this.prayerLabel,
    required this.message,
  });

  @override
  State<_FlashingReminderPreview> createState() =>
      _FlashingReminderPreviewState();
}

class _FlashingReminderPreviewState extends State<_FlashingReminderPreview> {
  Timer? _timer;
  bool _isBright = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted) return;
      setState(() {
        _isBright = !_isBright;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isBright ? const Color(0xFFFFF2F2) : Colors.white;
    final borderColor = _isBright
        ? Colors.redAccent.withValues(alpha: 0.9)
        : Colors.redAccent.withValues(alpha: 0.5);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: _isBright ? 2 : 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.prayerLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ColorSpectrum extends StatelessWidget {
  final HSVColor hsv;
  final void Function(double saturation, double value) onChanged;

  const _ColorSpectrum({required this.hsv, required this.onChanged});

  void _update(Offset localPosition, Size size) {
    final dx = localPosition.dx.clamp(0.0, size.width);
    final dy = localPosition.dy.clamp(0.0, size.height);
    final saturation = size.width == 0 ? 0.0 : dx / size.width;
    final value = size.height == 0 ? 0.0 : 1 - (dy / size.height);
    onChanged(saturation.clamp(0.0, 1.0), value.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final indicatorOffset = Offset(
          hsv.saturation * size.width,
          (1 - hsv.value) * size.height,
        );
        return GestureDetector(
          onPanDown: (details) => _update(details.localPosition, size),
          onPanUpdate: (details) => _update(details.localPosition, size),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: indicatorOffset.dx - 9,
                top: indicatorOffset.dy - 9,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HueStrip extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const _HueStrip({required this.hue, required this.onChanged});

  void _update(Offset localPosition, double height) {
    final dy = localPosition.dy.clamp(0.0, height);
    final nextHue = height == 0 ? 0.0 : (dy / height) * 360;
    onChanged(nextHue.clamp(0.0, 360.0));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final top = ((hue / 360) * height).clamp(0.0, height);
        return SizedBox(
          width: 28,
          child: GestureDetector(
            onPanDown: (details) => _update(details.localPosition, height),
            onPanUpdate: (details) => _update(details.localPosition, height),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: top - 2,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

