package com.mskaymaz.mhaydinamaza

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.concurrent.atomic.AtomicBoolean

class PrayerWidgetRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != PrayerWidgetScheduler.ACTION_DATA_REFRESH) return

        val pendingResult = goAsync()
        val finished = AtomicBoolean(false)
        val finish: (FlutterEngine?) -> Unit = { engine ->
            if (finished.compareAndSet(false, true)) {
                engine?.destroy()
                pendingResult.finish()
            }
        }
        val timeoutHandler = Handler(Looper.getMainLooper())
        var engine: FlutterEngine? = null
        try {
            val appContext = context.applicationContext
            val loader = FlutterLoader()
            loader.startInitialization(appContext)
            loader.ensureInitializationComplete(appContext, null)
            engine = FlutterEngine(appContext)
            GeneratedPluginRegistrant.registerWith(engine!!)
            val channel = MethodChannel(
                engine!!.dartExecutor.binaryMessenger,
                "mhaydinamaza/prayer_notifications"
            )
            channel.setMethodCallHandler { call, result ->
                if (call.method != "configureWidget") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val events = call.argument<List<Map<String, Any?>>>("events").orEmpty()
                PrayerWidgetScheduler.configure(appContext, events)
                result.success(null)
                timeoutHandler.removeCallbacksAndMessages(null)
                finish(engine)
            }
            timeoutHandler.postDelayed({ finish(engine) }, 60_000L)
            val entrypoint = DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "package:mhaydinamaza/app/native_prayer_notification_scheduler.dart",
                "prayerWidgetBackgroundRefresh"
            )
            engine!!.dartExecutor.executeDartEntrypoint(entrypoint)
        } catch (_: Exception) {
            timeoutHandler.removeCallbacksAndMessages(null)
            finish(engine)
        }
    }
}
