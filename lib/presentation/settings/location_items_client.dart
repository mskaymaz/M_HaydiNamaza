import 'package:http/http.dart' as http;

import '../../app/runtime_monitor.dart';
import 'location_data_parsers.dart';
import 'location_models.dart';

class DiyanetLocationItemsClient {
  static const Duration timeout = Duration(seconds: 12);
  static const Map<String, String> headers = <String, String>{
    'Accept': 'application/json',
    'User-Agent': 'HaydiNamaza/1.0',
  };

  Future<List<DiyanetItem>> fetchItems(Uri uri) async {
    try {
      final response = await http.get(uri, headers: headers).timeout(timeout);
      if (response.statusCode != 200) return const <DiyanetItem>[];
      return parseItems(response.body);
    } catch (_) {
      RuntimeMonitor.instance.reportNonFatalCode(
        source: 'location_list_fetch',
        code: 'network_or_parse_failed',
      );
      return const <DiyanetItem>[];
    }
  }
}
