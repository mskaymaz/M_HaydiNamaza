import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import '../../../../features/shared_settings/shared_settings_remote_client.dart';
import 'shared_settings_section_styles.dart';

class SettingsSharedUpdateSection extends StatefulWidget {
  final bool showHelpBalloons;

  const SettingsSharedUpdateSection({
    super.key,
    required this.showHelpBalloons,
  });

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
  bool _updateAvailable = false;

  static const String _lastUpdateCheckKey =
      'shared_settings_last_update_check_ms';
  static const Duration _automaticUpdateCheckInterval = Duration(days: 10);

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
    _packageInfoFuture.then(_checkForUpdateIfDue);
  }

  @override
  Widget build(BuildContext context) {
    final config = kSharedSettingsAppConfig;
    return SharedSettingsSectionCard(
      title: 'Uygulama Bilgileri ve Güncelleme',
      showHelpBalloons: widget.showHelpBalloons,
      helpMessage:
          'Bu bölüm mevcut sürüm bilgisini gösterir ve public dağıtım kaynağından yeni sürüm kontrolü yapar. Güncelleme varsa indirme bağlantısını açar.',
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
                _infoRow('Sürüm', versionText),
                _infoRow('Kanal', config.updateChannel),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _checkingUpdate
                        ? null
                        : () => _checkForUpdate(package, automatic: false),
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
                          : (_updateAvailable
                              ? 'Güncelleme var'
                              : 'Güncellemeleri Kontrol Et'),
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

  Future<void> _checkForUpdateIfDue(PackageInfo packageInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastUpdateCheckKey);
    final now = DateTime.now();
    final due = lastMs == null ||
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastMs)) >=
            _automaticUpdateCheckInterval;
    if (!due) return;
    await _checkForUpdate(packageInfo, automatic: true);
  }

  Future<void> _checkForUpdate(
    PackageInfo? packageInfo, {
    required bool automatic,
  }) async {
    final localBuild = int.tryParse(packageInfo?.buildNumber ?? '') ?? 0;
    setState(() => _checkingUpdate = true);

    final manifest = await _remoteClient.loadUpdateManifest(
      remoteUrl: kSharedSettingsAppConfig.updateRemoteManifestUrl,
      localAssetPath: kSharedSettingsAppConfig.localUpdateAssetPath,
    );

    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastUpdateCheckKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    if (manifest == null) {
      if (!automatic) _showSnack('Güncelleme bilgisi alınamadı.');
      return;
    }

    if (manifest.buildNumber <= localBuild) {
      setState(() {
        _updateAvailable = false;
      });
      if (!automatic) _showSnack('Yeni sürüm bulunamadı.');
      return;
    }

    setState(() {
      _updateAvailable = true;
    });

    if (automatic) return;
    if (!mounted) return;

    final open = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Sürüm Hazır'),
          content: Text(
            'Yeni sürüm: ${manifest.version} (${manifest.buildNumber})\n\n${manifest.notes.isEmpty ? 'Güncelleme mevcut.' : manifest.notes}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Daha Sonra'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );

    if (open != true) return;

    final link = manifest.url.trim().isNotEmpty
        ? manifest.url
        : kSharedSettingsAppConfig.updateFallbackReleaseUrl;
    await _openUrl(link, failMessage: 'Güncelleme bağlantısı açılamadı.');
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
