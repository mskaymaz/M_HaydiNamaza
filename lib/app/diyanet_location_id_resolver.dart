import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/config_registry.dart';
import 'prayer_service_pure_helpers.dart';

class DiyanetLocationIdResolver {
  static final Map<String, String> _stateIdCache = <String, String>{};
  static final Map<String, String> _districtIdCache = <String, String>{};

  Future<DiyanetIds?> resolve({
    required String? countryId,
    required String province,
    required String district,
    required Duration timeout,
    required Map<String, String> headers,
    void Function(String message)? onLog,
  }) async {
    final provinceKey = normalizePrayerLocationName(province);
    final districtKey = normalizePrayerLocationName(district);
    final config = ConfigRegistry.dataSources.diyanet;
    final resolvedCountryId =
        (countryId != null && countryId.trim().isNotEmpty)
            ? countryId.trim()
            : config.countryId;
    final cachePrefix = '$resolvedCountryId|$provinceKey';
    final cachedState = _stateIdCache[cachePrefix];
    final cachedDistrict = _districtIdCache['$cachePrefix|$districtKey'];
    if (cachedState != null && cachedDistrict != null) {
      return DiyanetIds(stateId: cachedState, districtId: cachedDistrict);
    }

    final statesUri = Uri.parse('${config.baseUrl}/api/locations/states').replace(
      queryParameters: <String, String>{'countryId': resolvedCountryId},
    );

    try {
      final statesResponse = await http.get(statesUri, headers: headers).timeout(timeout);
      if (statesResponse.statusCode != 200) {
        onLog?.call('[Diyanet] states status=${statesResponse.statusCode}');
        return null;
      }
      final statesPayload = jsonDecode(statesResponse.body) as Map<String, dynamic>;
      final statesData = statesPayload['data'];
      if (statesData is! List) {
        return null;
      }
      final stateId = findDiyanetEntryIdByNormalizedName(statesData, provinceKey);
      if (stateId == null) {
        onLog?.call('[Diyanet] state not found for $province');
        return null;
      }

      final districtsUri = Uri.parse('${config.baseUrl}/api/locations/districts').replace(
        queryParameters: <String, String>{'stateId': stateId},
      );
      final districtsResponse = await http
          .get(districtsUri, headers: headers)
          .timeout(timeout);
      if (districtsResponse.statusCode != 200) {
        onLog?.call('[Diyanet] districts status=${districtsResponse.statusCode}');
        return null;
      }
      final districtsPayload = jsonDecode(districtsResponse.body) as Map<String, dynamic>;
      final districtsData = districtsPayload['data'];
      if (districtsData is! List) {
        return null;
      }
      final districtId = findDiyanetEntryIdByNormalizedName(
        districtsData,
        districtKey,
      );
      if (districtId == null) {
        onLog?.call('[Diyanet] district not found for $province/$district');
        return null;
      }

      _stateIdCache[cachePrefix] = stateId;
      _districtIdCache['$cachePrefix|$districtKey'] = districtId;
      return DiyanetIds(stateId: stateId, districtId: districtId);
    } catch (_) {
      return null;
    }
  }
}
