import 'package:flutter/material.dart';

import '../../../app/adhan_catalog.dart';

class SettingsAdhanSelectionSection extends StatefulWidget {
  final Map<String, AdhanSelection> selections;
  final Map<String, String> downloadedAdhanPaths;
  final Set<String> downloadingPrayerKeys;
  final String? activePreviewKey;
  final ValueChanged<String> onUseDefault;
  final Future<void> Function(String prayerKey, AdhanCatalogOption option)
      onDownloadOption;
  final Future<void> Function(String prayerKey, AdhanCatalogOption option)
      onSelectDownloaded;
  final Future<void> Function(String prayerKey) onPickLocalFile;
  final Future<void> Function() onPreviewDefault;
  final Future<void> Function(AdhanCatalogOption option) onPreviewDownloaded;
  final Future<void> Function(String prayerKey) onPreviewLocalFile;
  final Future<void> Function() onStopPreview;
  final Future<void> Function(AdhanCatalogOption option) onDeleteDownloaded;
  final Future<void> Function(String prayerKey) onClearLocalFile;

  const SettingsAdhanSelectionSection({
    super.key,
    required this.selections,
    required this.downloadedAdhanPaths,
    required this.downloadingPrayerKeys,
    required this.activePreviewKey,
    required this.onUseDefault,
    required this.onDownloadOption,
    required this.onSelectDownloaded,
    required this.onPickLocalFile,
    required this.onPreviewDefault,
    required this.onPreviewDownloaded,
    required this.onPreviewLocalFile,
    required this.onStopPreview,
    required this.onDeleteDownloaded,
    required this.onClearLocalFile,
  });

  @override
  State<SettingsAdhanSelectionSection> createState() =>
      _SettingsAdhanSelectionSectionState();
}

class _SettingsAdhanSelectionSectionState
    extends State<SettingsAdhanSelectionSection> {
  String _selectedPrayerKey = kMainAdhanPrayerSlots.first.key;

  @override
  Widget build(BuildContext context) {
    final slot = _selectedSlot;
    final selection = adhanSelectionForPrayer(
      widget.selections,
      slot.key,
    );
    final isDownloading = widget.downloadingPrayerKeys.contains(slot.key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Önce vakti seçin, sonra kütüphaneden ezanı indirin, dinleyin veya seçin.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: slot.key,
          decoration: const InputDecoration(
            labelText: 'Vakit seç',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: kMainAdhanPrayerSlots
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.key,
                  child: Text(item.label),
                ),
              )
              .toList(growable: false),
          onChanged: isDownloading
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() => _selectedPrayerKey = value);
                },
        ),
        const SizedBox(height: 10),
        _SelectionSummary(slot: slot, selection: selection),
        const SizedBox(height: 10),
        _DefaultAdhanTile(
          isSelected: selection.source == AdhanSelectionSource.bundled,
          isPreviewing: widget.activePreviewKey == _defaultPreviewKey,
          onPreview: widget.onPreviewDefault,
          onStopPreview: widget.onStopPreview,
          onSelect: () => widget.onUseDefault(slot.key),
        ),
        const SizedBox(height: 8),
        _LocalAdhanTile(
          selection: selection,
          isBusy: isDownloading,
          onPick: () => widget.onPickLocalFile(slot.key),
          isPreviewing: widget.activePreviewKey == _localPreviewKey(slot.key),
          onPreview: () => widget.onPreviewLocalFile(slot.key),
          onStopPreview: widget.onStopPreview,
          onClear: () => widget.onClearLocalFile(slot.key),
        ),
        const SizedBox(height: 12),
        Text(
          'Ezan kütüphanesi',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        for (final option in kDownloadableAdhanOptions) ...[
          _DownloadableAdhanTile(
            option: option,
            isBusy: isDownloading,
            isDownloaded: _isDownloaded(option),
            isSelected: _isSelected(selection, option),
            isPreviewing: widget.activePreviewKey == _downloadedPreviewKey(option.id),
            onDownload: () => widget.onDownloadOption(slot.key, option),
            onSelect: () => widget.onSelectDownloaded(slot.key, option),
            onPreview: () => widget.onPreviewDownloaded(option),
            onStopPreview: widget.onStopPreview,
            onDelete: () => widget.onDeleteDownloaded(option),
          ),
          const SizedBox(height: 3),
        ],
      ],
    );
  }

  AdhanPrayerSlot get _selectedSlot {
    return kMainAdhanPrayerSlots.firstWhere(
      (slot) => slot.key == _selectedPrayerKey,
      orElse: () => kMainAdhanPrayerSlots.first,
    );
  }

  String get _defaultPreviewKey => 'bundled';

  String _downloadedPreviewKey(String optionId) => 'downloaded:$optionId';

  String _localPreviewKey(String prayerKey) => 'local:$prayerKey';

  bool _isDownloaded(AdhanCatalogOption option) {
    return widget.downloadedAdhanPaths[option.id]?.trim().isNotEmpty ?? false;
  }

  bool _isSelected(AdhanSelection selection, AdhanCatalogOption option) {
    return selection.source == AdhanSelectionSource.downloadable &&
        selection.optionId == option.id;
  }
}

class _SelectionSummary extends StatelessWidget {
  final AdhanPrayerSlot slot;
  final AdhanSelection selection;

  const _SelectionSummary({required this.slot, required this.selection});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F3E6).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F7A3E).withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slot.label} için seçili ezan',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            selection.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 1),
          Text(
            _sourceLabel(selection.source),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _sourceLabel(AdhanSelectionSource source) {
    switch (source) {
      case AdhanSelectionSource.bundled:
        return 'Kaynak: Dahili varsayılan ezan';
      case AdhanSelectionSource.downloadable:
        return 'Kaynak: İndirilen ezan';
      case AdhanSelectionSource.localFile:
        return 'Kaynak: Yerel dosya';
    }
  }
}

class _DefaultAdhanTile extends StatelessWidget {
  final bool isSelected;
  final bool isPreviewing;
  final Future<void> Function() onPreview;
  final Future<void> Function() onStopPreview;
  final VoidCallback onSelect;

  const _DefaultAdhanTile({
    required this.isSelected,
    required this.isPreviewing,
    required this.onPreview,
    required this.onStopPreview,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _AdhanTileFrame(
      title: 'Varsayılan ezan',
      subtitle: 'Uygulama içinde bulunan dahili ezan.',
      children: [
        _PreviewActionButton(
          isPreviewing: isPreviewing,
          onPreview: onPreview,
          onStopPreview: onStopPreview,
        ),
        _SelectButton(isSelected: isSelected, onPressed: onSelect),
      ],
    );
  }
}

class _LocalAdhanTile extends StatelessWidget {
  final AdhanSelection selection;
  final bool isBusy;
  final bool isPreviewing;
  final Future<void> Function() onPick;
  final Future<void> Function() onPreview;
  final Future<void> Function() onStopPreview;
  final Future<void> Function() onClear;

  const _LocalAdhanTile({
    required this.selection,
    required this.isBusy,
    required this.isPreviewing,
    required this.onPick,
    required this.onPreview,
    required this.onStopPreview,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selection.source == AdhanSelectionSource.localFile;
    return _AdhanTileFrame(
      title: 'Yerel ezan dosyası',
      subtitle: isSelected ? selection.label : 'Telefondan ses dosyası seç.',
      titleActions: [
        _SmallActionButton(
          icon: Icons.audio_file_rounded,
          label: isSelected ? 'Değiştir' : 'Dosya Seç',
          onPressed: isBusy ? null : onPick,
        ),
      ],
      children: [
        if (isSelected)
          _PreviewActionButton(
            isPreviewing: isPreviewing,
            onPreview: onPreview,
            onStopPreview: onStopPreview,
          ),
        if (isSelected)
          _SmallActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Temizle',
            onPressed: onClear,
          ),
      ],
    );
  }
}

class _DownloadableAdhanTile extends StatelessWidget {
  final AdhanCatalogOption option;
  final bool isBusy;
  final bool isDownloaded;
  final bool isSelected;
  final bool isPreviewing;
  final Future<void> Function() onDownload;
  final Future<void> Function() onSelect;
  final Future<void> Function() onPreview;
  final Future<void> Function() onStopPreview;
  final Future<void> Function() onDelete;

  const _DownloadableAdhanTile({
    required this.option,
    required this.isBusy,
    required this.isDownloaded,
    required this.isSelected,
    required this.isPreviewing,
    required this.onDownload,
    required this.onSelect,
    required this.onPreview,
    required this.onStopPreview,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _AdhanTileFrame(
      title: option.label,
      subtitle: isDownloaded ? 'Telefona indirildi' : 'İndirilmedi',
      compact: true,
      inlineSubtitle: true,
      children: [
        if (isDownloaded)
          _PreviewActionButton(
            isPreviewing: isPreviewing,
            onPreview: onPreview,
            onStopPreview: onStopPreview,
          ),
        if (isDownloaded)
          _SelectButton(isSelected: isSelected, onPressed: onSelect)
        else
          _SmallActionButton(
            icon: isBusy ? Icons.hourglass_top_rounded : Icons.download_rounded,
            label: isBusy ? 'İniyor' : 'İndir',
            onPressed: isBusy ? null : onDownload,
          ),
        if (isDownloaded)
          _SmallActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Sil',
            onPressed: isBusy ? null : onDelete,
          ),
      ],
    );
  }
}

class _AdhanTileFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final List<Widget> titleActions;
  final bool compact;
  final bool inlineSubtitle;

  const _AdhanTileFrame({
    required this.title,
    required this.subtitle,
    required this.children,
    this.titleActions = const [],
    this.compact = false,
    this.inlineSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = compact
        ? textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)
        : const TextStyle(fontWeight: FontWeight.w800);
    final subtitleStyle = textTheme.bodySmall;
    final verticalPadding = compact ? 2.0 : 6.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: compact ? 0.44 : 0.52),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (inlineSubtitle) ...[
                Text(title, style: titleStyle),
                const SizedBox(width: 20),
                Flexible(child: Text(subtitle, style: subtitleStyle)),
              ] else
                Expanded(child: Text(title, style: titleStyle)),
              if (titleActions.isNotEmpty) ...[
                const SizedBox(width: 8),
                ...titleActions,
              ],
            ],
          ),
          if (!inlineSubtitle) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: subtitleStyle),
          ],
          if (children.isNotEmpty) ...[
            SizedBox(height: compact ? 3 : 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 5,
                runSpacing: 3,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewActionButton extends StatelessWidget {
  final bool isPreviewing;
  final Future<void> Function() onPreview;
  final Future<void> Function() onStopPreview;

  const _PreviewActionButton({
    required this.isPreviewing,
    required this.onPreview,
    required this.onStopPreview,
  });

  @override
  Widget build(BuildContext context) {
    return _SmallActionButton(
      icon: isPreviewing ? Icons.stop_rounded : Icons.play_arrow_rounded,
      label: isPreviewing ? 'Durdur' : 'Dinle',
      onPressed: isPreviewing ? onStopPreview : onPreview,
    );
  }
}

class _SelectButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onPressed;

  const _SelectButton({required this.isSelected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _SmallActionButton(
      icon: isSelected ? Icons.check_circle_rounded : Icons.check_rounded,
      label: isSelected ? 'Seçili' : 'Seç',
      onPressed: isSelected ? null : onPressed,
      filled: true,
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    if (filled) {
      return FilledButton(onPressed: onPressed, style: style, child: child);
    }
    return OutlinedButton(onPressed: onPressed, style: style, child: child);
  }
}
