import 'shared_settings_models.dart';

const SharedSettingsAppConfig kSharedSettingsAppConfig = SharedSettingsAppConfig(
  appName: 'Let\'s Pray',
  appId: 'haydi_namaza',
  packageName: 'com.msklabs.haydi_namaza',
  adminName: 'HaydiNamazaAdmin',
  updateRemoteManifestUrl:
      'https://raw.githubusercontent.com/mskaymaz/M_HaydiNamaza/main/update.json',
  updateFallbackReleaseUrl:
      'https://github.com/mskaymaz/M_HaydiNamaza/releases',
  updateChannel: 'public',
  otherAppsRemoteCatalogUrl:
      'https://raw.githubusercontent.com/mskaymaz/AllApp/main/app_catalog.json',
  localCatalogAssetPath: 'assets/data/shared_settings/app_catalog.local.json',
  localUpdateAssetPath: 'assets/data/shared_settings/update_manifest.local.json',
  contact: SharedSettingsContactConfig(email: 'msklabs.org@gmail.com'),
  support: SharedSettingsSupportConfig(
    title: 'Destek Olabilirsiniz',
    body:
        'Uygulamayı faydalı bulduysanız paylaşarak ve geri bildirim vererek destek olabilirsiniz.',
    actionUrl: 'https://github.com/mskaymaz/M_HaydiNamaza',
    actionLabel: 'Projeyi Aç',
  ),
  about: SharedSettingsAboutConfig(
    title: 'Hakkımızda',
    summary: 'MSK Labs sade, güvenilir ve faydalı mobil ürünler üretir.',
    details:
        'Haydi Namaza uygulamasını gerçek kullanım geri bildirimleriyle adım adım iyileştiriyoruz.',
    imageAsset: 'img/M_BizKimiz.jpg',
    linkUrl: 'https://msklabsdevelopment.blogspot.com',
    linkLabel: 'Blogu Aç',
  ),
);
