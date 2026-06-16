import 'package:shared_preferences/shared_preferences.dart';

import '../../app/runtime_monitor.dart';
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
      final warningCountBefore = warnings?.length ?? 0;
      final state = _codec.decodeOrDefault(raw, warnings: warnings);
      final warningCountAfter = warnings?.length ?? 0;
      final hadDecodeWarning = warningCountAfter > warningCountBefore;

      if (raw != null && raw.trim().isNotEmpty && hadDecodeWarning) {
        await _recoverState(prefs, warnings);
      }
      return state;
    } catch (_) {
      warnings?.add('daily_content_state_v1: state okunamadı, varsayılan kullanıldı.');
      RuntimeMonitor.instance.reportNonFatalCode(
        source: 'daily_content_state_read',
        code: 'state_read_failed',
      );
      return DailyContentSelectionState.empty();
    }
  }

  Future<void> write(DailyContentSelectionState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(stateKey, _codec.encode(state));
    } catch (_) {
      RuntimeMonitor.instance.reportNonFatalCode(
        source: 'daily_content_state_write',
        code: 'state_write_failed',
      );
      // State write failure should not break daily selection flow.
    }
  }

  Future<void> _recoverState(
    SharedPreferences prefs,
    List<String>? warnings,
  ) async {
    try {
      await prefs.setString(
        stateKey,
        _codec.encode(DailyContentSelectionState.empty()),
      );
      warnings?.add('daily_content_state_v1: bozuk state sifirlandi.');
      RuntimeMonitor.instance.reportNonFatalCode(
        source: 'daily_content_state_read',
        code: 'state_recovered',
      );
    } catch (_) {
      RuntimeMonitor.instance.reportNonFatalCode(
        source: 'daily_content_state_read',
        code: 'state_recover_failed',
      );
    }
  }
}
