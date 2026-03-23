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
        title: Text(l10n.methodEditTitle),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.methodSave),
          ),
        ],
      ),
      body: RadioGroup<String>(
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
                  title: Text(item.label),
                  value: item.code,
                ),
              )
              .toList(),
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
