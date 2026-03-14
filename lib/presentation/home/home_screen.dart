import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/calculation_method_storage.dart';
import '../../app/locale_controller.dart';
import '../../app/location_storage.dart';
import '../../app/prayer_service.dart';
import '../../core/prayer_engine/prayer_times.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final LocaleController localeController;

  const HomeScreen({super.key, required this.localeController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _locationStorage = LocationStorage();
  final _methodStorage = CalculationMethodStorage();
  final _prayerService = PrayerService();

  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_HomeData> _loadData() async {
    final location = await _locationStorage.read();
    var methodCode = await _methodStorage.readCode();
    methodCode ??= 'turkey';
    if (location == null) {
      return _HomeData(location: null, methodCode: methodCode);
    }

    final lat = double.tryParse(location.latitude);
    final lon = double.tryParse(location.longitude);
    if (lat == null || lon == null) {
      return _HomeData(
        location: location,
        methodCode: methodCode,
        error: 'invalid_location',
      );
    }

    final timeZone = _offsetToTz(DateTime.now().timeZoneOffset);
    final times = _prayerService.calculateToday(
      latitude: lat,
      longitude: lon,
      timeZone: timeZone,
      methodCode: methodCode,
    );

    return _HomeData(
      location: location,
      methodCode: methodCode,
      times: times,
    );
  }

  String _offsetToTz(Duration offset) {
    final totalMinutes = offset.inMinutes;
    final sign = totalMinutes < 0 ? '-' : '+';
    final total = totalMinutes.abs();
    final hours = (total ~/ 60).toString().padLeft(2, '0');
    final mins = (total % 60).toString().padLeft(2, '0');
    return '$sign$hours:$mins';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _methodLabel(AppLocalizations l10n, String code) {
    switch (code) {
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

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          localeController: widget.localeController,
        ),
      ),
    );
    setState(() {
      _future = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.location == null) {
            return Center(
              child: Text(
                l10n.locationNotSet,
                textAlign: TextAlign.center,
              ),
            );
          }

          if (data.error == 'invalid_location') {
            return Center(
              child: Text(
                l10n.locationFillAll,
                textAlign: TextAlign.center,
              ),
            );
          }

          final times = data.times;
          if (times == null) {
            return Center(
              child: Text(
                l10n.comingSoon,
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${l10n.locationLabel}: ${data.location!.city}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.calculationMethodLabel}: ${_methodLabel(l10n, data.methodCode ?? 'turkey')}',
              ),
              const SizedBox(height: 16),
              _timeTile(l10n.prayerFajr, times.fajr),
              _timeTile(l10n.prayerSunrise, times.sunrise),
              _timeTile(l10n.prayerDhuhr, times.dhuhr),
              _timeTile(l10n.prayerAsr, times.asr),
              _timeTile(l10n.prayerMaghrib, times.maghrib),
              _timeTile(l10n.prayerIsha, times.isha),
            ],
          );
        },
      ),
    );
  }

  Widget _timeTile(String label, DateTime time) {
    return ListTile(
      title: Text(label),
      trailing: Text(_formatTime(time)),
    );
  }
}

class _HomeData {
  final LocationData? location;
  final String? methodCode;
  final PrayerTimes? times;
  final String? error;

  _HomeData({
    required this.location,
    required this.methodCode,
    this.times,
    this.error,
  });
}
