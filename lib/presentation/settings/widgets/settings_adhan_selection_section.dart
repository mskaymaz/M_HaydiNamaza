import 'package:flutter/material.dart';

import '../../../app/adhan_catalog.dart';

class SettingsAdhanSelectionSection extends StatefulWidget {
  final Map<String, AdhanSelection> selections;
  final Map<String, String> downloadedAdhanPaths;
  final Set<String> downloadingPrayerKeys;
  final ValueChanged<String> onUseDefault;
  final Future<void> Function(String prayerKey, AdhanCatalogOption option)
      onDownloadOption;
  final Future<void> Function(String prayerKey, AdhanCatalogOption option)
      onSelectDownloaded;
  final Future<void> Function(String prayerKey) onPickLocalFile;

  const SettingsAdhanSelectionSection({
    super.key,
    required this.selections,
    required this.downloadedAdhanPaths,
    required this.downloadingPrayerKeys,
    required this.onUseDefault,
    required this.onDownloadOption,
    required this.onSelectDownloaded,
    required this.onPickLocalFile,
  });

  @override
  State<SettingsAdhanSelectionSection> createState() =>
      _SettingsAdhanSelectionSectionState();
}

class _SettingsAdhanSelectionSectionState
    extends State<SettingsAdhanSelectionSection> {
  final Map<String, String?> _selectedOptionIds = <String, String?>{};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ezan okunacak vakitler ana sayfadaki cami ikonu ile açılır. '
          'İndirilen ezanlar bu listeden seçilir; dosya yeri aramanız gerekmez.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        for (final slot in kMainAdhanPrayerSlots) ...[
          _AdhanPrayerCard(
            slot: slot,
            selection: adhanSelectionForPrayer(widget.selections, slot.key),
            selectedOptionId: _selectedOptionIdFor(slot),
            downloadedAdhanPaths: widget.downloadedAdhanPaths,
            isDownloading: widget.downloadingPrayerKeys.contains(slot.key),
            onOptionChanged: (value) {
              setState(() => _selectedOptionIds[slot.key] = value);
            },
            onUseDefault: () => widget.onUseDefault(slot.key),
            onDownload: () async {
              final option = _optionFor(slot.key, _selectedOptionIdFor(slot));
              if (option == null) return;
              await widget.onDownloadOption(slot.key, option);
            },
            onSelectDownloaded: () async {
              final option = _optionFor(slot.key, _selectedOptionIdFor(slot));
              if (option == null) return;
              await widget.onSelectDownloaded(slot.key, option);
            },
            onPickLocalFile: () => widget.onPickLocalFile(slot.key),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String? _selectedOptionIdFor(AdhanPrayerSlot slot) {
    final options = adhanOptionsForPrayer(slot.key);
    if (options.isEmpty) return null;
    final manualId = _selectedOptionIds[slot.key];
    if (_hasOption(options, manualId)) return manualId;
    final selection = adhanSelectionForPrayer(widget.selections, slot.key);
    if (selection.source == AdhanSelectionSource.downloadable &&
        _hasOption(options, selection.optionId)) {
      return selection.optionId;
    }
    return options.first.id;
  }

  bool _hasOption(List<AdhanCatalogOption> options, String? optionId) {
    return optionId != null && options.any((option) => option.id == optionId);
  }

  AdhanCatalogOption? _optionFor(String prayerKey, String? optionId) {
    final options = adhanOptionsForPrayer(prayerKey);
    if (options.isEmpty) return null;
    return options.firstWhere(
      (option) => option.id == optionId,
      orElse: () => options.first,
    );
  }
}

class _AdhanPrayerCard extends StatelessWidget {
  final AdhanPrayerSlot slot;
  final AdhanSelection selection;
  final String? selectedOptionId;
  final Map<String, String> downloadedAdhanPaths;
  final bool isDownloading;
  final ValueChanged<String?> onOptionChanged;
  final VoidCallback onUseDefault;
  final Future<void> Function() onDownload;
  final Future<void> Function() onSelectDownloaded;
  final Future<void> Function() onPickLocalFile;

  const _AdhanPrayerCard({
    required this.slot,
    required this.selection,
    required this.selectedOptionId,
    required this.downloadedAdhanPaths,
    required this.isDownloading,
    required this.onOptionChanged,
    required this.onUseDefault,
    required this.onDownload,
    required this.onSelectDownloaded,
    required this.onPickLocalFile,
  });

  @override
  Widget build(BuildContext context) {
    final options = adhanOptionsForPrayer(slot.key);
    final selectedOption = _selectedOption(options);
    final selectedDownloaded = selectedOption != null &&
        (downloadedAdhanPaths[selectedOption.id]?.trim().isNotEmpty ?? false);
    final selectedActive = selectedOption != null &&
        selection.source == AdhanSelectionSource.downloadable &&
        selection.optionId == selectedOption.id;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  slot.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                _sourceLabel(selection.source),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Seçili: ${selection.label}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onUseDefault,
                icon: const Icon(Icons.restore_rounded),
                label: Text(
                  selection.source == AdhanSelectionSource.bundled
                      ? 'Varsayılan seçili'
                      : 'Varsayılan',
                ),
              ),
              OutlinedButton.icon(
                onPressed: isDownloading ? null : onPickLocalFile,
                icon: const Icon(Icons.audio_file_rounded),
                label: const Text('Yerel dosya'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedOptionId,
                  decoration: const InputDecoration(
                    labelText: 'İndirilebilir ezan',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: options
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(option.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: isDownloading ? null : onOptionChanged,
                ),
              ),
              const SizedBox(width: 8),
              _DownloadSelectButton(
                isDownloading: isDownloading,
                isDownloaded: selectedDownloaded,
                isSelected: selectedActive,
                onDownload: onDownload,
                onSelectDownloaded: onSelectDownloaded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  AdhanCatalogOption? _selectedOption(List<AdhanCatalogOption> options) {
    if (options.isEmpty) return null;
    return options.firstWhere(
      (option) => option.id == selectedOptionId,
      orElse: () => options.first,
    );
  }

  String _sourceLabel(AdhanSelectionSource source) {
    switch (source) {
      case AdhanSelectionSource.bundled:
        return 'Dahili';
      case AdhanSelectionSource.downloadable:
        return 'İndirilen';
      case AdhanSelectionSource.localFile:
        return 'Yerel';
    }
  }
}

class _DownloadSelectButton extends StatelessWidget {
  final bool isDownloading;
  final bool isDownloaded;
  final bool isSelected;
  final Future<void> Function() onDownload;
  final Future<void> Function() onSelectDownloaded;

  const _DownloadSelectButton({
    required this.isDownloading,
    required this.isDownloaded,
    required this.isSelected,
    required this.onDownload,
    required this.onSelectDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    if (isDownloading) {
      return FilledButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('İniyor'),
      );
    }
    if (isSelected) {
      return FilledButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('Seçili'),
      );
    }
    if (isDownloaded) {
      return FilledButton.icon(
        onPressed: onSelectDownloaded,
        icon: const Icon(Icons.check_rounded),
        label: const Text('Seç'),
      );
    }
    return FilledButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.download_rounded),
      label: const Text('İndir'),
    );
  }
}
