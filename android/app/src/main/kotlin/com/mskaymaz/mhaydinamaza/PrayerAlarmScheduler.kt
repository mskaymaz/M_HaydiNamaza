package com.mskaymaz.mhaydinamaza

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

object PrayerAlarmScheduler {
    private const val PREFS_NAME = "prayer_notification_schedule"
    private const val EVENTS_KEY = "events"
    const val ACTION_TRIGGER = "com.mskaymaz.mhaydinamaza.PRAYER_ALARM"

    fun configure(context: Context, events: List<Map<String, Any?>>) {
        val storedEvents = readStoredEvents(context)
        cancelEvents(context, storedEvents)

        val now = System.currentTimeMillis()
        val json = JSONArray()
        val normalized = events
            .mapNotNull { normalizeEvent(it) }
            .filter { it.optLong("triggerAtMillis", 0L) > now }

        for (event in normalized) {
            json.put(event)
        }
        prefs(context).edit().putString(EVENTS_KEY, json.toString()).apply()
        scheduleEvents(context, normalized)
    }

    fun cancelAll(context: Context) {
        val storedEvents = readStoredEvents(context)
        cancelEvents(context, storedEvents)
        prefs(context).edit().remove(EVENTS_KEY).apply()
    }

    fun scheduleStored(context: Context) {
        val now = System.currentTimeMillis()
        val events = readStoredEvents(context)
            .filter { it.optLong("triggerAtMillis", 0L) > now }
        val json = JSONArray()
        for (event in events) {
            json.put(event)
        }
        prefs(context).edit().putString(EVENTS_KEY, json.toString()).apply()
        scheduleEvents(context, events)
    }

    private fun scheduleEvents(context: Context, events: List<JSONObject>) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (event in events) {
            val triggerAtMillis = event.optLong("triggerAtMillis", 0L)
            if (triggerAtMillis <= System.currentTimeMillis()) continue
            val pendingIntent = pendingIntentFor(context, event)
            scheduleAlarm(alarmManager, triggerAtMillis, pendingIntent)
        }
    }

    private fun scheduleAlarm(
        alarmManager: AlarmManager,
        triggerAtMillis: Long,
        pendingIntent: PendingIntent
    ) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                    return
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
                return
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
                return
            }
        } catch (_: SecurityException) {
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            alarmManager.setWindow(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                60_000L,
                pendingIntent
            )
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        }
    }

    private fun cancelEvents(context: Context, events: List<JSONObject>) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (event in events) {
            alarmManager.cancel(pendingIntentFor(context, event))
        }
    }

    private fun pendingIntentFor(context: Context, event: JSONObject): PendingIntent {
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            action = ACTION_TRIGGER
            putExtra("id", event.optInt("id", 0))
            putExtra("triggerAtMillis", event.optLong("triggerAtMillis", 0L))
            putExtra("prayerLabel", event.optString("prayerLabel", "Vakit"))
            putExtra("stage", event.optString("stage", "reminder"))
            putExtra("title", event.optString("title", "Namaz vakti"))
            putExtra("message", event.optString("message", "Namaz vakti"))
            putExtra("voiceEnabled", event.optBoolean("voiceEnabled", false))
            putExtra("visualEnabled", event.optBoolean("visualEnabled", false))
            putExtra("azanEnabled", event.optBoolean("azanEnabled", false))
            putExtra("vibrationEnabled", event.optBoolean("vibrationEnabled", false))
            putExtra("vibrationDurationMs", event.optInt("vibrationDurationMs", 3000))
        }
        return PendingIntent.getBroadcast(
            context,
            event.optInt("id", 0),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun readStoredEvents(context: Context): List<JSONObject> {
        val raw = prefs(context).getString(EVENTS_KEY, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            val result = mutableListOf<JSONObject>()
            for (index in 0 until array.length()) {
                val event = array.optJSONObject(index) ?: continue
                result.add(event)
            }
            result
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun normalizeEvent(input: Map<String, Any?>): JSONObject? {
        val id = numberToInt(input["id"]) ?: return null
        val triggerAtMillis = numberToLong(input["triggerAtMillis"]) ?: return null
        return JSONObject().apply {
            put("id", id)
            put("triggerAtMillis", triggerAtMillis)
            put("prayerLabel", input["prayerLabel"]?.toString().orEmpty())
            put("stage", input["stage"]?.toString().orEmpty())
            put("title", input["title"]?.toString().orEmpty())
            put("message", input["message"]?.toString().orEmpty())
            put("voiceEnabled", input["voiceEnabled"] == true)
            put("visualEnabled", input["visualEnabled"] == true)
            put("azanEnabled", input["azanEnabled"] == true)
            put("vibrationEnabled", input["vibrationEnabled"] == true)
            put("vibrationDurationMs", numberToInt(input["vibrationDurationMs"]) ?: 3000)
        }
    }

    private fun numberToInt(value: Any?): Int? {
        return when (value) {
            is Int -> value
            is Long -> value.toInt()
            is Double -> value.toInt()
            is Float -> value.toInt()
            is Number -> value.toInt()
            else -> value?.toString()?.toIntOrNull()
        }
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
