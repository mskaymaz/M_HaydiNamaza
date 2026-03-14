import 'package:flutter/material.dart';
import 'package:mhaydinamaza/l10n/app_localizations.dart';

import '../../app/location_storage.dart';

class LocationScreen extends StatefulWidget {
  final LocationData? initial;

  const LocationScreen({super.key, this.initial});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _cityController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _storage = LocationStorage();

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _cityController.text = initial.city;
      _latController.text = initial.latitude;
      _lonController.text = initial.longitude;
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final city = _cityController.text.trim();
    final lat = _latController.text.trim();
    final lon = _lonController.text.trim();
    if (city.isEmpty || lat.isEmpty || lon.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.locationFillAll)));
      return;
    }
    await _storage.write(LocationData(city: city, latitude: lat, longitude: lon));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locationEditTitle),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(l10n.locationSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _cityController,
            decoration: InputDecoration(labelText: l10n.locationCityLabel),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _latController,
            decoration: InputDecoration(labelText: l10n.locationLatitudeLabel),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lonController,
            decoration: InputDecoration(labelText: l10n.locationLongitudeLabel),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
        ],
      ),
    );
  }
}
