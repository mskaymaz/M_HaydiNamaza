import 'diyanet_prayer_times_client.dart';
import 'location_storage.dart';
import 'prayer_service_pure_helpers.dart';

class DiyanetPrayerDataIndex {
  final List<DiyanetProvinceRef> provinces;

  const DiyanetPrayerDataIndex({required this.provinces});

  factory DiyanetPrayerDataIndex.fromJson(Map<String, dynamic> json) {
    final rawProvinces = json['provinces'];
    return DiyanetPrayerDataIndex(
      provinces: rawProvinces is List
          ? rawProvinces
                .whereType<Map<String, dynamic>>()
                .map(DiyanetProvinceRef.fromJson)
                .toList(growable: false)
          : const <DiyanetProvinceRef>[],
    );
  }

  bool get isValid => provinces.isNotEmpty;

  DiyanetProvinceRef? findProvince(LocationData location) {
    final stateId = location.stateId?.trim();
    if (stateId != null && stateId.isNotEmpty) {
      for (final province in provinces) {
        if (province.id == stateId) return province;
      }
    }
    final provinceKey = normalizePrayerLocationName(location.province);
    for (final province in provinces) {
      if (province.normalizedName == provinceKey ||
          province.normalizedCode == provinceKey) {
        return province;
      }
    }
    return null;
  }
}

class DiyanetProvinceRef {
  final String id;
  final String slug;
  final String name;
  final String code;
  final String file;
  final List<DiyanetDistrictRef> districts;

  DiyanetProvinceRef({
    required this.id,
    required this.slug,
    required this.name,
    required this.code,
    required this.file,
    required this.districts,
  });

  String get normalizedName => normalizePrayerLocationName(name);
  String get normalizedCode => normalizePrayerLocationName(code);

  factory DiyanetProvinceRef.fromJson(Map<String, dynamic> json) {
    final rawDistricts = json['districts'];
    return DiyanetProvinceRef(
      id: _stringValue(json['id']),
      slug: _stringValue(json['slug']),
      name: _stringValue(json['name']),
      code: _stringValue(json['code']),
      file: _stringValue(json['file']),
      districts: rawDistricts is List
          ? rawDistricts
                .whereType<Map<String, dynamic>>()
                .map(DiyanetDistrictRef.fromJson)
                .toList(growable: false)
          : const <DiyanetDistrictRef>[],
    );
  }

  DiyanetDistrictRef? findDistrict(LocationData location) {
    final districtId = location.districtId?.trim();
    if (districtId != null && districtId.isNotEmpty) {
      for (final district in districts) {
        if (district.id == districtId) return district;
      }
    }
    final districtKey = normalizePrayerLocationName(location.district);
    for (final district in districts) {
      if (district.normalizedName == districtKey ||
          district.normalizedCode == districtKey) {
        return district;
      }
    }
    return null;
  }
}

class DiyanetDistrictRef {
  final String id;
  final String slug;
  final String name;
  final String code;

  DiyanetDistrictRef({
    required this.id,
    required this.slug,
    required this.name,
    required this.code,
  });

  String get normalizedName => normalizePrayerLocationName(name);
  String get normalizedCode => normalizePrayerLocationName(code);

  factory DiyanetDistrictRef.fromJson(Map<String, dynamic> json) {
    return DiyanetDistrictRef(
      id: _stringValue(json['id']),
      slug: _stringValue(json['slug']),
      name: _stringValue(json['name']),
      code: _stringValue(json['code']),
    );
  }
}

class DiyanetProvinceData {
  final List<DiyanetLocalLocation> locations;

  const DiyanetProvinceData({required this.locations});

  factory DiyanetProvinceData.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['locations'];
    return DiyanetProvinceData(
      locations: rawLocations is List
          ? rawLocations
                .whereType<Map<String, dynamic>>()
                .map(DiyanetLocalLocation.fromJson)
                .toList(growable: false)
          : const <DiyanetLocalLocation>[],
    );
  }

  bool get isValid => locations.isNotEmpty;

  DiyanetLocalLocation? findLocationById(String id) {
    for (final location in locations) {
      if (location.id == id) return location;
    }
    return null;
  }

  DiyanetLocalLocation? findLocation(LocationData location) {
    final districtKey = normalizePrayerLocationName(location.district);
    for (final localLocation in locations) {
      if (localLocation.normalizedName == districtKey ||
          localLocation.normalizedCode == districtKey) {
        return localLocation;
      }
    }
    return null;
  }
}

class DiyanetLocalLocation {
  final String id;
  final String slug;
  final String name;
  final String code;
  final Map<String, DiyanetLocalDay> days;

  DiyanetLocalLocation({
    required this.id,
    required this.slug,
    required this.name,
    required this.code,
    required this.days,
  });

  String get normalizedName => normalizePrayerLocationName(name);
  String get normalizedCode => normalizePrayerLocationName(code);

  factory DiyanetLocalLocation.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final days = <String, DiyanetLocalDay>{};
    if (rawDays is List) {
      for (final entry in rawDays) {
        final day = DiyanetLocalDay.fromList(entry);
        if (day != null) days[day.dateKey] = day;
      }
    }
    return DiyanetLocalLocation(
      id: _stringValue(json['id']),
      slug: _stringValue(json['slug']),
      name: _stringValue(json['name']),
      code: _stringValue(json['code']),
      days: days,
    );
  }

  DiyanetLocalDay? dayByDate(String dateKey) => days[dateKey];
}

class DiyanetLocalDay {
  final String dateKey;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  const DiyanetLocalDay({
    required this.dateKey,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  static DiyanetLocalDay? fromList(Object? entry) {
    if (entry is! List || entry.length < 7) return null;
    return DiyanetLocalDay(
      dateKey: _stringValue(entry[0]),
      fajr: _stringValue(entry[1]),
      sunrise: _stringValue(entry[2]),
      dhuhr: _stringValue(entry[3]),
      asr: _stringValue(entry[4]),
      maghrib: _stringValue(entry[5]),
      isha: _stringValue(entry[6]),
    );
  }

  DiyanetDailyTimings? toTimings(DateTime date) {
    final baseDate = DateTime(date.year, date.month, date.day);
    final fajrTime = parsePrayerClockTime(raw: fajr, baseDate: baseDate);
    final sunriseTime = parsePrayerClockTime(raw: sunrise, baseDate: baseDate);
    final dhuhrTime = parsePrayerClockTime(raw: dhuhr, baseDate: baseDate);
    final asrTime = parsePrayerClockTime(raw: asr, baseDate: baseDate);
    final maghribTime = parsePrayerClockTime(raw: maghrib, baseDate: baseDate);
    final ishaTime = parsePrayerClockTime(raw: isha, baseDate: baseDate);
    if ([
      fajrTime,
      sunriseTime,
      dhuhrTime,
      asrTime,
      maghribTime,
      ishaTime,
    ].contains(null)) {
      return null;
    }
    return DiyanetDailyTimings(
      baseDate: baseDate,
      fajr: fajrTime!,
      sunrise: sunriseTime!,
      dhuhr: dhuhrTime!,
      asr: asrTime!,
      maghrib: maghribTime!,
      isha: ishaTime!,
    );
  }
}

String diyanetPrayerDateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';
