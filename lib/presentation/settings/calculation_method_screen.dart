import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/calculation_advanced_settings_storage.dart';
import '../../app/calculation_method_storage.dart';

class CalculationMethodScreen extends StatefulWidget {
  final String? initialCode;

  const CalculationMethodScreen({super.key, this.initialCode});

  @override
  State<CalculationMethodScreen> createState() =>
      _CalculationMethodScreenState();
}

class _CalculationMethodScreenState extends State<CalculationMethodScreen> {
  final CalculationMethodStorage _storage = CalculationMethodStorage();
  final CalculationAdvancedSettingsStorage _advancedStorage =
      CalculationAdvancedSettingsStorage();

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = _safeInitialCode(widget.initialCode);
  }

  String _safeInitialCode(String? code) {
    if (code == 'diyanet_tabanli') return 'diyanet';
    const supported = <String>{
      'aladhan',
      'turkey',
      'diyanet',
      'umm_al_qura',
      'muslim_world_league',
      'moonsighting',
      'north_america',
    };
    return supported.contains(code)
        ? code!
        : CalculationMethodStorage.defaultCode;
  }

  Future<void> _save() async {
    await _storage.writeCode(_selected);
    await _advancedStorage.write(const CalculationAdvancedSettings());
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <_MethodItem>[
      const _MethodItem('diyanet', 'Diyanet'),
      _MethodItem('turkey', l10n.methodTurkey),
      _MethodItem('aladhan', l10n.methodAladhan),
      _MethodItem('umm_al_qura', l10n.methodUmmAlQura),
      _MethodItem('muslim_world_league', l10n.methodMuslimWorldLeague),
      _MethodItem('moonsighting', l10n.methodMoonsighting),
      _MethodItem('north_america', l10n.methodNorthAmerica),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 7,
        title: const Text(
          'Vakit Hesabı',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
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
        ],
      ),
      body: ListTileTheme(
        horizontalTitleGap: 7,
        minLeadingWidth: 7,
        child: ListView(
          children: [
            Column(
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

                      // ignore: deprecated_member_use
                      groupValue: _selected,

                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selected = value);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
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

