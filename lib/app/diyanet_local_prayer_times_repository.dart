import 'dart:convert';

import 'package:flutter/services.dart';

import 'diyanet_prayer_times_client.dart';
import 'location_storage.dart';
import 'prayer_service_pure_helpers.dart';

class DiyanetLocalPrayerTimesRepository {
  static const String _assetBase = 'assets/data/prayer/diyanet';

  final AssetBundle _bundle;
  final Map<int, _DiyanetLocalIndex> _indexCache = <int, _DiyanetLocalIndex>{};
  final Map<String, _DiyanetProvinceData> _provinceCache =
      <String, _DiyanetProvinceData>{};

  DiyanetLocalPrayerTimesRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  Future<DiyanetDailyTimings?> readDaily({
    required LocationData location,
    required DateTime date,
    void Function(String message)? onLog,
  }) async {
    final countryId = location.countryId?.trim();
    if (countryId != null && countryId.isNotEmpty && countryId != '2') {
      return null;
    }

    final index = await _readIndex(date.year, onLog);
    if (index == null) return null;

    final province = index.findProvince(location);
    if (province == null) {
      onLog?.call('[Diyanet:local] province not found ${location.province}');
      return null;
    }

    final provinceData = await _readProvinceData(date.year, province, onLog);
    if (provinceData == null) return null;

    final district = province.findDistrict(location);
    final localLocation = district == null
        ? provinceData.findLocation(location)
        : provinceData.findLocationById(district.id) ??
            provinceData.findLocation(location);
    if (localLocation == null) {
      onLog?.call('[Diyanet:local] district not found '
          '${location.province}/${location.district}');
      return null;
    }

    final day = localLocation.dayByDate(_dateKey(date));
    if (day == null) {
      onLog?.call('[Diyanet:local] date not found '
          '${_dateKey(date)} ${province.slug}/${localLocation.slug}');
      return null;
    }

    return day.toTimings(date);
  }

  Future<_DiyanetLocalIndex?> _readIndex(
    int year,
    void Function(String message)? onLog,
  ) async {
    final cached = _indexCache[year];
    if (cached != null) return cached;
    try {
      final raw = await _bundle.loadString('$_assetBase/$year/index.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final index = _DiyanetLocalIndex.fromJson(decoded);
      _indexCache[year] = index;
      return index;
    } catch (_) {
      onLog?.call('[Diyanet:local] index missing for $year');
      return null;
    }
  }

  Future<_DiyanetProvinceData?> _readProvinceData(
    int year,
    _DiyanetProvinceRef province,
    void Function(String message)? onLog,
  ) async {
    final cacheKey = '$year/${province.slug}';
    final cached = _provinceCache[cacheKey];
    if (cached != null) return cached;
    try {
      final raw = await _bundle.loadString('$_assetBase/$year/${province.file}');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final data = _DiyanetProvinceData.fromJson(decoded);
      _provinceCache[cacheKey] = data;
      return data;
    } catch (_) {
      onLog?.call('[Diyanet:local] province file missing ${province.file}');
      return null;
    }
  }
}

class _DiyanetLocalIndex {
  final List<_DiyanetProvinceRef> provinces;

  const _DiyanetLocalIndex({required this.provinces});

  factory _DiyanetLocalIndex.fromJson(Map<String, dynamic> json) {
    final rawProvinces = json['provinces'];
    return _DiyanetLocalIndex(
      provinces: rawProvinces is List
          ? rawProvinces
              .whereType<Map<String, dynamic>>()
              .map(_DiyanetProvinceRef.fromJson)
              .toList(growable: false)
          : const <_DiyanetProvinceRef>[],
    );
  }

  _DiyanetProvinceRef? findProvince(LocationData location) {
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

class _DiyanetProvinceRef {
  final String id;
  final String slug;
  final String name;
  final String code;
  final String file;
  final List<_DiyanetDistrictRef> districts;

  _DiyanetProvinceRef({
    required this.id,
    required this.slug,
    required this.name,
    required this.code,
    required this.file,
    required this.districts,
  });

  String get normalizedName => normalizePrayerLocationName(name);
  String get normalizedCode => normalizePrayerLocationName(code);

  factory _DiyanetProvinceRef.fromJson(Map<String, dynamic> json) {
    final rawDistricts = json['districts'];
    return _DiyanetProvinceRef(
      id: _stringValue(json['id']),
      slug: _stringValue(json['slug']),
      name: _stringValue(json['name']),
      code: _stringValue(json['code']),
      file: _stringValue(json['file']),
      districts: rawDistricts is List
          ? rawDistricts
              .whereType<Map<String, dynamic>>()
              .map(_DiyanetDistrictRef.fromJson)
              .toList(growable: false)
          : const <_DiyanetDistrictRef>[],
    );
  }

  _DiyanetDistrictRef? findDistrict(LocationData location) {
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

class _DiyanetDistrictRef {
  final String id;
  final String slug;
  final String name;
  final String code;

  _DiyanetDistrictRef({
    required this.id,
    required this.slug,
    required this.name,
    required this.code,
  });

  String get normalizedName => normalizePrayerLocationName(name);
  String get normalizedCode => normalizePrayerLocationName(code);

  factory _DiyanetDistrictRef.fromJson(Map<String, dynamic> json) {
    return _DiyanetDistrictRef(
      id: _stringValue(json['id']),
      slug: _stringValue(json['slug']),
      name: _stringValue(json['name']),
      code: _stringValue(json['code']),
    );
  }
}

class _DiyanetProvinceData {
  final List<_DiyanetLocalLocation> locations;

  const _DiyanetProvinceData({required this.locations});

  factory _DiyanetProvinceData.fromJson(Map<String, dynamic> json) {
    final rawLocations = json['locations'];
    return _DiyanetProvinceData(
      locations: rawLocations is List
          ? rawLocations
              .whereType<Map<String, dynamic>>()
              .map(_DiyanetLocalLocation.fromJson)
              .toList(growable: false)
          : const <_DiyanetLocalLocation>[],
    );
  }

  _DiyanetLocalLocation? findLocationById(String id) {
    for (final location in locations) {
      if (location.id == id) return location;
    }
    return null;
  }

  _DiyanetLocalLocation? findLocation(LocationData location) {
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

class _DiyanetLocalLocation {
  final String id;
  final String slug;
  final String name;
  final String code;
  final Map<String, _DiyanetLocalDay> days;

  _DiyanetLocalLocation({
    required this.id,
    required this.slug,
    required this.name,
    required this.code,
    required this.days,
  });

  String get normalizedName => normalizePrayerLocationName(name);
  String get normalizedCode => normalizePrayerLocationName(code);

  factory _DiyanetLocalLocation.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final days = <String, _DiyanetLocalDay>{};
    if (rawDays is List) {
      for (final entry in rawDays) {
        final day = _DiyanetLocalDay.fromList(entry);
        if (day != null) days[day.dateKey] = day;
      }
    }
    return _DiyanetLocalLocation(
      id: _stringValue(json['id']),
      slug: _stringValue(json['slug']),
      name: _stringValue(json['name']),
      code: _stringValue(json['code']),
      days: days,
    );
  }

  _DiyanetLocalDay? dayByDate(String dateKey) => days[dateKey];
}

class _DiyanetLocalDay {
  final String dateKey;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  const _DiyanetLocalDay({
    required this.dateKey,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  static _DiyanetLocalDay? fromList(Object? entry) {
    if (entry is! List || entry.length < 7) return null;
    return _DiyanetLocalDay(
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
    if ([fajrTime, sunriseTime, dhuhrTime, asrTime, maghribTime, ishaTime]
        .contains(null)) {
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

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';
