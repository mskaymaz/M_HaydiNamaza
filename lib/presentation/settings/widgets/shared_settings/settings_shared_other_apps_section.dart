import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import '../../../../features/shared_settings/shared_settings_models.dart';
import '../../../../features/shared_settings/shared_settings_remote_client.dart';
import 'shared_settings_section_styles.dart';

class SettingsSharedOtherAppsSection extends StatefulWidget {
  final SharedSettingsRemoteClient remoteClient;
  final bool showHelpBalloons;

  const SettingsSharedOtherAppsSection({
    super.key,
    required this.remoteClient,
    this.showHelpBalloons = false,
  });

  @override
  State<SettingsSharedOtherAppsSection> createState() =>
      _SettingsSharedOtherAppsSectionState();
}

class _SettingsSharedOtherAppsSectionState
    extends State<SettingsSharedOtherAppsSection> {
  late final Future<List<OtherAppItem>> _future;
  String? _expandedAppId;

  @override
  void initState() {
    super.initState();
    _future = widget.remoteClient.loadOtherApps(
      remoteUrl: kSharedSettingsAppConfig.otherAppsRemoteCatalogUrl,
      localAssetPath: kSharedSettingsAppConfig.localCatalogAssetPath,
      currentAppId: kSharedSettingsAppConfig.appId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SharedSettingsSectionCard(
      title: 'Uygulamalar\u0131m\u0131z',
      headerColor: sharedSettingsOtherAppsHeader,
      showHelpBalloons: widget.showHelpBalloons,
      helpMessage:
          'MSK Labs taraf\u0131ndan yay\u0131nlanan di\u011fer uygulamalar\u0131 buradan g\u00f6rebilir, indirme ba\u011flant\u0131lar\u0131n\u0131 a\u00e7abilir veya kopyalayabilirsiniz.',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<List<OtherAppItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final items = snapshot.data ?? const <OtherAppItem>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in _platformGroups) ...[
                  _OtherAppsPlatformGroup(
                    title: group.title,
                    icon: group.icon,
                    items: items
                        .where((item) => item.platform == group.key)
                        .toList(growable: false),
                    expandedAppId: _expandedAppId,
                    onSelected: _toggleExpandedItem,
                    onOpen: _openUrl,
                    onCopy: _copyUrl,
                  ),
                  if (group != _platformGroups.last)
                    const SizedBox(height: 16),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _toggleExpandedItem(OtherAppItem item) {
    setState(() {
      _expandedAppId = _expandedAppId == item.appId ? null : item.appId;
    });
  }

  Future<void> _openUrl(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyUrl(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link kopyaland\u0131.')),
    );
  }
}

const List<_PlatformGroup> _platformGroups = [
  _PlatformGroup('mobile', 'Mobile', Icons.phone_android_rounded),
  _PlatformGroup('desktop', 'Desktop', Icons.desktop_windows_rounded),
  _PlatformGroup('web', 'Web', Icons.public_rounded),
];

class _PlatformGroup {
  final String key;
  final String title;
  final IconData icon;

  const _PlatformGroup(this.key, this.title, this.icon);
}

class _OtherAppsPlatformGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<OtherAppItem> items;
  final String? expandedAppId;
  final ValueChanged<OtherAppItem> onSelected;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onCopy;

  const _OtherAppsPlatformGroup({
    required this.title,
    required this.icon,
    required this.items,
    required this.expandedAppId,
    required this.onSelected,
    required this.onOpen,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    OtherAppItem? expandedItem;
    for (final item in items) {
      if (item.appId == expandedAppId) {
        expandedItem = item;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 9),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Hen\u00fcz uygulama bulunmuyor.'),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 24) / 3;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in items)
                    _OtherAppIconButton(
                      item: item,
                      width: itemWidth,
                      selected: item.appId == expandedAppId,
                      onTap: () => onSelected(item),
                    ),
                ],
              );
            },
          ),
        if (expandedItem != null) ...[
          const SizedBox(height: 10),
          _OtherAppDownloadCard(
            item: expandedItem,
            onOpen: () => onOpen(expandedItem!.launchUrl),
            onCopy: () => onCopy(expandedItem!.launchUrl),
          ),
        ],
      ],
    );
  }
}

class _OtherAppIconButton extends StatelessWidget {
  final OtherAppItem item;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  const _OtherAppIconButton({
    required this.item,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFFFF3CD)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFFE0A800) : Colors.black12,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AppIcon(item: item, size: 64),
              const SizedBox(height: 7),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtherAppDownloadCard extends StatelessWidget {
  final OtherAppItem item;
  final VoidCallback onOpen;
  final VoidCallback onCopy;

  const _OtherAppDownloadCard({
    required this.item,
    required this.onOpen,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AppIcon(item: item, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('\u0130ndir'),
                  onPressed: onOpen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Linki Kopyala'),
                  onPressed: onCopy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            item.launchUrl,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final OtherAppItem item;
  final double size;

  const _AppIcon({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final asset = item.iconAsset.trim();
    if (asset.isNotEmpty) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _FallbackIcon(label: item.name, size: size),
      );
    }

    return _NetworkIcon(item: item, size: size);
  }
}

class _NetworkIcon extends StatelessWidget {
  final OtherAppItem item;
  final double size;

  const _NetworkIcon({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final iconUrl = item.iconUrl.trim();
    if (iconUrl.isEmpty) {
      return _FallbackIcon(label: item.name, size: size);
    }
    return Image.network(
      iconUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _FallbackIcon(label: item.name, size: size),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final String label;
  final double size;

  const _FallbackIcon({required this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    final trimmedLabel = label.trim();
    final initial = trimmedLabel.isEmpty
        ? 'M'
        : String.fromCharCode(trimmedLabel.runes.first).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(size * 0.27),
        border: Border.all(color: const Color(0xFFE0A800)),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: const Color(0xFF7A4F00),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
