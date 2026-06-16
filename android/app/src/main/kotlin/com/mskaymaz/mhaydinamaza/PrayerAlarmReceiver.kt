package com.mskaymaz.mhaydinamaza

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
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
        val enabled = intent.getBooleanExtra("voiceEnabled", false) ||
            intent.getBooleanExtra("visualEnabled", false) ||
            intent.getBooleanExtra("azanEnabled", false) ||
            intent.getBooleanExtra("vibrationEnabled", false)
        if (!enabled) return

        val visualIntent = activeReminderIntent(context, intent, title, message)
        showNotification(context, intent, title, message, visualIntent)
        try {
            context.startActivity(visualIntent)
        } catch (_: Exception) {
        }
    }

    private fun activeReminderIntent(
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

    private fun showNotification(
        context: Context,
        sourceIntent: Intent,
        title: String,
        message: String,
        visualIntent: Intent
    ) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureChannel(manager)
        val requestCode = sourceIntent.getIntExtra("id", 0) + 700000
        val pendingIntent = PendingIntent.getActivity(
            context,
            requestCode,
            visualIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(Notification.BigTextStyle().bigText(message))
            .setAutoCancel(false)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setWhen(sourceIntent.getLongExtra("triggerAtMillis", System.currentTimeMillis()))
            .setShowWhen(true)
            .setFullScreenIntent(pendingIntent, true)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_HIGH)
        }
        @Suppress("DEPRECATION")
        builder.setSound(null)
        @Suppress("DEPRECATION")
        builder.setDefaults(0)

        try {
            manager.notify(sourceIntent.getIntExtra("id", 0), builder.build())
        } catch (_: SecurityException) {
        }
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        for (oldChannelId in OLD_CHANNEL_IDS) {
            try {
                manager.deleteNotificationChannel(oldChannelId)
            } catch (_: Exception) {
            }
        }
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Namaz vakti uyarıları",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Namaz vakti hatırlatma, ezan ve titreşim uyarıları"
            enableVibration(false)
            setSound(null, null)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "prayer_reminders_active_v5"
        private val OLD_CHANNEL_IDS = arrayOf("prayer_reminders", "prayer_reminders_silent_v3")
    }
}
