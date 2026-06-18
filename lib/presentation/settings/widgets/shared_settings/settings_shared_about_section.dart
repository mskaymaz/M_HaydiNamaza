import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import 'shared_settings_section_styles.dart';

class SettingsSharedAboutSection extends StatelessWidget {
  final bool showHelpBalloons;

  const SettingsSharedAboutSection({
    super.key,
    required this.showHelpBalloons,
  });

  @override
  Widget build(BuildContext context) {
    final config = kSharedSettingsAppConfig;
    final about = config.about;
    final contactEmail = config.contact.email;

    return SharedSettingsSectionCard(
      title: about.title,
      showHelpBalloons: showHelpBalloons,
      helpMessage:
          'Bu bölüm uygulama hakkında kısa bilgi, proje bağlantısı ve iletişim adresini gösterir. Blog bağlantısını açabilir veya e-posta adresini kopyalayabilirsiniz.',
      headerColor: sharedSettingsAboutHeader,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (about.imageAsset.trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  about.imageAsset,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
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
            const SizedBox(height: 14),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 180),
                child: FilledButton.icon(
                  onPressed: () => _openBlog(context),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(about.linkLabel),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bize ulaşın',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Bilgi verme, talep ve geri bildirimleriniz için iletişim adresimiz:',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              contactEmail,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'E-posta adresini kopyala',
                            onPressed: () => _copyEmail(context, contactEmail),
                            icon: const Icon(Icons.copy_rounded, size: 19),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
      _showSnack(context, 'Bağlantı açılamadı.');
      return;
    }

    final external = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (external) return;

    final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!fallback && context.mounted) {
      _showSnack(context, 'Bağlantı açılamadı.');
    }
  }

  Future<void> _copyEmail(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (context.mounted) {
      _showSnack(context, 'E-posta adresi kopyalandı.');
    }
  }

  void _showSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
