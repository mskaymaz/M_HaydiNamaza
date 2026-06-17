part of 'settings_screen.dart';

extension _SettingsAdhanController on _SettingsScreenState {
  Future<void> _loadAdhanSelections() async {
    final selections = await _adhanSelectionStorage.read();
    final downloadedPaths = await _adhanSelectionStorage.readDownloadedLocalPaths();
    final mergedDownloads = _mergeSelectionDownloads(selections, downloadedPaths);
    if (!mounted) return;
    _updateSettingsState(() {
      _adhanSelections = selections;
      _downloadedAdhanPaths = mergedDownloads;
    });
    if (mergedDownloads.length != downloadedPaths.length) {
      await _adhanSelectionStorage.writeDownloadedLocalPaths(mergedDownloads);
    }
  }

  Future<void> _useDefaultAdhan(String prayerKey) async {
    final updated = Map<String, AdhanSelection>.from(_adhanSelections);
    updated[prayerKey] = const AdhanSelection.bundled();
    _updateSettingsState(() => _adhanSelections = updated);
    await _adhanSelectionStorage.write(updated);
  }

  Future<void> _downloadAdhan(String prayerKey, AdhanCatalogOption option) async {
    if (_downloadingAdhanPrayerKeys.contains(prayerKey)) return;
    _updateSettingsState(() => _downloadingAdhanPrayerKeys.add(prayerKey));
    try {
      final localPath = await _adhanDownloader.downloadOption(option);
      final updatedSelections = Map<String, AdhanSelection>.from(_adhanSelections);
      final updatedDownloads = Map<String, String>.from(_downloadedAdhanPaths);
      updatedDownloads[option.id] = localPath;
      updatedSelections[prayerKey] = AdhanSelection.fromDownloadedOption(
        option: option,
        localPath: localPath,
      );
      if (!mounted) return;
      _updateSettingsState(() {
        _adhanSelections = updatedSelections;
        _downloadedAdhanPaths = updatedDownloads;
      });
      await _adhanSelectionStorage.write(updatedSelections);
      await _adhanSelectionStorage.writeDownloadedOption(
        optionId: option.id,
        localPath: localPath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${option.label} indirildi ve seçildi.')),
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

  Future<void> _selectDownloadedAdhan(
    String prayerKey,
    AdhanCatalogOption option,
  ) async {
    final localPath = _downloadedAdhanPaths[option.id]?.trim() ?? '';
    if (localPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ezan önce indirilmelidir.')),
      );
      return;
    }
    final updated = Map<String, AdhanSelection>.from(_adhanSelections);
    updated[prayerKey] = AdhanSelection.fromDownloadedOption(
      option: option,
      localPath: localPath,
    );
    _updateSettingsState(() => _adhanSelections = updated);
    await _adhanSelectionStorage.write(updated);
  }

  Future<void> _pickLocalAdhan(String prayerKey) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    final file = result == null || result.files.isEmpty ? null : result.files.first;
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

  Future<void> _previewDefaultAdhan() async {
    await _startAdhanPreview(
      key: _defaultAdhanPreviewKey,
      action: _adhanDownloader.previewBundled,
    );
  }

  Future<void> _previewDownloadedAdhan(AdhanCatalogOption option) async {
    final localPath = _downloadedAdhanPaths[option.id]?.trim() ?? '';
    if (localPath.isEmpty) {
      _showAdhanError('Bu ezan önce indirilmelidir.');
      return;
    }
    await _startAdhanPreview(
      key: _downloadedAdhanPreviewKey(option.id),
      action: () => _adhanDownloader.previewFile(localPath),
    );
  }

  Future<void> _previewLocalAdhan(String prayerKey) async {
    final selection = adhanSelectionForPrayer(_adhanSelections, prayerKey);
    final localPath = selection.localPath?.trim() ?? '';
    if (selection.source != AdhanSelectionSource.localFile || localPath.isEmpty) {
      _showAdhanError('Önce yerel ezan dosyası seçin.');
      return;
    }
    await _startAdhanPreview(
      key: _localAdhanPreviewKey(prayerKey),
      action: () => _adhanDownloader.previewFile(localPath),
    );
  }

  Future<void> _stopAdhanPreview() async {
    try {
      await _adhanDownloader.stopPreview();
    } catch (_) {}
    if (!mounted) return;
    _updateSettingsState(() => _activeAdhanPreviewKey = null);
  }

  Future<void> _deleteDownloadedAdhan(AdhanCatalogOption option) async {
    final localPath = _downloadedAdhanPaths[option.id]?.trim() ?? '';
    if (localPath.isNotEmpty) {
      try {
        await _adhanDownloader.deleteFile(localPath);
      } catch (_) {}
    }
    final updatedDownloads = Map<String, String>.from(_downloadedAdhanPaths)
      ..remove(option.id);
    final updatedSelections = Map<String, AdhanSelection>.from(_adhanSelections);
    for (final entry in updatedSelections.entries.toList()) {
      final selection = entry.value;
      if (selection.source == AdhanSelectionSource.downloadable &&
          selection.optionId == option.id) {
        updatedSelections[entry.key] = const AdhanSelection.bundled();
      }
    }
    if (_activeAdhanPreviewKey == _downloadedAdhanPreviewKey(option.id)) {
      await _stopAdhanPreview();
    }
    _updateSettingsState(() {
      _downloadedAdhanPaths = updatedDownloads;
      _adhanSelections = updatedSelections;
    });
    await _adhanSelectionStorage.write(updatedSelections);
    await _adhanSelectionStorage.removeDownloadedOption(option.id);
  }

  Future<void> _clearLocalAdhan(String prayerKey) async {
    final selection = adhanSelectionForPrayer(_adhanSelections, prayerKey);
    if (selection.source != AdhanSelectionSource.localFile) return;
    if (_activeAdhanPreviewKey == _localAdhanPreviewKey(prayerKey)) {
      await _stopAdhanPreview();
    }
    final updated = Map<String, AdhanSelection>.from(_adhanSelections);
    updated[prayerKey] = const AdhanSelection.bundled();
    _updateSettingsState(() => _adhanSelections = updated);
    await _adhanSelectionStorage.write(updated);
  }

  Future<void> _startAdhanPreview({
    required String key,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
      if (!mounted) return;
      _updateSettingsState(() => _activeAdhanPreviewKey = key);
    } catch (_) {
      if (!mounted) return;
      _updateSettingsState(() => _activeAdhanPreviewKey = null);
      _showAdhanError('Ezan dinletisi başlatılamadı.');
    }
  }

  void _showAdhanError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _defaultAdhanPreviewKey => 'bundled';

  String _downloadedAdhanPreviewKey(String optionId) => 'downloaded:$optionId';

  String _localAdhanPreviewKey(String prayerKey) => 'local:$prayerKey';

  Map<String, String> _mergeSelectionDownloads(
    Map<String, AdhanSelection> selections,
    Map<String, String> downloadedPaths,
  ) {
    final result = Map<String, String>.from(downloadedPaths);
    for (final selection in selections.values) {
      final optionId = selection.optionId?.trim() ?? '';
      final localPath = selection.localPath?.trim() ?? '';
      if (selection.source == AdhanSelectionSource.downloadable &&
          optionId.isNotEmpty &&
          localPath.isNotEmpty) {
        result[optionId] = localPath;
      }
    }
    return result;
  }
}
