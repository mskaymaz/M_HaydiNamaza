import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import '../../../../features/shared_settings/shared_settings_models.dart';
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
  bool _automaticUpdateChecksEnabled = true;

  static const String _lastUpdateCheckKey =
      'shared_settings_last_update_check_ms';
  static const String _automaticUpdateChecksEnabledKey =
      'shared_settings_automatic_update_checks_enabled';
  static const Duration _automaticUpdateCheckInterval = Duration(hours: 12);

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
    _loadAutomaticUpdatePreference();
  }

  @override
  Widget build(BuildContext context) {
    final config = kSharedSettingsAppConfig;
    return SharedSettingsSectionCard(
      title: 'Uygulama Bilgileri ve G\u00fcncelleme',
      showHelpBalloons: widget.showHelpBalloons,
      helpMessage:
          'Bu b\u00f6l\u00fcm mevcut s\u00fcr\u00fcm bilgisini g\u00f6sterir ve public da\u011f\u0131t\u0131m kayna\u011f\u0131ndan yeni s\u00fcr\u00fcm kontrol\u00fc yapar. G\u00fcncelleme varsa indirme ba\u011flant\u0131s\u0131n\u0131 a\u00e7ar.',
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
                _infoRow('S\u00fcr\u00fcm', versionText),
                _infoRow('Kanal', config.updateChannel),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _automaticUpdateChecksEnabled,
                  onChanged: (value) => _setAutomaticUpdateChecks(value),
                  title: const Text('G\u00fcncellemeleri otomatik kontrol et'),
                  subtitle: const Text(
                    'A\u00e7\u0131ksa, bu b\u00f6l\u00fcm a\u00e7\u0131ld\u0131\u011f\u0131nda internet \u00fczerinden yeni s\u00fcr\u00fcm bilgisi kontrol edilir.',
                  ),
                ),
                const SizedBox(height: 8),
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
                              ? 'G\u00fcncelleme var'
                              : 'G\u00fcncellemeleri Kontrol Et'),
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

  Future<void> _loadAutomaticUpdatePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_automaticUpdateChecksEnabledKey) ?? true;
    if (!mounted) return;
    setState(() => _automaticUpdateChecksEnabled = enabled);
    if (!enabled) return;
    final packageInfo = await _packageInfoFuture;
    if (!mounted) return;
    await _checkForUpdateIfDue(packageInfo);
  }

  Future<void> _setAutomaticUpdateChecks(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_automaticUpdateChecksEnabledKey, enabled);
    if (!mounted) return;
    setState(() => _automaticUpdateChecksEnabled = enabled);
    if (!enabled) {
      _showSnack('Otomatik g\u00fcncelleme kontrol\u00fc kapat\u0131ld\u0131.');
      return;
    }
    _showSnack('Otomatik g\u00fcncelleme kontrol\u00fc a\u00e7\u0131ld\u0131.');
    final packageInfo = await _packageInfoFuture;
    if (!mounted) return;
    await _checkForUpdate(packageInfo, automatic: true, ignoreInterval: true);
  }

  Future<void> _checkForUpdateIfDue(PackageInfo packageInfo) async {
    if (!_automaticUpdateChecksEnabled) return;
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
    bool ignoreInterval = false,
  }) async {
    if (automatic && !_automaticUpdateChecksEnabled) return;
    final localBuild = int.tryParse(packageInfo?.buildNumber ?? '') ?? 0;
    if (!mounted) return;
    setState(() => _checkingUpdate = true);

    final manifest = await _remoteClient.loadUpdateManifest(
      remoteUrl: kSharedSettingsAppConfig.updateRemoteManifestUrl,
      localAssetPath: kSharedSettingsAppConfig.localUpdateAssetPath,
    );

    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    final prefs = await SharedPreferences.getInstance();
    if (!automatic || !ignoreInterval) {
      await prefs.setInt(
        _lastUpdateCheckKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

    if (manifest == null) {
      if (!automatic) _showSnack('G\u00fcncelleme bilgisi al\u0131namad\u0131.');
      return;
    }

    if (manifest.buildNumber <= localBuild) {
      setState(() {
        _updateAvailable = false;
      });
      if (!automatic) _showSnack('Yeni s\u00fcr\u00fcm bulunamad\u0131.');
      return;
    }

    setState(() {
      _updateAvailable = true;
    });

    if (automatic) {
      _showUpdateAvailableSnack(manifest);
      return;
    }
    if (!mounted) return;

    final open = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni S\u00fcr\u00fcm Haz\u0131r'),
          content: Text(
            'Yeni s\u00fcr\u00fcm: ${manifest.version} (${manifest.buildNumber})\n\n${manifest.notes.isEmpty ? 'G\u00fcncelleme mevcut.' : manifest.notes}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Daha Sonra'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('G\u00fcncelle'),
            ),
          ],
        );
      },
    );

    if (open != true) return;

    await _openUpdateLink(manifest);
  }

  Future<void> _openUpdateLink(UpdateManifest manifest) async {
    final link = manifest.url.trim().isNotEmpty
        ? manifest.url
        : kSharedSettingsAppConfig.updateFallbackReleaseUrl;
    await _openUrl(link, failMessage: 'G\u00fcncelleme ba\u011flant\u0131s\u0131 a\u00e7\u0131lamad\u0131.');
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

  void _showUpdateAvailableSnack(UpdateManifest manifest) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
        content: Text(
          'Yeni s\u00fcr\u00fcm haz\u0131r: ${manifest.version} (${manifest.buildNumber})',
        ),
        action: SnackBarAction(
          label: 'G\u00fcncelle',
          onPressed: () => _openUpdateLink(manifest),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }
}
