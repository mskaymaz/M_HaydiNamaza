package com.mskaymaz.mhaydinamaza

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
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
            showNotification(context, intent, title, message, visualEnabled)
        }
        if (voiceEnabled) {
            speak(context, "$prayerLabel vakti. $message")
        } else if (azanEnabled) {
            speak(context, "Ezan okunuyor", repeatCount = 3, pauseMillis = 5000L)
        }
    }

    private fun showNotification(
        context: Context,
        sourceIntent: Intent,
        title: String,
        message: String,
        visualEnabled: Boolean
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
        val visualIntent = Intent(context, PrayerVisualReminderActivity::class.java).apply {
            putExtra("title", title)
            putExtra("message", message)
            putExtra("prayerLabel", sourceIntent.getStringExtra("prayerLabel") ?: "Vakit")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val visualPendingIntent = PendingIntent.getActivity(
            context,
            sourceIntent.getIntExtra("id", 0) + 700000,
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
            .setAutoCancel(true)
            .setContentIntent(if (visualEnabled) visualPendingIntent else contentIntent)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setWhen(sourceIntent.getLongExtra("triggerAtMillis", System.currentTimeMillis()))
            .setShowWhen(true)

        if (visualEnabled) {
            builder.setFullScreenIntent(visualPendingIntent, true)
        }
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

    private fun speak(
        context: Context,
        text: String,
        repeatCount: Int = 1,
        pauseMillis: Long = 0L
    ) {
        val pendingResult = goAsync()
        val handler = Handler(Looper.getMainLooper())
        val safeRepeatCount = repeatCount.coerceIn(1, 3)
        var finished = false
        var spokenCount = 0
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

        fun speakOnce(engine: TextToSpeech) {
            val utteranceId = "${UTTERANCE_ID}_$spokenCount"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val params = Bundle().apply {
                    putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId)
                }
                engine.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
            } else {
                @Suppress("DEPRECATION")
                engine.speak(
                    text,
                    TextToSpeech.QUEUE_FLUSH,
                    hashMapOf(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID to utteranceId)
                )
            }
        }

        handler.postDelayed({ finish() }, 32_000L)
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
                if (!applyMaleTurkishVoice(engine)) {
                    finish()
                    return@TextToSpeech
                }
                engine.setSpeechRate(0.52f)
                engine.setPitch(1.0f)
                engine.setOnUtteranceProgressListener(
                    object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) = Unit
                        override fun onDone(utteranceId: String?) {
                            spokenCount += 1
                            if (spokenCount >= safeRepeatCount) {
                                finish()
                                return
                            }
                            handler.postDelayed({
                                if (!finished) speakOnce(engine)
                            }, pauseMillis.coerceIn(0L, 5000L))
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
                speakOnce(engine)
            } catch (_: Exception) {
                finish()
            }
        }
    }

    private fun applyMaleTurkishVoice(engine: TextToSpeech): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return false
        val voices = try {
            engine.voices
        } catch (_: Exception) {
            null
        } ?: return false
        val selectedVoice = voices.firstOrNull { voice ->
            val name = voice.name.lowercase(Locale.US)
            isTurkishVoice(name, voice.locale) &&
                name == DEFAULT_TURKISH_MALE_VOICE_NAME
        } ?: voices.firstOrNull { voice ->
            isTurkishVoice(voice.name, voice.locale) &&
                voiceLooksMale(voice.name, voice.features)
        } ?: return false
        return try {
            val languageResult = engine.setLanguage(selectedVoice.locale)
            if (
                languageResult == TextToSpeech.LANG_MISSING_DATA ||
                languageResult == TextToSpeech.LANG_NOT_SUPPORTED
            ) {
                return false
            }
            engine.setVoice(selectedVoice) == TextToSpeech.SUCCESS
        } catch (_: Exception) {
            false
        }
    }

    private fun isTurkishVoice(name: String, locale: Locale): Boolean {
        val normalizedName = name.lowercase(Locale.US)
        return locale.language.equals("tr", ignoreCase = true) ||
            normalizedName.startsWith("tr-")
    }

    private fun voiceLooksMale(name: String, features: Set<String>?): Boolean {
        val searchText = buildString {
            append(name.lowercase(Locale.US))
            features.orEmpty().forEach { feature ->
                append('|')
                append(feature.lowercase(Locale.US))
            }
        }
        if (searchText.contains("female") ||
            searchText.contains("woman") ||
            searchText.contains("kadın") ||
            searchText.contains("kadin")
        ) {
            return false
        }
        return searchText.contains(DEFAULT_TURKISH_MALE_VOICE_NAME) ||
            searchText.contains(" male") ||
            searchText.contains("_male") ||
            searchText.contains("-male") ||
            searchText.contains("erkek") ||
            searchText.contains("ahmet")
    }

    companion object {
        private const val CHANNEL_ID = "prayer_reminders_silent_v3"
        private val OLD_CHANNEL_IDS = arrayOf("prayer_reminders")
        private const val UTTERANCE_ID = "prayer_reminder_voice"
        private const val DEFAULT_TURKISH_MALE_VOICE_NAME = "tr-tr-x-tmc-network"
    }
}
