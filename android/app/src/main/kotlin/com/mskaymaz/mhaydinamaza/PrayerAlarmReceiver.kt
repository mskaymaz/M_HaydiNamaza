package com.mskaymaz.mhaydinamaza

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale

class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                PrayerAlarmScheduler.scheduleStored(context)
            }
            PrayerAlarmScheduler.ACTION_TRIGGER -> {
                handlePrayerAlarm(context, intent)
            }
        }
    }

    private fun handlePrayerAlarm(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: "Namaz vakti"
        val message = intent.getStringExtra("message") ?: "Namaz vakti"
        val prayerLabel = intent.getStringExtra("prayerLabel") ?: "Vakit"
        val voiceEnabled = intent.getBooleanExtra("voiceEnabled", false)
        val visualEnabled = intent.getBooleanExtra("visualEnabled", false)
        val azanEnabled = intent.getBooleanExtra("azanEnabled", false)
        val vibrationEnabled = intent.getBooleanExtra("vibrationEnabled", false)
        val vibrationDurationMs = intent.getIntExtra("vibrationDurationMs", 3000)

        if (vibrationEnabled) {
            vibrate(context, vibrationDurationMs)
        }
        if (visualEnabled || voiceEnabled || azanEnabled || vibrationEnabled) {
            showNotification(context, intent, title, message)
        }
        if (voiceEnabled) {
            speak(context, "$prayerLabel vakti. $message")
        }
    }

    private fun showNotification(
        context: Context,
        sourceIntent: Intent,
        title: String,
        message: String
    ) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureChannel(manager)

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        val contentIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
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
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setWhen(sourceIntent.getLongExtra("triggerAtMillis", System.currentTimeMillis()))
            .setShowWhen(true)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_HIGH)
            @Suppress("DEPRECATION")
            builder.setSound(soundUri)
            @Suppress("DEPRECATION")
            builder.setDefaults(Notification.DEFAULT_LIGHTS)
        }

        try {
            manager.notify(sourceIntent.getIntExtra("id", 0), builder.build())
        } catch (_: SecurityException) {
        }
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return

        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Namaz vakti uyarilari",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Namaz vakti hatirlatma, ezan ve titresim uyarilari"
            enableVibration(true)
            setSound(soundUri, attributes)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    private fun vibrate(context: Context, durationMs: Int) {
        val duration = durationMs.coerceIn(100, 60_000).toLong()
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                    as VibratorManager
                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(
                    VibrationEffect.createOneShot(
                        duration,
                        VibrationEffect.DEFAULT_AMPLITUDE
                    )
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(duration)
            }
        } catch (_: Exception) {
        }
    }

    private fun speak(context: Context, text: String) {
        val pendingResult = goAsync()
        val handler = Handler(Looper.getMainLooper())
        var finished = false
        var tts: TextToSpeech? = null

        fun finish() {
            if (finished) return
            finished = true
            try {
                tts?.stop()
                tts?.shutdown()
            } catch (_: Exception) {
            }
            try {
                pendingResult.finish()
            } catch (_: Exception) {
            }
        }

        handler.postDelayed({ finish() }, 15_000L)
        tts = TextToSpeech(context.applicationContext) { status ->
            if (status != TextToSpeech.SUCCESS) {
                finish()
                return@TextToSpeech
            }
            val engine = tts ?: run {
                finish()
                return@TextToSpeech
            }
            try {
                engine.language = Locale("tr", "TR")
                engine.setSpeechRate(0.52f)
                engine.setPitch(1.0f)
                engine.setOnUtteranceProgressListener(
                    object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) = Unit
                        override fun onDone(utteranceId: String?) {
                            finish()
                        }
                        @Deprecated("Deprecated in Java")
                        override fun onError(utteranceId: String?) {
                            finish()
                        }
                        override fun onError(utteranceId: String?, errorCode: Int) {
                            finish()
                        }
                    }
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    val params = Bundle().apply {
                        putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, UTTERANCE_ID)
                    }
                    engine.speak(text, TextToSpeech.QUEUE_FLUSH, params, UTTERANCE_ID)
                } else {
                    @Suppress("DEPRECATION")
                    engine.speak(
                        text,
                        TextToSpeech.QUEUE_FLUSH,
                        hashMapOf(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID to UTTERANCE_ID)
                    )
                }
            } catch (_: Exception) {
                finish()
            }
        }
    }

    companion object {
        private const val CHANNEL_ID = "prayer_reminders"
        private const val UTTERANCE_ID = "prayer_reminder_voice"
    }
}
