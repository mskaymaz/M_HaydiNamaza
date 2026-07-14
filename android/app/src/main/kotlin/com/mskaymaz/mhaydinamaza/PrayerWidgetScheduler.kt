package com.mskaymaz.mhaydinamaza

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

object PrayerWidgetScheduler {
    private const val PREFS_NAME = "prayer_widget_schedule"
    private const val EVENTS_KEY = "events"
    private const val REFRESH_REQUEST_CODE_BASE = 9911
    private const val DATA_REFRESH_DEBOUNCE_MILLIS = 60_000L
    private const val DATA_REFRESH_RETRY_DELAY_MILLIS = 60_000L
    private const val LAST_DATA_REFRESH_REQUEST_KEY = "lastDataRefreshRequestMillis"
    private val REFRESH_OFFSETS_AFTER_TRANSITION = longArrayOf(1_000L, 60_000L, 5 * 60_000L)
    const val ACTION_REFRESH = "com.mskaymaz.mhaydinamaza.PRAYER_WIDGET_REFRESH"
    const val ACTION_DATA_REFRESH = "com.mskaymaz.mhaydinamaza.PRAYER_WIDGET_DATA_REFRESH"

    data class WidgetEvent(
        val triggerAtMillis: Long,
        val prayerLabel: String,
        val remainingTriggerAtMillis: Long,
        val remainingPrayerLabel: String,
        val timeLabel: String,
        val dateLabel: String,
        val fajrTime: String,
        val sunriseTime: String,
        val dhuhrTime: String,
        val asrTime: String,
        val maghribTime: String,
        val ishaTime: String
    )

    fun configure(context: Context, events: List<Map<String, Any?>>) {
        val normalized = events.mapNotNull { normalizeEvent(it) }.sortedBy { it.triggerAtMillis }
        val json = JSONArray()
        for (event in normalized) {
            json.put(
                JSONObject().apply {
                    put("triggerAtMillis", event.triggerAtMillis)
                    put("prayerLabel", event.prayerLabel)
                    put("remainingTriggerAtMillis", event.remainingTriggerAtMillis)
                    put("remainingPrayerLabel", event.remainingPrayerLabel)
                    put("timeLabel", event.timeLabel)
                    put("dateLabel", event.dateLabel)
                    put("fajrTime", event.fajrTime)
                    put("sunriseTime", event.sunriseTime)
                    put("dhuhrTime", event.dhuhrTime)
                    put("asrTime", event.asrTime)
                    put("maghribTime", event.maghribTime)
                    put("ishaTime", event.ishaTime)
                }
            )
        }
        prefs(context).edit().putString(EVENTS_KEY, json.toString()).apply()
        updateWidgets(context)
    }

    fun updateWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val compact = ComponentName(context, PrayerTimeWidgetProvider::class.java)
        val compactIds = manager.getAppWidgetIds(compact)
        if (compactIds.isNotEmpty()) {
            PrayerTimeWidgetProvider.updateAll(context, manager, compactIds)
        }
        val large = ComponentName(context, PrayerTimeLargeWidgetProvider::class.java)
        val largeIds = manager.getAppWidgetIds(large)
        if (largeIds.isNotEmpty()) {
            PrayerTimeLargeWidgetProvider.updateAll(context, manager, largeIds)
        }
        val wide = ComponentName(context, PrayerTimesWideWidgetProvider::class.java)
        val wideIds = manager.getAppWidgetIds(wide)
        if (wideIds.isNotEmpty()) {
            PrayerTimesWideWidgetProvider.updateAll(context, manager, wideIds)
        }
        scheduleNextRefresh(context)
    }

    fun requestBackgroundRefresh(context: Context) {
        if (!hasInternetConnection(context)) return
        val now = System.currentTimeMillis()
        val prefs = prefs(context)
        val lastRequest = prefs.getLong(LAST_DATA_REFRESH_REQUEST_KEY, 0L)
        if (now - lastRequest < DATA_REFRESH_DEBOUNCE_MILLIS) return
        prefs.edit().putLong(LAST_DATA_REFRESH_REQUEST_KEY, now).apply()
        val intent = Intent(context, PrayerWidgetRefreshReceiver::class.java).apply {
            action = ACTION_DATA_REFRESH
        }
        context.sendBroadcast(intent)
    }

    @Suppress("DEPRECATION")
    private fun hasInternetConnection(context: Context): Boolean {
        val connectivityManager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return connectivityManager.activeNetworkInfo?.isConnected == true
        }
        val network = connectivityManager.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
            capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
    }

    fun nextEvent(context: Context): WidgetEvent? {
        val now = System.currentTimeMillis()
        return readEvents(context)
            .filter { it.remainingTriggerAtMillis > now }
            .minByOrNull { it.remainingTriggerAtMillis }
    }

    private fun nextRefreshEvent(context: Context): WidgetEvent? {
        val now = System.currentTimeMillis()
        return readEvents(context)
            .filter { it.remainingTriggerAtMillis > now }
            .minByOrNull { it.remainingTriggerAtMillis }
    }

    private fun scheduleNextRefresh(context: Context) {
        val next = nextRefreshEvent(context)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (next == null) {
            scheduleRefreshAt(
                context = context,
                alarmManager = alarmManager,
                requestCode = REFRESH_REQUEST_CODE_BASE,
                triggerAt = System.currentTimeMillis() + DATA_REFRESH_RETRY_DELAY_MILLIS
            )
            return
        }
        for ((index, offset) in REFRESH_OFFSETS_AFTER_TRANSITION.withIndex()) {
            scheduleRefreshAt(
                context = context,
                alarmManager = alarmManager,
                requestCode = REFRESH_REQUEST_CODE_BASE + index,
                triggerAt = next.remainingTriggerAtMillis + offset
            )
        }
    }

    private fun scheduleRefreshAt(
        context: Context,
        alarmManager: AlarmManager,
        requestCode: Int,
        triggerAt: Long
    ) {
        val pendingIntent = refreshPendingIntent(context, requestCode)
        alarmManager.cancel(pendingIntent)
        try {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms() -> {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAt,
                        pendingIntent
                    )
                }
                else -> {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                }
            }
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
        }
    }

    private fun refreshPendingIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, PrayerTimeWidgetProvider::class.java).apply {
            action = ACTION_REFRESH
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun readEvents(context: Context): List<WidgetEvent> {
        val raw = prefs(context).getString(EVENTS_KEY, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            val result = mutableListOf<WidgetEvent>()
            for (index in 0 until array.length()) {
                val item = array.optJSONObject(index) ?: continue
                result.add(
                    WidgetEvent(
                        triggerAtMillis = item.optLong("triggerAtMillis", 0L),
                        prayerLabel = item.optString("prayerLabel", "Vakit"),
                        remainingTriggerAtMillis = item.optLong(
                            "remainingTriggerAtMillis",
                            item.optLong("triggerAtMillis", 0L)
                        ),
                        remainingPrayerLabel = item.optString(
                            "remainingPrayerLabel",
                            item.optString("prayerLabel", "Vakit")
                        ),
                        timeLabel = item.optString("timeLabel", "--:--"),
                        dateLabel = item.optString("dateLabel", ""),
                        fajrTime = item.optString("fajrTime", "--:--"),
                        sunriseTime = item.optString("sunriseTime", "--:--"),
                        dhuhrTime = item.optString("dhuhrTime", "--:--"),
                        asrTime = item.optString("asrTime", "--:--"),
                        maghribTime = item.optString("maghribTime", "--:--"),
                        ishaTime = item.optString("ishaTime", "--:--")
                    )
                )
            }
            result.sortedBy { it.triggerAtMillis }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun normalizeEvent(input: Map<String, Any?>): WidgetEvent? {
        val triggerAtMillis = numberToLong(input["triggerAtMillis"]) ?: return null
        val prayerLabel = input["prayerLabel"]?.toString()?.trim().orEmpty()
        val timeLabel = input["timeLabel"]?.toString()?.trim().orEmpty()
        if (prayerLabel.isEmpty() || timeLabel.isEmpty()) return null
        return WidgetEvent(
            triggerAtMillis = triggerAtMillis,
            prayerLabel = prayerLabel,
            remainingTriggerAtMillis = numberToLong(input["remainingTriggerAtMillis"]) ?: triggerAtMillis,
            remainingPrayerLabel = input["remainingPrayerLabel"]?.toString()?.trim().orEmpty().ifEmpty { prayerLabel },
            timeLabel = timeLabel,
            dateLabel = input["dateLabel"]?.toString()?.trim().orEmpty(),
            fajrTime = input["fajrTime"]?.toString()?.trim().orEmpty().ifEmpty { "--:--" },
            sunriseTime = input["sunriseTime"]?.toString()?.trim().orEmpty().ifEmpty { "--:--" },
            dhuhrTime = input["dhuhrTime"]?.toString()?.trim().orEmpty().ifEmpty { "--:--" },
            asrTime = input["asrTime"]?.toString()?.trim().orEmpty().ifEmpty { "--:--" },
            maghribTime = input["maghribTime"]?.toString()?.trim().orEmpty().ifEmpty { "--:--" },
            ishaTime = input["ishaTime"]?.toString()?.trim().orEmpty().ifEmpty { "--:--" }
        )
    }

    private fun numberToLong(value: Any?): Long? {
        return when (value) {
            is Long -> value
            is Int -> value.toLong()
            is Double -> value.toLong()
            is Float -> value.toLong()
            is Number -> value.toLong()
            else -> value?.toString()?.toLongOrNull()
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
