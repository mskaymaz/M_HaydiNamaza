package com.mskaymaz.mhaydinamaza

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.min

class PrayerVisualReminderActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private val blinkingViews = mutableListOf<TextView>()
    private var active = true
    private var blinkVisible = true

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prepareWindow()
        setContentView(buildContent())
        resizeDialogWindow()
        startBlinkLoop()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handler.removeCallbacksAndMessages(null)
        setIntent(intent)
        active = true
        blinkVisible = true
        blinkingViews.clear()
        setContentView(buildContent())
        resizeDialogWindow()
        startBlinkLoop()
    }

    override fun onDestroy() {
        active = false
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            keyCode == KeyEvent.KEYCODE_VOLUME_DOWN
        ) {
            stopAllWarnings()
            return true
        }
        return super.onKeyDown(keyCode, event)
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
            addView(hintView())
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
            setPadding(0, dp(14), 0, dp(8))
            blinkingViews.add(this)
        }
    }

    private fun hintView(): TextView {
        return TextView(this).apply {
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(90, 90, 90))
            textSize = 12.5f
            text = "Ses tuşları da uyarıyı kapatır."
            includeFontPadding = true
            setPadding(0, 0, 0, dp(14))
        }
    }

    private fun closeButton(): Button {
        return Button(this).apply {
            text = "Uyarıyı Kapat"
            setOnClickListener { stopAllWarnings() }
        }
    }

    private fun startBlinkLoop() {
        if (!intent.getBooleanExtra("visualEnabled", false)) return
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

    private fun stopAllWarnings() {
        active = false
        handler.removeCallbacksAndMessages(null)
        try {
            val stopIntent = PrayerActiveReminderService.stopIntent(this)
            startService(stopIntent)
        } catch (_: Exception) {
        }
        finish()
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }
}
