import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import '../../../../features/shared_settings/shared_settings_models.dart';
import '../../../../features/shared_settings/shared_settings_remote_client.dart';
import 'shared_settings_section_styles.dart';

class SettingsSharedOtherAppsSection extends StatelessWidget {
  final SharedSettingsRemoteClient remoteClient;

  const SettingsSharedOtherAppsSection({
    super.key,
    required this.remoteClient,
  });

  @override
  Widget build(BuildContext context) {
    return SharedSettingsSectionCard(
      title: 'Diger Uygulamalarimiz',
      headerColor: sharedSettingsOtherAppsHeader,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 15, 25, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            FractionallySizedBox(
              widthFactor: 0.7,
              child: OutlinedButton.icon(
                onPressed: () => _showOtherAppsDialog(context),
                icon: const Icon(Icons.apps_rounded),
                label: const Text('Listeyi Gor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOtherAppsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Diger Uygulamalarimiz'),
          content: SizedBox(
            width: 420,
            child: FutureBuilder<List<OtherAppItem>>(
              future: remoteClient.loadOtherApps(
                remoteUrl: kSharedSettingsAppConfig.otherAppsRemoteCatalogUrl,
                localAssetPath: kSharedSettingsAppConfig.localCatalogAssetPath,
                currentAppId: kSharedSettingsAppConfig.appId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final items = snapshot.data ?? const <OtherAppItem>[];
                if (items.isEmpty) {
                  return const Text(
                    'Henuz listelenecek uygulama bulunmuyor.',
                    textAlign: TextAlign.center,
                  );
                }

                return SizedBox(
                  height: 320,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        subtitle: item.description.isEmpty
                            ? null
                            : Text(item.description),
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                        ),
                        onTap: () => _openUrl(
                          context,
                          item.url,
                          failMessage: 'Baglanti acilamadi.',
                        ),
                      );
                    },
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

  Future<void> _openUrl(
    BuildContext context,
    String rawUrl, {
    required String failMessage,
  }) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      _showSnack(context, failMessage);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      _showSnack(context, failMessage);
    }
  }

  void _showSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
