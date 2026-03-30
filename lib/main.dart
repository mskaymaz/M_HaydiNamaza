import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/runtime_monitor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final monitor = RuntimeMonitor.instance;
  monitor.startStartupTimer();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    monitor.reportFlutterError(details);
  };
  ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
    monitor.reportPlatformError(error, stackTrace);
    return false;
  };
  runApp(const App());
}
