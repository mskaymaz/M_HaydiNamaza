import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import '../../../../features/shared_settings/shared_settings_remote_client.dart';
import 'shared_settings_section_styles.dart';

class SettingsSharedUpdateSection extends StatefulWidget {
  const SettingsSharedUpdateSection({super.key});

  @override
  State<SettingsSharedUpdateSection> createState() =>
      _SettingsSharedUpdateSectionState();
}

class _SettingsSharedUpdateSectionState
    extends State<SettingsSharedUpdateSection> {
  final SharedSettingsRemoteClient _remoteClient =
      const SharedSettingsRemoteClient();
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
    return SharedSettingsSectionCard(
      title: 'Uygulama Bilgileri ve Guncelleme',
      headerColor: sharedSettingsUpdateHeader,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
        child: FutureBuilder<PackageInfo>(
          future: _packageInfoFuture,
          builder: (context, snapshot) {
            final package = snapshot.data;
            final versionText = package == null
                ? 'Bilinmiyor'
                : '${package.version} (${package.buildNumber})';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Teknik Bilgiler',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                _infoRow('Uygulama', config.appName),
                _infoRow('App ID', config.appId),
                _infoRow('Package', config.packageName),
                _infoRow('Surum', versionText),
                _infoRow('Kanal', config.updateChannel),
                const SizedBox(height: 12),
                FractionallySizedBox(
                  widthFactor: 0.7,
                  child: FilledButton.icon(
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
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

    if (open != true) return;

    final link = manifest.url.trim().isNotEmpty
        ? manifest.url
        : kSharedSettingsAppConfig.updateFallbackReleaseUrl;
    await _openUrl(link, failMessage: 'Guncelleme baglantisi acilamadi.');
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
