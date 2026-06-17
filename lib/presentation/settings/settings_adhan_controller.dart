part of 'settings_screen.dart';

extension _SettingsAdhanController on _SettingsScreenState {
  Future<void> _loadAdhanSelections() async {
    final selections = await _adhanSelectionStorage.read();
    if (!mounted) return;
    _updateSettingsState(() => _adhanSelections = selections);
  }

  Future<void> _useDefaultAdhan(String prayerKey) async {
    final updated = Map<String, AdhanSelection>.from(_adhanSelections);
    updated[prayerKey] = const AdhanSelection.bundled();
    _updateSettingsState(() => _adhanSelections = updated);
    await _adhanSelectionStorage.write(updated);
  }

  Future<void> _downloadAdhan(
    String prayerKey,
    AdhanCatalogOption option,
  ) async {
    if (_downloadingAdhanPrayerKeys.contains(prayerKey)) return;
    _updateSettingsState(() => _downloadingAdhanPrayerKeys.add(prayerKey));
    try {
      final localPath = await _adhanDownloader.downloadOption(option);
      final updated = Map<String, AdhanSelection>.from(_adhanSelections);
      updated[prayerKey] = AdhanSelection.fromDownloadedOption(
        option: option,
        localPath: localPath,
      );
      if (!mounted) return;
      _updateSettingsState(() => _adhanSelections = updated);
      await _adhanSelectionStorage.write(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${option.label} indirildi.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ezan indirilemedi.')),
      );
    } finally {
      if (mounted) {
        _updateSettingsState(() => _downloadingAdhanPrayerKeys.remove(prayerKey));
      }
    }
  }

  Future<void> _pickLocalAdhan(String prayerKey) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final file = result == null || result.files.isEmpty
        ? null
        : result.files.first;
    final path = file?.path?.trim() ?? '';
    if (path.isEmpty) return;
    final updated = Map<String, AdhanSelection>.from(_adhanSelections);
    updated[prayerKey] = AdhanSelection.fromLocalFile(
      label: file?.name ?? path.split('\\').last,
      localPath: path,
    );
    _updateSettingsState(() => _adhanSelections = updated);
    await _adhanSelectionStorage.write(updated);
  }
}
