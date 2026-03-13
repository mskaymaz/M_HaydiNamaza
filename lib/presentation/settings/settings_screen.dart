import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../app/calculation_method_storage.dart';
import '../../app/locale_controller.dart';
import '../../app/location_storage.dart';
import 'calculation_method_screen.dart';
import 'location_screen.dart';

class SettingsScreen extends StatefulWidget {
  final LocaleController localeController;

  const SettingsScreen({super.key, required this.localeController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocationStorage _locationStorage = LocationStorage();
  final CalculationMethodStorage _methodStorage = CalculationMethodStorage();
  LocationData? _location;
  String? _methodCode;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadMethod();
  }

  Future<void> _loadLocation() async {
    final data = await _locationStorage.read();
    if (!mounted) return;
    setState(() {
      _location = data;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = widget.localeController.value;

    String locationSubtitle() {
      final data = _location;
      if (data == null) return l10n.locationNotSet;
      return '${data.city} (${data.latitude}, ${data.longitude})';
    }

    String methodSubtitle() {
      switch (_methodCode) {
        case 'turkey':
          return l10n.methodTurkey;
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
          ListTile(
            title: Text(l10n.languageLabel),
          ),
          RadioListTile<String>(
            title: Text(l10n.languageSystem),
            value: 'system',
            groupValue: codeFor(current),
            onChanged: (value) async {
              if (value == null) return;
              await widget.localeController.setLocale(localeFor(value));
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.languageTurkish),
            value: 'tr',
            groupValue: codeFor(current),
            onChanged: (value) async {
              if (value == null) return;
              await widget.localeController.setLocale(localeFor(value));
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.languageEnglish),
            value: 'en',
            groupValue: codeFor(current),
            onChanged: (value) async {
              if (value == null) return;
              await widget.localeController.setLocale(localeFor(value));
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.languageArabic),
            value: 'ar',
            groupValue: codeFor(current),
            onChanged: (value) async {
              if (value == null) return;
              await widget.localeController.setLocale(localeFor(value));
            },
          ),
          const Divider(height: 32),
          ListTile(
            title: Text(l10n.locationLabel),
            subtitle: Text(locationSubtitle()),
            trailing: const Icon(Icons.location_on_outlined),
            onTap: () async {
              final changed = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => LocationScreen(initial: _location),
                ),
              );
              if (changed == true) {
                await _loadLocation();
              }
            },
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
        ],
      ),
    );
  }
}
