import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/config_registry.dart';
import 'prayer_service_pure_helpers.dart';

class DiyanetLocationIdResolver {
  static final Map<String, String> _stateIdCache = <String, String>{};
  static final Map<String, String> _districtIdCache = <String, String>{};

  Future<DiyanetIds?> resolve({
    required String? countryId,
    required String? stateId,
    required String? districtId,
    required String province,
    required String district,
    required Duration timeout,
    required Map<String, String> headers,
    void Function(String message)? onLog,
  }) async {
    final provinceKey = normalizePrayerLocationName(province);
    final districtKey = normalizePrayerLocationName(district);
    final config = ConfigRegistry.dataSources.diyanet;
    final resolvedCountryId = _resolveCountryId(countryId, config.countryId);
    final storedStateId = stateId?.trim() ?? '';
    final storedDistrictId = districtId?.trim() ?? '';
    if (storedStateId.isNotEmpty && storedDistrictId.isNotEmpty) {
      return DiyanetIds(stateId: storedStateId, districtId: storedDistrictId);
    }

    final cachePrefix = '$resolvedCountryId|$provinceKey';
    final cachedState = _stateIdCache[cachePrefix];
    final cachedDistrict = _districtIdCache['$cachePrefix|$districtKey'];
    if (cachedState != null && cachedDistrict != null) {
      return DiyanetIds(stateId: cachedState, districtId: cachedDistrict);
    }

    final resolvedStateId = storedStateId.isNotEmpty
        ? storedStateId
        : await _fetchStateId(
            countryId: resolvedCountryId,
            province: province,
            provinceKey: provinceKey,
            timeout: timeout,
            headers: headers,
            onLog: onLog,
          );
    if (resolvedStateId == null) return null;

    final resolvedDistrictId = storedDistrictId.isNotEmpty
        ? storedDistrictId
        : await _fetchDistrictId(
            stateId: resolvedStateId,
            province: province,
            district: district,
            districtKey: districtKey,
            timeout: timeout,
            headers: headers,
            onLog: onLog,
          );
    if (resolvedDistrictId == null) return null;

    _stateIdCache[cachePrefix] = resolvedStateId;
    _districtIdCache['$cachePrefix|$districtKey'] = resolvedDistrictId;
    return DiyanetIds(
      stateId: resolvedStateId,
      districtId: resolvedDistrictId,
    );
  }

  String _resolveCountryId(String? countryId, String fallback) {
    final value = countryId?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  Future<String?> _fetchStateId({
    required String countryId,
    required String province,
    required String provinceKey,
    required Duration timeout,
    required Map<String, String> headers,
    void Function(String message)? onLog,
  }) async {
    final config = ConfigRegistry.dataSources.diyanet;
    final uri = Uri.parse('${config.baseUrl}/api/locations/states').replace(
      queryParameters: <String, String>{'countryId': countryId},
    );
    try {
      final response = await http.get(uri, headers: headers).timeout(timeout);
      if (response.statusCode != 200) {
        onLog?.call('[Diyanet] states status=${response.statusCode}');
        return null;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'];
      if (data is! List) return null;
      final id = findDiyanetEntryIdByNormalizedName(data, provinceKey);
      if (id == null) onLog?.call('[Diyanet] state not found for $province');
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fetchDistrictId({
    required String stateId,
    required String province,
    required String district,
    required String districtKey,
    required Duration timeout,
    required Map<String, String> headers,
    void Function(String message)? onLog,
  }) async {
    final config = ConfigRegistry.dataSources.diyanet;
    final uri = Uri.parse('${config.baseUrl}/api/locations/districts').replace(
      queryParameters: <String, String>{'stateId': stateId},
    );
    try {
      final response = await http.get(uri, headers: headers).timeout(timeout);
      if (response.statusCode != 200) {
        onLog?.call('[Diyanet] districts status=${response.statusCode}');
        return null;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'];
      if (data is! List) return null;
      final id = findDiyanetEntryIdByNormalizedName(data, districtKey);
      if (id == null) {
        onLog?.call('[Diyanet] district not found for $province/$district');
      }
      return id;
    } catch (_) {
      return null;
    }
  }
}
