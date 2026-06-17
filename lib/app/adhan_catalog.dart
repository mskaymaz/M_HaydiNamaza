enum AdhanSelectionSource { bundled, downloadable, localFile }

extension AdhanSelectionSourceX on AdhanSelectionSource {
  String get key {
    switch (this) {
      case AdhanSelectionSource.bundled:
        return 'bundled';
      case AdhanSelectionSource.downloadable:
        return 'downloadable';
      case AdhanSelectionSource.localFile:
        return 'local_file';
    }
  }
}

AdhanSelectionSource adhanSelectionSourceFromKey(String? key) {
  switch (key) {
    case 'downloadable':
      return AdhanSelectionSource.downloadable;
    case 'local_file':
      return AdhanSelectionSource.localFile;
    case 'bundled':
    default:
      return AdhanSelectionSource.bundled;
  }
}

class AdhanPrayerSlot {
  final String key;
  final String label;

  const AdhanPrayerSlot({required this.key, required this.label});
}

class AdhanCatalogOption {
  final String id;
  final String prayerKey;
  final String label;
  final String fileName;
  final String url;

  const AdhanCatalogOption({
    required this.id,
    required this.prayerKey,
    required this.label,
    required this.fileName,
    required this.url,
  });
}

class AdhanSelection {
  final AdhanSelectionSource source;
  final String? optionId;
  final String label;
  final String? fileName;
  final String? remoteUrl;
  final String? localPath;

  const AdhanSelection({
    required this.source,
    required this.label,
    this.optionId,
    this.fileName,
    this.remoteUrl,
    this.localPath,
  });

  const AdhanSelection.bundled()
      : source = AdhanSelectionSource.bundled,
        optionId = null,
        label = 'Varsayılan ezan',
        fileName = null,
        remoteUrl = null,
        localPath = null;

  bool get hasPlayableLocalPath => (localPath ?? '').trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'source': source.key,
      'optionId': optionId,
      'label': label,
      'fileName': fileName,
      'remoteUrl': remoteUrl,
      'localPath': localPath,
    };
  }

  static AdhanSelection fromJson(Map<String, dynamic> json) {
    final source = adhanSelectionSourceFromKey(json['source']?.toString());
    if (source == AdhanSelectionSource.bundled) {
      return const AdhanSelection.bundled();
    }
    final label = json['label']?.toString().trim() ?? '';
    return AdhanSelection(
      source: source,
      optionId: json['optionId']?.toString(),
      label: label.isEmpty ? 'Seçili ezan' : label,
      fileName: json['fileName']?.toString(),
      remoteUrl: json['remoteUrl']?.toString(),
      localPath: json['localPath']?.toString(),
    );
  }

  static AdhanSelection fromDownloadedOption({
    required AdhanCatalogOption option,
    required String localPath,
  }) {
    return AdhanSelection(
      source: AdhanSelectionSource.downloadable,
      optionId: option.id,
      label: option.label,
      fileName: option.fileName,
      remoteUrl: option.url,
      localPath: localPath,
    );
  }

  static AdhanSelection fromLocalFile({
    required String label,
    required String localPath,
  }) {
    return AdhanSelection(
      source: AdhanSelectionSource.localFile,
      label: label,
      localPath: localPath,
    );
  }
}

const List<AdhanPrayerSlot> kMainAdhanPrayerSlots = <AdhanPrayerSlot>[
  AdhanPrayerSlot(key: 'fajr', label: 'İmsak'),
  AdhanPrayerSlot(key: 'dhuhr', label: 'Öğle'),
  AdhanPrayerSlot(key: 'asr', label: 'İkindi'),
  AdhanPrayerSlot(key: 'maghrib', label: 'Akşam'),
  AdhanPrayerSlot(key: 'isha', label: 'Yatsı'),
];

const String kAdhanRemoteBaseUrl =
    'https://raw.githubusercontent.com/mskaymaz/AllApp/main/Ezanlar';

const List<AdhanCatalogOption> kDownloadableAdhanOptions = <AdhanCatalogOption>[
  AdhanCatalogOption(
    id: 'fajr_abdulkadirsehitoglu',
    prayerKey: 'fajr',
    label: 'Sabah 1',
    fileName: '1_sabah_ezani_abdulkadirsehitoglu.mp3',
    url: '$kAdhanRemoteBaseUrl/1_sabah_ezani_abdulkadirsehitoglu.mp3',
  ),
  AdhanCatalogOption(
    id: 'fajr_ismailcosar',
    prayerKey: 'fajr',
    label: 'Sabah 2',
    fileName: '1_sabah_ezani_ismailcosar.mp3',
    url: '$kAdhanRemoteBaseUrl/1_sabah_ezani_ismailcosar.mp3',
  ),
  AdhanCatalogOption(
    id: 'dhuhr_abdulkadirsehitoglu',
    prayerKey: 'dhuhr',
    label: 'Öğle 1',
    fileName: '2_ogle_ezani_abdulkadirsehitoglu.mp3',
    url: '$kAdhanRemoteBaseUrl/2_ogle_ezani_abdulkadirsehitoglu.mp3',
  ),
  AdhanCatalogOption(
    id: 'dhuhr_ismailcosar',
    prayerKey: 'dhuhr',
    label: 'Öğle 2',
    fileName: '2_ogle_ezani_ismailcosar.mp3',
    url: '$kAdhanRemoteBaseUrl/2_ogle_ezani_ismailcosar.mp3',
  ),
  AdhanCatalogOption(
    id: 'asr_abdulkadirsehitoglu',
    prayerKey: 'asr',
    label: 'İkindi 1',
    fileName: '3_ikindi_ezani_abdulkadirsehitoglu.mp3',
    url: '$kAdhanRemoteBaseUrl/3_ikindi_ezani_abdulkadirsehitoglu.mp3',
  ),
  AdhanCatalogOption(
    id: 'asr_ismailcosar',
    prayerKey: 'asr',
    label: 'İkindi 2',
    fileName: '3_ikindi_ezani_ismailcosar.mp3',
    url: '$kAdhanRemoteBaseUrl/3_ikindi_ezani_ismailcosar.mp3',
  ),
  AdhanCatalogOption(
    id: 'maghrib_abdulkadirsehitoglu',
    prayerKey: 'maghrib',
    label: 'Akşam 1',
    fileName: '4_aksam_ezani_abdulkadirsehitoglu.mp3',
    url: '$kAdhanRemoteBaseUrl/4_aksam_ezani_abdulkadirsehitoglu.mp3',
  ),
  AdhanCatalogOption(
    id: 'maghrib_ismailcosar',
    prayerKey: 'maghrib',
    label: 'Akşam 2',
    fileName: '4_aksam_ezani_ismailcosar.mp3',
    url: '$kAdhanRemoteBaseUrl/4_aksam_ezani_ismailcosar.mp3',
  ),
  AdhanCatalogOption(
    id: 'isha_abdulkadirsehitoglu',
    prayerKey: 'isha',
    label: 'Yatsı 1',
    fileName: '5_yatsi_ezani_abdulkadirsehitoglu.mp3',
    url: '$kAdhanRemoteBaseUrl/5_yatsi_ezani_abdulkadirsehitoglu.mp3',
  ),
  AdhanCatalogOption(
    id: 'isha_ismailcosar',
    prayerKey: 'isha',
    label: 'Yatsı 2',
    fileName: '5_yatsi_ezani_ismailcosar.mp3',
    url: '$kAdhanRemoteBaseUrl/5_yatsi_ezani_ismailcosar.mp3',
  ),
];

Map<String, AdhanSelection> defaultAdhanSelections() {
  return <String, AdhanSelection>{
    for (final slot in kMainAdhanPrayerSlots)
      slot.key: const AdhanSelection.bundled(),
  };
}

List<AdhanCatalogOption> adhanOptionsForPrayer(String prayerKey) {
  return kDownloadableAdhanOptions
      .where((option) => option.prayerKey == prayerKey)
      .toList(growable: false);
}

AdhanSelection adhanSelectionForPrayer(
  Map<String, AdhanSelection> selections,
  String prayerKey,
) {
  return selections[prayerKey] ?? const AdhanSelection.bundled();
}
