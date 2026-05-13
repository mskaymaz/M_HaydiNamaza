import 'package:flutter/foundation.dart';

abstract class ErrorReporter {
  void report(
    Object error,
    StackTrace stackTrace, {
    required String source,
    required bool fatal,
  });
}

class DebugPrintErrorReporter implements ErrorReporter {
  @override
  void report(
    Object error,
    StackTrace stackTrace, {
    required String source,
    required bool fatal,
  }) {
    if (!kDebugMode) return;
    final level = fatal ? 'fatal' : 'non_fatal';
    debugPrint('[Error][$source][$level] $error');
  }
}

class RuntimeMonitor {
  RuntimeMonitor._();

  static final RuntimeMonitor instance = RuntimeMonitor._();

  ErrorReporter _errorReporter = DebugPrintErrorReporter();
  final Stopwatch _startupStopwatch = Stopwatch();
  bool _startupStarted = false;
  bool _startupReported = false;

  void configure({ErrorReporter? errorReporter}) {
    if (errorReporter != null) {
      _errorReporter = errorReporter;
    }
  }

  void startStartupTimer() {
    if (_startupStarted) return;
    _startupStarted = true;
    _startupStopwatch.start();
  }

  void markFirstFrameRendered() {
    if (!_startupStarted || _startupReported) return;
    _startupStopwatch.stop();
    _startupReported = true;
    if (kDebugMode) {
      debugPrint(
        '[Perf] startup_first_frame_ms=${_startupStopwatch.elapsedMilliseconds}',
      );
    }
  }

  Future<T> profileAsync<T>(String label, Future<T> Function() action) async {
    final sw = Stopwatch()..start();
    try {
      return await action();
    } finally {
      sw.stop();
      if (kDebugMode) {
        debugPrint('[Perf] $label ms=${sw.elapsedMilliseconds}');
      }
    }
  }

  void reportFlutterError(FlutterErrorDetails details) {
    _errorReporter.report(
      details.exception,
      details.stack ?? StackTrace.current,
      source: 'flutter',
      fatal: true,
    );
  }

  void reportPlatformError(Object error, StackTrace stackTrace) {
    _errorReporter.report(
      error,
      stackTrace,
      source: 'platform',
      fatal: true,
    );
  }

  void reportNonFatalCode({required String source, required String code}) {
    _errorReporter.report(
      StateError(code),
      StackTrace.current,
      source: source,
      fatal: false,
    );
  }
}
