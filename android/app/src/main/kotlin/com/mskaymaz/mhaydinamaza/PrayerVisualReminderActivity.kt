package com.mskaymaz.mhaydinamaza

import android.app.Activity
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class PrayerVisualReminderActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prepareWindow()
        setContentView(buildContent())
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
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun buildContent(): LinearLayout {
        val title = intent.getStringExtra("title") ?: "Namaz vakti"
        val message = intent.getStringExtra("message") ?: "Namaz vakti"
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(22), dp(22), dp(22), dp(22))
            setBackgroundColor(Color.argb(210, 0, 0, 0))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(22), dp(20), dp(22), dp(18))
            background = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dp(22).toFloat()
            }
        }
        card.addView(titleView(title))
        card.addView(messageView(message))
        card.addView(closeButton())
        root.addView(
            card,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        )
        return root
    }

    private fun titleView(text: String): TextView {
        return TextView(this).apply {
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(25, 70, 25))
            textSize = 24f
            typeface = Typeface.DEFAULT_BOLD
            this.text = text
            includeFontPadding = true
        }
    }

    private fun messageView(text: String): TextView {
        return TextView(this).apply {
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(30, 30, 30))
            textSize = 18f
            this.text = text
            includeFontPadding = true
            setPadding(0, dp(14), 0, dp(16))
        }
    }

    private fun closeButton(): Button {
        return Button(this).apply {
            text = "Kapat"
            setOnClickListener { finish() }
        }
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }
}
