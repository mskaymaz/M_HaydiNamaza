import 'package:flutter/material.dart';

import '../../../app/adhan_catalog.dart';

class SettingsAdhanSelectionSection extends StatefulWidget {
  final Map<String, AdhanSelection> selections;
  final Set<String> downloadingPrayerKeys;
  final ValueChanged<String> onUseDefault;
  final Future<void> Function(String prayerKey, AdhanCatalogOption option)
      onDownloadOption;
  final Future<void> Function(String prayerKey) onPickLocalFile;

  const SettingsAdhanSelectionSection({
    super.key,
    required this.selections,
    required this.downloadingPrayerKeys,
    required this.onUseDefault,
    required this.onDownloadOption,
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
          'Seçim yapılmazsa uygulama içindeki varsayılan ezan okunur.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        for (final slot in kMainAdhanPrayerSlots) ...[
          _AdhanPrayerCard(
            slot: slot,
            selection: adhanSelectionForPrayer(widget.selections, slot.key),
            selectedOptionId: _selectedOptionIdFor(slot.key),
            isDownloading: widget.downloadingPrayerKeys.contains(slot.key),
            onOptionChanged: (value) {
              setState(() => _selectedOptionIds[slot.key] = value);
            },
            onUseDefault: () => widget.onUseDefault(slot.key),
            onDownload: () async {
              final option = _optionFor(slot.key, _selectedOptionIdFor(slot.key));
              if (option == null) return;
              await widget.onDownloadOption(slot.key, option);
            },
            onPickLocalFile: () => widget.onPickLocalFile(slot.key),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String? _selectedOptionIdFor(String prayerKey) {
    final options = adhanOptionsForPrayer(prayerKey);
    if (options.isEmpty) return null;
    return _selectedOptionIds[prayerKey] ?? options.first.id;
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
  final bool isDownloading;
  final ValueChanged<String?> onOptionChanged;
  final VoidCallback onUseDefault;
  final Future<void> Function() onDownload;
  final Future<void> Function() onPickLocalFile;

  const _AdhanPrayerCard({
    required this.slot,
    required this.selection,
    required this.selectedOptionId,
    required this.isDownloading,
    required this.onOptionChanged,
    required this.onUseDefault,
    required this.onDownload,
    required this.onPickLocalFile,
  });

  @override
  Widget build(BuildContext context) {
    final options = adhanOptionsForPrayer(slot.key);
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
                label: const Text('Varsayılan'),
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
              FilledButton.icon(
                onPressed: isDownloading ? null : onDownload,
                icon: isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(isDownloading ? 'İniyor' : 'İndir'),
              ),
            ],
          ),
        ],
      ),
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
