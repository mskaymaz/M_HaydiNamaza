import 'package:flutter/material.dart';
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
      title: 'Diğer Uygulamalarımız',
      headerColor: sharedSettingsOtherAppsHeader,
      showHelpBalloons: widget.showHelpBalloons,
      helpMessage:
          'Bu bölümde yer alan uygulamalar ekibimizin yapmış olduğu, ücretsiz ve reklamsız diğer tüm uygulamalara erişimi sağlar. Bu yapı aracılığıyla diğer uygulamalarımızı da indirebilirsiniz.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
        child: FutureBuilder<List<OtherAppItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final items = snapshot.data ?? const <OtherAppItem>[];
            if (items.isEmpty) {
              return const SizedBox(
                height: 90,
                child: Center(
                  child: Text(
                    'Henüz listelenecek uygulama bulunmuyor.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return SizedBox(
              height: 250,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _OtherAppTile(
                    item: item,
                    onTap: () => _openUrl(
                      item.launchUrl,
                      failMessage: 'Bağlantı açılamadı.',
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openUrl(String rawUrl, {required String failMessage}) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      _showSnack(failMessage);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      _showSnack(failMessage);
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OtherAppTile extends StatelessWidget {
  final OtherAppItem item;
  final VoidCallback onTap;

  const _OtherAppTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AppIcon(item: item),
            const SizedBox(height: 8),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final OtherAppItem item;

  const _AppIcon({required this.item});

  @override
  Widget build(BuildContext context) {
    final asset = item.iconAsset.trim();
    if (asset.isNotEmpty) {
      return Image.asset(
        asset,
        width: 52,
        height: 52,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _NetworkIcon(item: item),
      );
    }

    return _NetworkIcon(item: item);
  }
}

class _NetworkIcon extends StatelessWidget {
  final OtherAppItem item;

  const _NetworkIcon({required this.item});

  @override
  Widget build(BuildContext context) {
    final iconUrl = item.iconUrl.trim();
    if (iconUrl.isEmpty) return _FallbackIcon(label: item.name);
    return Image.network(
      iconUrl,
      width: 52,
      height: 52,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _FallbackIcon(label: item.name),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final String label;

  const _FallbackIcon({required this.label});

  @override
  Widget build(BuildContext context) {
    final trimmedLabel = label.trim();
    final initial = trimmedLabel.isEmpty
        ? 'M'
        : String.fromCharCode(trimmedLabel.runes.first).toUpperCase();
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(14),
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

