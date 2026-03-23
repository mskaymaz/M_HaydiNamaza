import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/calculation_method_storage.dart';

class CalculationMethodScreen extends StatefulWidget {
  final String? initialCode;

  const CalculationMethodScreen({super.key, this.initialCode});

  @override
  State<CalculationMethodScreen> createState() => _CalculationMethodScreenState();
}

class _CalculationMethodScreenState extends State<CalculationMethodScreen> {
  final CalculationMethodStorage _storage = CalculationMethodStorage();
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCode ?? 'turkey';
  }

  Future<void> _save() async {
    await _storage.writeCode(_selected);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <_MethodItem>[
      _MethodItem('turkey', l10n.methodTurkey),
      const _MethodItem('diyanet_tabanli', 'Diyanet tabanlı'),
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
        child: RadioGroup<String>(
          groupValue: _selected,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selected = value;
            });
          },
          child: ListView(
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
      ),
    );
  }
}

class _MethodItem {
  final String code;
  final String label;

  const _MethodItem(this.code, this.label);
}
