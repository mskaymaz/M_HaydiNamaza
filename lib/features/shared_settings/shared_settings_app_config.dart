import 'shared_settings_models.dart';

const SharedSettingsAppConfig kSharedSettingsAppConfig = SharedSettingsAppConfig(
  appName: 'Haydi Namaza',
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
  contact: SharedSettingsContactConfig(
    email: 'msklabs.org@gmail.com',
    supportFormUrl: 'https://github.com/mskaymaz/M_HaydiNamaza/issues',
    supportFormTopic: 'Geri bildirim',
    supportFormMessage: 'Mesajinizi detayli yazabilirsiniz.',
    responsePolicyText: 'Mesajlar sirayla degerlendirilir.',
  ),
  support: SharedSettingsSupportConfig(
    title: 'Destek Olabilirsiniz',
    body:
        'Uygulamayi faydali bulduysaniz paylasarak ve geri bildirim vererek destek olabilirsiniz.',
    actionUrl: 'https://github.com/mskaymaz/M_HaydiNamaza',
    actionLabel: 'Projeyi Ac',
  ),
  about: SharedSettingsAboutConfig(
    title: 'Biz Kimiz',
    summary: 'MSK Labs sade, guvenilir ve faydali mobil urunler uretir.',
    details:
        'Haydi Namaza uygulamasini gercek kullanim geri bildirimleriyle adim adim iyilestiriyoruz.',
    imageAsset: 'img/M_BizKimiz.jpg',
    linkUrl: 'https://msklabsdevelopment.blogspot.com',
    linkLabel: 'Blogu Ac',
  ),
);
