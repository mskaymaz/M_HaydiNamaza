import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/calculation_method_storage.dart';
import '../../app/locale_controller.dart';
import '../../app/location_favorites_storage.dart';
import '../../app/location_storage.dart';
import '../../app/reminder_text_settings_storage.dart';
import '../../app/ui_palette_controller.dart';
import '../../core/config/config_registry.dart';
import 'calculation_method_screen.dart';
import 'location_screen.dart';

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
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _voiceReminderController = TextEditingController();
  final TextEditingController _visualReminderController = TextEditingController();
  final List<_VoiceOption> _voiceOptions = [];
  LocationData? _location;
  List<LocationFavorite> _favorites = [];
  LocationFavorite? _selectedFavorite;
  String? _methodCode;
  bool _voiceTextEnabled = true;
  String? _selectedVoiceKey;

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
      _selectedFavorite = _selectedFavorite != null &&
              favorites.contains(_selectedFavorite)
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
    _voiceTextEnabled = settings.voiceTextEnabled;
    if (settings.selectedVoiceName != null && settings.selectedVoiceLocale != null) {
      _selectedVoiceKey = _voiceKey(
        settings.selectedVoiceName!,
        settings.selectedVoiceLocale!,
      );
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadVoiceOptions() async {
    dynamic voices;
    try {
      voices = await _flutterTts.getVoices;
    } catch (_) {
      return;
    }
    if (voices is! List) return;
    final options = <_VoiceOption>[];
    for (final item in voices) {
      if (item is! Map) continue;
      final name = (item['name'] ?? '').toString().trim();
      final locale = (item['locale'] ?? '').toString().trim();
      if (name.isEmpty || locale.isEmpty) continue;
      options.add(_VoiceOption(name: name, locale: locale));
    }
    options.sort((a, b) => a.label.compareTo(b.label));
    if (!mounted) return;
    setState(() {
      _voiceOptions
        ..clear()
        ..addAll(options);
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
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = widget.localeController.value;
    final palette = widget.uiPaletteController.value;
    final ui = ConfigRegistry.settingsPanelsFor(palette);

    String locationSubtitle() {
      final data = _location;
      if (data == null) return l10n.locationNotSet;
      final coords = data.latitude.trim().isEmpty || data.longitude.trim().isEmpty
          ? ''
          : '\n${data.latitude}, ${data.longitude}';
      return '${_formatLocationSummary(data)}$coords';
    }

    String methodSubtitle() {
      switch (_methodCode) {
        case 'turkey':
          return l10n.methodTurkey;
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
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<String>(
              value: codeFor(current),
              decoration: _dropdownDecoration(l10n.languageLabel),
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.languageSystem),
                ),
                DropdownMenuItem(value: 'tr', child: Text(l10n.languageTurkish)),
                DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                DropdownMenuItem(value: 'ar', child: Text(l10n.languageArabic)),
              ],
              onChanged: (value) async {
                if (value == null) return;
                await widget.localeController.setLocale(localeFor(value));
              },
            ),
          ),
          ListTile(
            title: Text(l10n.calculationMethodLabel),
            subtitle: Text(methodSubtitle()),
            trailing: const Icon(Icons.calculate_outlined),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CalculationMethodScreen(
                    initialCode: _methodCode,
                  ),
                ),
              );
              if (changed == true) {
                await _loadMethod();
              }
            },
          ),
          const Divider(height: 32),
          Padding(
            padding: ui.screenPadding,
            child: _SettingsPanel(
              style: ui.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    title: 'Sesli Hatırlatma',
                    tooltip:
                        'Metni Oku açıldığında sesli hatırlatma metni ve sistem sesi seçimi görünür. Seçilen ses sesli testte ve hatırlatma okumasında kullanılır.',
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Metni Oku'),
                    value: _voiceTextEnabled,
                    onChanged: (value) {
                      setState(() {
                        _voiceTextEnabled = value;
                      });
                      _persistReminderTexts();
                    },
                  ),
                  if (_voiceTextEnabled) ...[
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      value: _selectedVoiceKey,
                      decoration: const InputDecoration(
                        labelText: 'Sistem Sesi',
                        border: OutlineInputBorder(),
                      ),
                      items: [
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
                      onChanged: (value) {
                        setState(() {
                          _selectedVoiceKey = value;
                        });
                        _persistReminderTexts();
                      },
                    ),
                    const SizedBox(height: 10),
                    _ReminderTextField(
                      label: 'Sesli Hatırlatma Metni',
                      controller: _voiceReminderController,
                      hintText: 'Sesli hatırlatmada okunacak metni girin.',
                      onChanged: (_) => _persistReminderTexts(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => _speakVoiceReminderTest(context, l10n),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Sesli Test'),
                      ),
                    ),
                  ],
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
                  const _SectionHeader(
                    title: 'Görsel Hatırlatma',
                    tooltip:
                        'Görsel hatırlatma ayrı tutulur. Bu alan boşsa sesli hatırlatma metni kullanılır.',
                  ),
                  const SizedBox(height: 10),
                  _ReminderTextField(
                    label: 'Görsel Hatırlatma Metni',
                    controller: _visualReminderController,
                    hintText:
                        'Buraya herhangi bir metin girilmediğinde sesli hatırlatmadaki metin kullanılacaktır.',
                    onChanged: (_) => _persistReminderTexts(),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _showVisualReminderPreview(context, l10n),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Görsel Yapıyı Göster'),
                    ),
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
                    tooltip: 'Geometrik arka planın zemin ve çizgi renklerini değiştir.',
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
                            onApply: widget.uiPaletteController
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
                            onApply: widget.uiPaletteController
                                .setBackgroundCizgiColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      _ResetIconButton(
                        onTap: () async {
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
        voiceTextEnabled: _voiceTextEnabled,
        selectedVoiceName: selectedVoice?.name,
        selectedVoiceLocale: selectedVoice?.locale,
      ),
    );
  }

  String _effectiveVisualReminderText() {
    final visualText = _visualReminderController.text.trim();
    if (visualText.isNotEmpty) return visualText;
    return _voiceReminderController.text.trim();
  }

  Future<void> _speakVoiceReminderTest(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (!_voiceTextEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce Metni Oku seçeneğini açın.')),
      );
      return;
    }
    final text = _voiceReminderController.text.trim();
    await _speakReminderPreview(
      context: context,
      previewText: text,
      prayerLabel: l10n.prayerDhuhr,
    );
  }

  Future<void> _speakReminderPreview({
    required BuildContext context,
    required String previewText,
    String prayerLabel = 'Öğle',
  }) async {
    final trimmed = previewText.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test için önce metin girin.')),
      );
      return;
    }
    final spokenText = '$prayerLabel vakti. $trimmed';
    try {
      await _speakWithFallback(spokenText);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesli test başlatılamadı.')),
      );
    }
  }

  Future<void> _applyPreferredVoice() async {
    final selectedVoice = _selectedVoice();
    final selected = widget.localeController.value;
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final locale = selected ?? deviceLocale;
    final localeKey = locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}-${locale.countryCode}';
    try {
      await _flutterTts.setLanguage(selectedVoice?.locale ?? localeKey);
    } catch (_) {
      try {
        await _flutterTts.setLanguage(locale.languageCode);
      } catch (_) {}
    }
    if (selectedVoice != null) {
      try {
        await _flutterTts.setVoice({
          'name': selectedVoice.name,
          'locale': selectedVoice.locale,
        });
        return;
      } catch (_) {}
    }
    dynamic voices;
    try {
      voices = await _flutterTts.getVoices;
    } catch (_) {
      return;
    }
    if (voices is! List) return;
    Map<String, dynamic>? selectedVoice;
    for (final voice in voices) {
      if (voice is! Map) continue;
      final name = (voice['name'] ?? '').toString().toLowerCase();
      final localeName = (voice['locale'] ?? '').toString().toLowerCase();
      final sameLocale =
          localeName.startsWith(locale.languageCode.toLowerCase());
      if (!sameLocale) continue;
      if (name.contains('male') ||
          name.contains('erkek') ||
          name.contains('man')) {
        selectedVoice = Map<String, dynamic>.from(voice);
        break;
      }
      selectedVoice ??= Map<String, dynamic>.from(voice);
    }
    if (selectedVoice == null) return;
    try {
      await _flutterTts.setVoice({
        'name': (selectedVoice['name'] ?? '').toString(),
        'locale': (selectedVoice['locale'] ?? localeKey).toString(),
      });
    } catch (_) {}
  }

  Future<void> _speakWithFallback(String spokenText) async {
    await _flutterTts.stop();
    try {
      await _flutterTts.awaitSpeakCompletion(true);
    } catch (_) {}
    try {
      await _applyPreferredVoice();
    } catch (_) {}
    try {
      await _flutterTts.setPitch(0.95);
    } catch (_) {}
    try {
      await _flutterTts.setSpeechRate(0.45);
    } catch (_) {}
    final result = await _flutterTts.speak(spokenText);
    if (result == 1 || result == null) {
      return;
    }
    await _flutterTts.setVoice(const <String, String>{});
    final retry = await _flutterTts.speak(spokenText);
    if (retry == 1 || retry == null) {
      return;
    }
    throw Exception('tts_failed');
  }

  Future<void> _showVisualReminderPreview(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final effectiveText = _effectiveVisualReminderText().trim();
    if (effectiveText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görsel önizleme için önce metin girin.')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          content: _FlashingReminderPreview(
            prayerLabel: '${l10n.prayerDhuhr.toUpperCase()} VAKTI',
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

  InputDecoration _dropdownDecoration(String label) {
    final palette = widget.uiPaletteController.value;
    final ui = ConfigRegistry.settingsPanelsFor(palette);
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: ui.itemPanel.color,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
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
                                  draft = draft.withSaturation(saturation).withValue(value);
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

  String _formatDisplayName(String input) {
    final trimmed = _normalizeSpacing(input);
    if (trimmed.isEmpty) return trimmed;
    final lower = trimmed
        .replaceAll('I', String.fromCharCode(0x0131))
        .replaceAll(String.fromCharCode(0x0130), 'i')
        .toLowerCase();
    final parts = lower.split(RegExp(r'(\s+|/|-)'));
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part.isEmpty) continue;
      final isSeparator = RegExp(r'^\s+$|^/$|^-$').hasMatch(part);
      if (isSeparator) {
        buffer.write(part);
        continue;
      }
      buffer.write(_capitalizeFirst(part[0]));
      if (part.length > 1) {
        buffer.write(part.substring(1));
      }
    }
    return buffer.toString();
  }

  String _capitalizeFirst(String char) {
    if (char == 'i') return String.fromCharCode(0x0130);
    if (char == String.fromCharCode(0x0131)) return 'I';
    return char.toUpperCase();
  }

  String _formatLocationSummary(LocationData data) {
    final province = _formatDisplayName(data.province);
    final district = _formatDisplayName(data.district);
    if (district.isEmpty) return province;
    return '$province / $district';
  }

  String _formatFavoriteLabel(LocationFavorite favorite) {
    return _formatLocationSummary(
      LocationData(
        countryId: favorite.countryId,
        countryName: favorite.countryName,
        province: favorite.province,
        district: favorite.district,
        latitude: favorite.latitude,
        longitude: favorite.longitude,
      ),
    );
  }

  String _currentFavoriteClosedLabel(AppLocalizations l10n) {
    final data = _location;
    if (data == null) return l10n.locationFavoritesLabel;
    return _formatLocationSummary(data);
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

  const _SettingsPanel({
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String tooltip;

  const _SectionHeader({
    required this.title,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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

  const _ResetIconButton({
    required this.onTap,
  });

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
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black87,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF4F1EA),
        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade400,
            ),
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
            ),
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _VoiceOption {
  final String name;
  final String locale;

  const _VoiceOption({
    required this.name,
    required this.locale,
  });

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
  State<_FlashingReminderPreview> createState() => _FlashingReminderPreviewState();
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ColorSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  const _ColorSlider({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 18, child: Text(label)),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            activeColor: activeColor,
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ColorSpectrum extends StatelessWidget {
  final HSVColor hsv;
  final void Function(double saturation, double value) onChanged;

  const _ColorSpectrum({
    required this.hsv,
    required this.onChanged,
  });

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
                      colors: [
                        Colors.transparent,
                        Colors.black,
                      ],
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
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 4,
                      ),
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

  const _HueStrip({
    required this.hue,
    required this.onChanged,
  });

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
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 3,
                        ),
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
