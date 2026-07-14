import 'shared_settings_models.dart';

const SharedSettingsAppConfig
kSharedSettingsAppConfig = SharedSettingsAppConfig(
  appName: 'Haydi Namaza',
  appId: 'haydi_namaza',
  packageName: 'com.mskaymaz.mhaydinamaza',
  adminName: 'HaydiNamazaAdmin',
  updateRemoteManifestUrl:
      'https://raw.githubusercontent.com/mskaymaz/AllApp/main/update_manifest.json',
  updateFallbackReleaseUrl:
      'https://raw.githubusercontent.com/mskaymaz/AllApp/main/releases/HaydiNamaza.apk',
  updateChannel: 'public',
  otherAppsRemoteCatalogUrl:
      'https://raw.githubusercontent.com/mskaymaz/AllApp/main/app_catalog.json',
  localCatalogAssetPath: 'assets/data/shared_settings/app_catalog.local.json',
  localUpdateAssetPath:
      'assets/data/shared_settings/update_manifest.local.json',
  contact: SharedSettingsContactConfig(email: 'msklabs.org@gmail.com'),
  support: SharedSettingsSupportConfig(
    title: 'Destek Olabilirsiniz',
    body:
        'Öncelikle Direniş için,\ntüm Dünya Müslümanları için\nve bizim için dua edin.\n\nAllah (cc) hepimizden razı olsun.',
    actionUrl: 'https://github.com/mskaymaz/AllApp/tree/main/HaydiNamaza',
    actionLabel: 'Dua Ediyorum',
    actionType: 'prayer',
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
