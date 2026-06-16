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
        val title = intent.getStringExtra("title") ?: "Namaz vakti"
        val message = intent.getStringExtra("message") ?: "Namaz vakti"
        val voiceEnabled = intent.getBooleanExtra("voiceEnabled", false)
        val visualEnabled = intent.getBooleanExtra("visualEnabled", false)
        val azanEnabled = intent.getBooleanExtra("azanEnabled", false)
        val vibrationEnabled = intent.getBooleanExtra("vibrationEnabled", false)
        if (!voiceEnabled && !visualEnabled && !azanEnabled && !vibrationEnabled) return

        startActiveReminderService(context, intent)
        if (visualEnabled) {
            try {
                context.startActivity(activeReminderIntent(context, intent, title, message))
            } catch (_: Exception) {
            }
        }
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

    companion object {
        fun activeReminderIntent(
            context: Context,
            sourceIntent: Intent,
            title: String,
            message: String
        ): Intent {
            return Intent(context, PrayerVisualReminderActivity::class.java).apply {
                putExtra("notificationId", sourceIntent.getIntExtra("id", 0))
                putExtra("title", title)
                putExtra("message", message)
                putExtra("prayerLabel", sourceIntent.getStringExtra("prayerLabel") ?: "Vakit")
                putExtra("stage", sourceIntent.getStringExtra("stage") ?: "reminder")
                putExtra("voiceEnabled", sourceIntent.getBooleanExtra("voiceEnabled", false))
                putExtra("visualEnabled", sourceIntent.getBooleanExtra("visualEnabled", false))
                putExtra("azanEnabled", sourceIntent.getBooleanExtra("azanEnabled", false))
                putExtra("vibrationEnabled", sourceIntent.getBooleanExtra("vibrationEnabled", false))
                putExtra("vibrationDurationMs", sourceIntent.getIntExtra("vibrationDurationMs", 3000))
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
            }
        }
    }
}
