import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/calculation_advanced_settings_storage.dart';
import '../../app/calculation_method_storage.dart';

class CalculationMethodScreen extends StatefulWidget {
  final String? initialCode;

  const CalculationMethodScreen({super.key, this.initialCode});

  @override
  State<CalculationMethodScreen> createState() => _CalculationMethodScreenState();
}

class _CalculationMethodScreenState extends State<CalculationMethodScreen> {
  final CalculationMethodStorage _storage = CalculationMethodStorage();
  final CalculationAdvancedSettingsStorage _advancedStorage =
      CalculationAdvancedSettingsStorage();
  final TextEditingController _fajrOffsetController = TextEditingController();
  final TextEditingController _sunriseOffsetController = TextEditingController();
  final TextEditingController _dhuhrOffsetController = TextEditingController();
  final TextEditingController _asrOffsetController = TextEditingController();
  final TextEditingController _maghribOffsetController = TextEditingController();
  final TextEditingController _ishaOffsetController = TextEditingController();

  late String _selected;
  String _madhabCode = 'shafi';
  String _highLatitudeRuleCode = 'middle_of_the_night';
  String _shafaqCode = 'general';
  String _roundingCode = 'nearest';
  bool _advancedLoaded = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCode ?? 'turkey';
    _loadAdvancedSettings();
  }

  @override
  void dispose() {
    _fajrOffsetController.dispose();
    _sunriseOffsetController.dispose();
    _dhuhrOffsetController.dispose();
    _asrOffsetController.dispose();
    _maghribOffsetController.dispose();
    _ishaOffsetController.dispose();
    super.dispose();
  }

  Future<void> _loadAdvancedSettings() async {
    final settings = await _advancedStorage.read();
    if (!mounted) return;
    setState(() {
      _madhabCode = settings.madhabCode;
      _highLatitudeRuleCode = settings.highLatitudeRuleCode;
      _shafaqCode = settings.shafaqCode;
      _roundingCode = settings.roundingCode;
      _fajrOffsetController.text = settings.fajrOffsetMinutes.toString();
      _sunriseOffsetController.text = settings.sunriseOffsetMinutes.toString();
      _dhuhrOffsetController.text = settings.dhuhrOffsetMinutes.toString();
      _asrOffsetController.text = settings.asrOffsetMinutes.toString();
      _maghribOffsetController.text = settings.maghribOffsetMinutes.toString();
      _ishaOffsetController.text = settings.ishaOffsetMinutes.toString();
      _advancedLoaded = true;
    });
  }

  Future<void> _save() async {
    await _storage.writeCode(_selected);
    await _advancedStorage.write(
      CalculationAdvancedSettings(
        madhabCode: _madhabCode,
        highLatitudeRuleCode: _highLatitudeRuleCode,
        shafaqCode: _shafaqCode,
        roundingCode: _roundingCode,
        fajrOffsetMinutes: _parseOffset(_fajrOffsetController),
        sunriseOffsetMinutes: _parseOffset(_sunriseOffsetController),
        dhuhrOffsetMinutes: _parseOffset(_dhuhrOffsetController),
        asrOffsetMinutes: _parseOffset(_asrOffsetController),
        maghribOffsetMinutes: _parseOffset(_maghribOffsetController),
        ishaOffsetMinutes: _parseOffset(_ishaOffsetController),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  int _parseOffset(TextEditingController controller) {
    final parsed = int.tryParse(controller.text.trim()) ?? 0;
    return parsed.clamp(-120, 120);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <_MethodItem>[
      _MethodItem('turkey', l10n.methodTurkey),
      const _MethodItem('diyanet_tabanli', 'Diyanet tabanlı (deneysel)'),
      _MethodItem('aladhan', l10n.methodAladhan),
      _MethodItem('muslim_world_league', l10n.methodMuslimWorldLeague),
      _MethodItem('umm_al_qura', l10n.methodUmmAlQura),
      _MethodItem('dubai', l10n.methodDubai),
      _MethodItem('kuwait', l10n.methodKuwait),
      _MethodItem('qatar', l10n.methodQatar),
      _MethodItem('singapore', l10n.methodSingapore),
      _MethodItem('tehran', l10n.methodTehran),
      _MethodItem('moonsighting', l10n.methodMoonsighting),
      _MethodItem('north_america', l10n.methodNorthAmerica),
      _MethodItem('egyptian', l10n.methodEgyptian),
      _MethodItem('karachi', l10n.methodKarachi),
      _MethodItem('other', l10n.methodOther),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 7,
        title: const Text(
          'Hesaplama Yöntemi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          Transform.translate(
            offset: const Offset(-50, 0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE4F3E6),
                  foregroundColor: const Color(0xFF2F6F4F),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l10n.methodSave),
              ),
            ),
          ),
        ],
      ),
      body: ListTileTheme(
        horizontalTitleGap: 7,
        minLeadingWidth: 7,
        child: ListView(
          children: [
            RadioGroup<String>(
              groupValue: _selected,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selected = value;
                });
              },
              child: Column(
                children: items
                    .map(
                      (item) => RadioListTile<String>(
                        dense: true,
                        visualDensity: const VisualDensity(
                          horizontal: 0,
                          vertical: -4,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 7),
                        title: Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        value: item.code,
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'İleri Hesaplama Ayarları',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (!_advancedLoaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _madhabCode,
                      decoration: const InputDecoration(
                        labelText: 'Madhab',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'shafi', child: Text('Şafi')),
                        DropdownMenuItem(value: 'hanafi', child: Text('Hanefi')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _madhabCode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _highLatitudeRuleCode,
                      decoration: const InputDecoration(
                        labelText: 'Yüksek Enlem Kuralı',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'middle_of_the_night',
                          child: Text('Gecenin Yarısı'),
                        ),
                        DropdownMenuItem(
                          value: 'seventh_of_the_night',
                          child: Text('Gecenin Yedide Biri'),
                        ),
                        DropdownMenuItem(
                          value: 'twilight_angle',
                          child: Text('Alacakaranlık Açısı'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _highLatitudeRuleCode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _shafaqCode,
                      decoration: const InputDecoration(
                        labelText: 'Şafak',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('Genel')),
                        DropdownMenuItem(value: 'ahmer', child: Text('Ahmer')),
                        DropdownMenuItem(value: 'abyad', child: Text('Abyad')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _shafaqCode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _roundingCode,
                      decoration: const InputDecoration(
                        labelText: 'Yuvarlama',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'nearest', child: Text('En Yakın')),
                        DropdownMenuItem(value: 'up', child: Text('Yukarı')),
                        DropdownMenuItem(value: 'none', child: Text('Yok')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _roundingCode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Vakit Ofsetleri (dakika, -120..120)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _offsetField('İmsak', _fajrOffsetController),
                        const SizedBox(width: 8),
                        _offsetField('Güneş', _sunriseOffsetController),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _offsetField('Öğle', _dhuhrOffsetController),
                        const SizedBox(width: 8),
                        _offsetField('İkindi', _asrOffsetController),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _offsetField('Akşam', _maghribOffsetController),
                        const SizedBox(width: 8),
                        _offsetField('Yatsı', _ishaOffsetController),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _offsetField(String label, TextEditingController controller) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: false,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,3}$')),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _MethodItem {
  final String code;
  final String label;

  const _MethodItem(this.code, this.label);
}
