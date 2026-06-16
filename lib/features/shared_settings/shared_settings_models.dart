class SharedSettingsContactConfig {
  final String email;

  const SharedSettingsContactConfig({required this.email});
}

class SharedSettingsSupportConfig {
  final String title;
  final String body;
  final String actionUrl;
  final String actionLabel;

  const SharedSettingsSupportConfig({
    required this.title,
    required this.body,
    required this.actionUrl,
    required this.actionLabel,
  });
}

class SharedSettingsAboutConfig {
  final String title;
  final String summary;
  final String details;
  final String imageAsset;
  final String linkUrl;
  final String linkLabel;

  const SharedSettingsAboutConfig({
    required this.title,
    required this.summary,
    required this.details,
    required this.imageAsset,
    required this.linkUrl,
    required this.linkLabel,
  });
}

class SharedSettingsAppConfig {
  final String appName;
  final String appId;
  final String packageName;
  final String adminName;
  final String updateRemoteManifestUrl;
  final String updateFallbackReleaseUrl;
  final String updateChannel;
  final String otherAppsRemoteCatalogUrl;
  final String localCatalogAssetPath;
  final String localUpdateAssetPath;
  final SharedSettingsContactConfig contact;
  final SharedSettingsSupportConfig support;
  final SharedSettingsAboutConfig about;

  const SharedSettingsAppConfig({
    required this.appName,
    required this.appId,
    required this.packageName,
    required this.adminName,
    required this.updateRemoteManifestUrl,
    required this.updateFallbackReleaseUrl,
    required this.updateChannel,
    required this.otherAppsRemoteCatalogUrl,
    required this.localCatalogAssetPath,
    required this.localUpdateAssetPath,
    required this.contact,
    required this.support,
    required this.about,
  });
}

class OtherAppItem {
  final String appId;
  final String name;
  final String description;
  final String url;
  final String iconAsset;
  final String iconUrl;
  final bool active;
  final int order;
  final List<String> targetApps;

  const OtherAppItem({
    required this.appId,
    required this.name,
    required this.description,
    required this.url,
    required this.iconAsset,
    required this.iconUrl,
    required this.active,
    required this.order,
    required this.targetApps,
  });

  bool isTargetFor(String appIdValue) {
    if (!active) return false;
    if (targetApps.isEmpty) return true;
    final current = appIdValue.trim().toLowerCase();
    return targetApps.contains('*') || targetApps.contains(current);
  }
}

class UpdateManifest {
  final String version;
  final int buildNumber;
  final String url;
  final bool forceUpdate;
  final String notes;

  const UpdateManifest({
    required this.version,
    required this.buildNumber,
    required this.url,
    required this.forceUpdate,
    required this.notes,
  });
}
