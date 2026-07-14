package com.mskaymaz.mhaydinamaza

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> PrayerAlarmScheduler.scheduleStored(context)
            PrayerAlarmScheduler.ACTION_TRIGGER -> handlePrayerAlarm(context, intent)
        }
    }

    private fun handlePrayerAlarm(context: Context, intent: Intent) {
        if (intent.getBooleanExtra("silentModeEvent", false)) {
            if (intent.getStringExtra("stage") == "silence_start") {
                PrayerSilenceManager.start(context)
            } else if (intent.getStringExtra("stage") == "silence_end") {
                PrayerSilenceManager.end(context)
            }
            return
        }
        val title = intent.getStringExtra("title") ?: "Namaz vakti"
        val message = intent.getStringExtra("message") ?: "Namaz vakti"
        val voiceEnabled = intent.getBooleanExtra("voiceEnabled", false)
        val azanEnabled = intent.getBooleanExtra("azanEnabled", false)
        val vibrationEnabled = intent.getBooleanExtra("vibrationEnabled", false)
        if (!voiceEnabled && !azanEnabled && !vibrationEnabled) return

        startActiveReminderService(context, intent)
    }

    private fun startActiveReminderService(context: Context, intent: Intent) {
        val serviceIntent = PrayerActiveReminderService.startIntent(context, intent)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (_: Exception) {
        }
    }

}
