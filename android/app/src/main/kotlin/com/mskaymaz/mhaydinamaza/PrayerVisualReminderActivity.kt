package com.mskaymaz.mhaydinamaza

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.util.Locale
import kotlin.math.min

class PrayerVisualReminderActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private val blinkingViews = mutableListOf<TextView>()
    private var active = true
    private var blinkVisible = true
    private var tts: TextToSpeech? = null
    private var vibrator: Vibrator? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prepareWindow()
        setContentView(buildContent())
        resizeDialogWindow()
        startActiveWarnings()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        stopActiveWarnings(cancelNotification = false)
        setIntent(intent)
        active = true
        blinkVisible = true
        blinkingViews.clear()
        setContentView(buildContent())
        resizeDialogWindow()
        startActiveWarnings()
    }

    override fun onDestroy() {
        stopActiveWarnings(cancelNotification = false)
        super.onDestroy()
    }

    private fun prepareWindow() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DIM_BEHIND
        )
        window.attributes = window.attributes.apply { dimAmount = 0.42f }
    }

    private fun resizeDialogWindow() {
        val width = min(resources.displayMetrics.widthPixels - dp(48), dp(360))
        window.setGravity(Gravity.CENTER)
        window.setLayout(width, WindowManager.LayoutParams.WRAP_CONTENT)
    }

    private fun buildContent(): LinearLayout {
        val title = intent.getStringExtra("title") ?: "Namaz vakti"
        val message = intent.getStringExtra("message") ?: "Namaz vakti"
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(22), dp(20), dp(22), dp(18))
            background = cardBackground()
            addView(titleView(title))
            addView(messageView(message))
            addView(closeButton())
        }
    }

    private fun cardBackground(): GradientDrawable {
        return GradientDrawable().apply {
            setColor(Color.WHITE)
            cornerRadius = dp(22).toFloat()
            setStroke(dp(2), Color.rgb(198, 24, 24))
        }
    }

    private fun titleView(text: String): TextView {
        return TextView(this).apply {
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(25, 70, 25))
            textSize = 24f
            typeface = Typeface.DEFAULT_BOLD
            this.text = text
            includeFontPadding = true
            blinkingViews.add(this)
        }
    }

    private fun messageView(text: String): TextView {
        return TextView(this).apply {
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(30, 30, 30))
            textSize = 18f
            this.text = text
            includeFontPadding = true
            setPadding(0, dp(14), 0, dp(18))
            blinkingViews.add(this)
        }
    }

    private fun closeButton(): Button {
        return Button(this).apply {
            text = "Uyarıyı Kapat"
            setOnClickListener {
                stopActiveWarnings(cancelNotification = true)
                finish()
            }
        }
    }

    private fun startActiveWarnings() {
        if (intent.getBooleanExtra("visualEnabled", false)) startBlinkLoop()
        if (intent.getBooleanExtra("vibrationEnabled", false)) startVibrationLoop()
        if (intent.getBooleanExtra("voiceEnabled", false) ||
            intent.getBooleanExtra("azanEnabled", false)
        ) {
            startVoiceLoop()
        }
    }

    private fun startBlinkLoop() {
        handler.post(object : Runnable {
            override fun run() {
                if (!active) return
                blinkVisible = !blinkVisible
                val alpha = if (blinkVisible) 1.0f else 0.18f
                blinkingViews.forEach { it.alpha = alpha }
                handler.postDelayed(this, 650L)
            }
        })
    }

    private fun startVibrationLoop() {
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

    private fun startVoiceLoop() {
        val isAzan = intent.getBooleanExtra("azanEnabled", false)
        val text = if (isAzan) {
            "Ezan okunuyor"
        } else {
            val prayerLabel = intent.getStringExtra("prayerLabel") ?: "Vakit"
            val message = intent.getStringExtra("message") ?: "Namaz vakti"
            "$prayerLabel vakti. $message"
        }
        val repeatMillis = if (isAzan) {
            5000L
        } else {
            readFlutterInt("reminder_voice_repeat_seconds", 15)
                .coerceIn(1, 3600) * 1000L
        }
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

    private fun stopActiveWarnings(cancelNotification: Boolean) {
        if (!active) return
        active = false
        handler.removeCallbacksAndMessages(null)
        try { vibrator?.cancel() } catch (_: Exception) {}
        try { tts?.stop() } catch (_: Exception) {}
        try { tts?.shutdown() } catch (_: Exception) {}
        if (cancelNotification) cancelNotification()
    }

    private fun cancelNotification() {
        val id = intent.getIntExtra("notificationId", 0)
        if (id == 0) return
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancel(id)
        } catch (_: Exception) {
        }
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

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    companion object {
        private const val DEFAULT_TURKISH_MALE_VOICE_NAME = "tr-tr-x-tmc-network"
    }
}
