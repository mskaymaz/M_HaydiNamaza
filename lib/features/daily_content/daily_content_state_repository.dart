import 'package:shared_preferences/shared_preferences.dart';

import 'daily_content_selection_models.dart';
import 'daily_content_state_codec.dart';

class DailyContentStateRepository {
  static const String stateKey = 'daily_content_state_v1';

  final DailyContentStateCodec _codec;

  DailyContentStateRepository({DailyContentStateCodec? codec})
    : _codec = codec ?? DailyContentStateCodec();

  Future<DailyContentSelectionState> read({List<String>? warnings}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(stateKey);
      return _codec.decodeOrDefault(raw, warnings: warnings);
    } catch (_) {
      warnings?.add('daily_content_state_v1: state okunamadi, varsayilan kullanildi.');
      return DailyContentSelectionState.empty();
    }
  }

  Future<void> write(DailyContentSelectionState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(stateKey, _codec.encode(state));
    } catch (_) {
      // State write failure should not break daily selection flow.
    }
  }
}

