package com.mskaymaz.mhaydinamaza

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.media.MediaPlayer
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.util.Locale

class PrayerActiveReminderService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var active = false
    private var notificationId = 0
    private var tts: TextToSpeech? = null
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopActiveReminder(cancelNotification = true)
            stopSelf()
            return START_NOT_STICKY
        }
        if (intent == null) return START_NOT_STICKY
        startActiveReminder(intent)
        return START_STICKY
    }

    override fun onDestroy() {
        stopActiveReminder(cancelNotification = false)
        super.onDestroy()
    }

    private fun startActiveReminder(intent: Intent) {
        stopActiveReminder(cancelNotification = false)
        active = true
        notificationId = intent.getIntExtra("id", 0)
        if (notificationId == 0) notificationId = NOTIFICATION_ID_FALLBACK
        startForeground(notificationId, buildNotification(intent))
        if (intent.getBooleanExtra("vibrationEnabled", false)) startVibrationLoop(intent)
        if (intent.getBooleanExtra("azanEnabled", false)) startAzanPlayback()
        if (intent.getBooleanExtra("voiceEnabled", false)) startVoiceLoop(intent)
    }

    private fun buildNotification(intent: Intent): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureChannel(manager)
        val title = intent.getStringExtra("title") ?: "Namaz vakti"
        val message = intent.getStringExtra("message") ?: "Namaz vakti"
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            notificationId + 710000,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val stopPendingIntent = PendingIntent.getService(
            this,
            notificationId + 720000,
            stopIntent(this),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(Notification.BigTextStyle().bigText(message))
            .setAutoCancel(false)
            .setOngoing(true)
            .setContentIntent(contentPendingIntent)
            .addAction(R.mipmap.ic_launcher, "Kapat", stopPendingIntent)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setWhen(intent.getLongExtra("triggerAtMillis", System.currentTimeMillis()))
            .setShowWhen(true)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_HIGH)
        }
        @Suppress("DEPRECATION")
        builder.setSound(null)
        @Suppress("DEPRECATION")
        builder.setDefaults(0)
        return builder.build()
    }

    private fun startVibrationLoop(intent: Intent) {
        val duration = intent.getIntExtra("vibrationDurationMs", 3000)
            .coerceIn(100, 60_000)
        val pause = readFlutterInt("reminder_vibration_pause_seconds", 5)
            .coerceIn(0, 3600) * 1000
        fun pulse() {
            if (!active) return
            vibrate(duration)
            handler.postDelayed({ pulse() }, (duration + pause).toLong())
        }
        pulse()
    }

    private fun vibrate(durationMs: Int) {
        try {
            val target = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                    as VibratorManager
                manager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            vibrator = target
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                target.vibrate(
                    VibrationEffect.createOneShot(
                        durationMs.toLong(),
                        VibrationEffect.DEFAULT_AMPLITUDE
                    )
                )
            } else {
                @Suppress("DEPRECATION")
                target.vibrate(durationMs.toLong())
            }
        } catch (_: Exception) {
        }
    }

    private fun startAzanPlayback() {
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer.create(this, R.raw.default_azan)?.apply {
                setOnCompletionListener { player ->
                    try { player.release() } catch (_: Exception) {}
                    if (mediaPlayer === player) mediaPlayer = null
                }
                start()
            }
        } catch (_: Exception) {
        }
    }

    private fun startVoiceLoop(intent: Intent) {
        val prayerLabel = intent.getStringExtra("prayerLabel") ?: "Vakit"
        val message = intent.getStringExtra("message") ?: "Namaz vakti"
        val text = "$prayerLabel vakti. $message"
        val repeatMillis = readFlutterInt("reminder_voice_repeat_seconds", 15)
            .coerceIn(1, 3600) * 1000L
        tts = TextToSpeech(applicationContext) { status ->
            if (!active || status != TextToSpeech.SUCCESS) return@TextToSpeech
            val engine = tts ?: return@TextToSpeech
            if (!applyMaleTurkishVoice(engine)) return@TextToSpeech
            engine.setSpeechRate(0.52f)
            engine.setPitch(1.0f)
            engine.setOnUtteranceProgressListener(
                object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) = Unit
                    override fun onDone(utteranceId: String?) {
                        if (active) handler.postDelayed({ speakOnce(text) }, repeatMillis)
                    }
                    @Deprecated("Deprecated in Java")
                    override fun onError(utteranceId: String?) = Unit
                    override fun onError(utteranceId: String?, errorCode: Int) = Unit
                }
            )
            speakOnce(text)
        }
    }

    private fun speakOnce(text: String) {
        val engine = tts ?: return
        if (!active) return
        val utteranceId = "prayer_active_reminder_${System.currentTimeMillis()}"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            engine.speak(text, TextToSpeech.QUEUE_FLUSH, Bundle(), utteranceId)
        } else {
            @Suppress("DEPRECATION")
            engine.speak(
                text,
                TextToSpeech.QUEUE_FLUSH,
                hashMapOf(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID to utteranceId)
            )
        }
    }

    private fun applyMaleTurkishVoice(engine: TextToSpeech): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return false
        val voices = try { engine.voices } catch (_: Exception) { null } ?: return false
        val selectedVoice = voices.firstOrNull { voice ->
            val name = voice.name.lowercase(Locale.US)
            isTurkishVoice(name, voice.locale) && name == DEFAULT_TURKISH_MALE_VOICE_NAME
        } ?: voices.firstOrNull { voice ->
            isTurkishVoice(voice.name, voice.locale) &&
                voiceLooksMale(voice.name, voice.features)
        } ?: return false
        return try {
            val languageResult = engine.setLanguage(selectedVoice.locale)
            if (languageResult == TextToSpeech.LANG_MISSING_DATA ||
                languageResult == TextToSpeech.LANG_NOT_SUPPORTED
            ) {
                false
            } else {
                engine.setVoice(selectedVoice) == TextToSpeech.SUCCESS
            }
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

    private fun stopActiveReminder(cancelNotification: Boolean) {
        if (!active && !cancelNotification) return
        active = false
        handler.removeCallbacksAndMessages(null)
        try { vibrator?.cancel() } catch (_: Exception) {}
        try { tts?.stop() } catch (_: Exception) {}
        try { tts?.shutdown() } catch (_: Exception) {}
        try { mediaPlayer?.stop() } catch (_: Exception) {}
        try { mediaPlayer?.release() } catch (_: Exception) {}
        tts = null
        mediaPlayer = null
        vibrator = null
        if (cancelNotification) cancelNotification()
    }

    private fun cancelNotification() {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancel(notificationId)
        } catch (_: Exception) {
        }
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        for (oldChannelId in OLD_CHANNEL_IDS) {
            try { manager.deleteNotificationChannel(oldChannelId) } catch (_: Exception) {}
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

    private fun readFlutterInt(key: String, fallback: Int): Int {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val value = prefs.all["flutter.$key"] ?: return fallback
        return when (value) {
            is Int -> value
            is Long -> value.toInt()
            is Float -> value.toInt()
            is Double -> value.toInt()
            is String -> value.toIntOrNull() ?: fallback
            else -> fallback
        }
    }

    companion object {
        const val ACTION_STOP = "com.mskaymaz.mhaydinamaza.PRAYER_ACTIVE_REMINDER_STOP"
        const val CHANNEL_ID = "prayer_reminders_active_v6"
        private const val DEFAULT_TURKISH_MALE_VOICE_NAME = "tr-tr-x-tmc-network"
        private const val NOTIFICATION_ID_FALLBACK = 100700
        private val OLD_CHANNEL_IDS = arrayOf(
            "prayer_reminders",
            "prayer_reminders_silent_v3",
            "prayer_reminders_active_v5"
        )

        fun startIntent(context: Context, sourceIntent: Intent): Intent {
            return Intent(context, PrayerActiveReminderService::class.java).apply {
                putExtras(sourceIntent)
            }
        }

        fun stopIntent(context: Context): Intent {
            return Intent(context, PrayerActiveReminderService::class.java).apply {
                action = ACTION_STOP
            }
        }
    }
}
