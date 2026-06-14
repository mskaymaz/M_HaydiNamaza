package com.mskaymaz.mhaydinamaza

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mhaydinamaza/prayer_notifications"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "ensurePermissions" -> {
                    requestNotificationPermissionIfNeeded()
                    result.success(null)
                }
                "configure" -> {
                    val events = call.argument<List<Map<String, Any?>>>("events").orEmpty()
                    PrayerAlarmScheduler.configure(this, events)
                    result.success(null)
                }
                "configureWidget" -> {
                    val events = call.argument<List<Map<String, Any?>>>("events").orEmpty()
                    PrayerWidgetScheduler.configure(this, events)
                    result.success(null)
                }
                "cancelAll" -> {
                    PrayerAlarmScheduler.cancelAll(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            42
        )
    }
}
