import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import 'shared_settings_section_styles.dart';

class SettingsSharedAboutSection extends StatelessWidget {
  const SettingsSharedAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final about = kSharedSettingsAppConfig.about;
    return SharedSettingsSectionCard(
      title: about.title,
      headerColor: sharedSettingsAboutHeader,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (about.imageAsset.trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Image.asset(
                      about.imageAsset,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: const Alignment(0, 0.84),
                        child: FractionallySizedBox(
                          widthFactor: 0.90,
                          heightFactor: 0.05,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openBlog(context),
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Text(about.summary),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Text(about.details),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: OutlinedButton.icon(
                onPressed: () => _openBlog(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(about.linkLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openBlog(BuildContext context) async {
    final url = kSharedSettingsAppConfig.about.linkUrl;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnack(context, 'Baglanti acilamadi.');
      return;
    }

    final external = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (external) return;

    final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!fallback && context.mounted) {
      _showSnack(context, 'Baglanti acilamadi.');
    }
  }

  void _showSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
