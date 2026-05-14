import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/config_registry.dart';
import '../../../features/shared_settings/shared_settings_app_config.dart';
import '../../../features/shared_settings/shared_settings_models.dart';
import '../../../features/shared_settings/shared_settings_remote_client.dart';
import 'settings_section_panel.dart';

class SettingsSharedModulesGroup extends StatefulWidget {
  final EdgeInsets outerPadding;
  final SurfaceStyle panelStyle;

  const SettingsSharedModulesGroup({
    super.key,
    required this.outerPadding,
    required this.panelStyle,
  });

  @override
  State<SettingsSharedModulesGroup> createState() =>
      _SettingsSharedModulesGroupState();
}

class _SettingsSharedModulesGroupState extends State<SettingsSharedModulesGroup> {
  final SharedSettingsRemoteClient _remoteClient = const SharedSettingsRemoteClient();
  late final Future<PackageInfo> _packageInfoFuture;
  bool _checkingUpdate = false;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    final config = kSharedSettingsAppConfig;
    return Padding(
      padding: widget.outerPadding.copyWith(top: 0),
      child: Column(
        children: [
          _buildSection(
            title: 'Bize Ulasin',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Yonetim: ${config.adminName}'),
                const SizedBox(height: 6),
                Text('E-posta: ${config.contact.email}'),
                const SizedBox(height: 8),
                Text(config.contact.responsePolicyText),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(
                        _mailtoUrl(config),
                        failMessage: 'E-posta uygulamasi acilamadi.',
                      ),
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('E-posta Gonder'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(
                        config.contact.supportFormUrl,
                        failMessage: 'Destek formu acilamadi.',
                      ),
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Destek Formu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildSection(
            title: 'Uygulama Bilgileri ve Guncelleme',
            child: FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                final package = snapshot.data;
                final versionText = package == null
                    ? 'Bilinmiyor'
                    : '${package.version} (${package.buildNumber})';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Uygulama: ${config.appName}'),
                    const SizedBox(height: 4),
                    Text('App ID: ${config.appId}'),
                    const SizedBox(height: 4),
                    Text('Package: ${config.packageName}'),
                    const SizedBox(height: 4),
                    Text('Surum: $versionText'),
                    const SizedBox(height: 4),
                    Text('Kanal: ${config.updateChannel}'),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _checkingUpdate
                          ? null
                          : () => _checkForUpdate(package),
                      icon: _checkingUpdate
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.system_update_alt_rounded),
                      label: Text(
                        _checkingUpdate
                            ? 'Kontrol Ediliyor...'
                            : 'Guncellemeleri Kontrol Et',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          _buildSection(
            title: 'Diger Uygulamalarimiz',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MSK Labs uygulama listesini acabilirsiniz.'),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _showOtherAppsDialog,
                  icon: const Icon(Icons.apps_rounded),
                  label: const Text('Listeyi Gor'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildSection(
            title: 'Destek Olabilirsiniz',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.support.body),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _openUrl(
                    config.support.actionUrl,
                    failMessage: 'Destek baglantisi acilamadi.',
                  ),
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label: Text(config.support.actionLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildSection(
            title: 'Biz Kimiz',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.about.imageAsset.trim().isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      config.about.imageAsset,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(config.about.summary),
                const SizedBox(height: 8),
                Text(config.about.details),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _openUrl(
                    config.about.linkUrl,
                    failMessage: 'Baglanti acilamadi.',
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(config.about.linkLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return SettingsSectionPanel(
      style: widget.panelStyle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  String _mailtoUrl(SharedSettingsAppConfig config) {
    final subject = Uri.encodeComponent(
      '${config.appName} - ${config.contact.supportFormTopic}',
    );
    return 'mailto:${config.contact.email}?subject=$subject';
  }

  Future<void> _checkForUpdate(PackageInfo? packageInfo) async {
    final localBuild = int.tryParse(packageInfo?.buildNumber ?? '') ?? 0;
    setState(() => _checkingUpdate = true);

    final manifest = await _remoteClient.loadUpdateManifest(
      remoteUrl: kSharedSettingsAppConfig.updateRemoteManifestUrl,
      localAssetPath: kSharedSettingsAppConfig.localUpdateAssetPath,
    );

    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    if (manifest == null) {
      _showSnack('Guncelleme bilgisi alinamadi.');
      return;
    }

    if (manifest.buildNumber <= localBuild) {
      _showSnack('Yeni surum bulunamadi.');
      return;
    }

    final open = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Surum Hazir'),
          content: Text(
            'Yeni surum: ${manifest.version} (${manifest.buildNumber})\n\n${manifest.notes.isEmpty ? 'Guncelleme mevcut.' : manifest.notes}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Daha Sonra'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guncelle'),
            ),
          ],
        );
      },
    );

    if (open == true) {
      await _openUrl(manifest.url, failMessage: 'Guncelleme baglantisi acilamadi.');
    }
  }

  Future<void> _showOtherAppsDialog() async {
    final items = await _remoteClient.loadOtherApps(
      remoteUrl: kSharedSettingsAppConfig.otherAppsRemoteCatalogUrl,
      localAssetPath: kSharedSettingsAppConfig.localCatalogAssetPath,
      currentAppId: kSharedSettingsAppConfig.appId,
    );

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Diger Uygulamalarimiz'),
          content: SizedBox(
            width: 420,
            child: items.isEmpty
                ? const Text('Listelenecek uygulama bulunamadi.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        subtitle: item.description.isEmpty
                            ? null
                            : Text(item.description),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                        onTap: () => _openUrl(
                          item.url,
                          failMessage: 'Baglanti acilamadi.',
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUrl(String rawUrl, {required String failMessage}) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      _showSnack(failMessage);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      _showSnack(failMessage);
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
