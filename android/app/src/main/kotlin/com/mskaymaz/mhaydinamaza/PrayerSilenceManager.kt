package com.mskaymaz.mhaydinamaza

import android.app.NotificationManager
import android.content.Context
import android.media.AudioManager
import android.os.Build

object PrayerSilenceManager {
    private const val PREFS_NAME = "prayer_silence_state"
    private const val ACTIVE_COUNT_KEY = "active_count"
    private const val PREVIOUS_RINGER_MODE_KEY = "previous_ringer_mode"
    private const val PREVIOUS_INTERRUPTION_FILTER_KEY = "previous_interruption_filter"

    fun start(context: Context) {
        val prefs = prefs(context)
        val activeCount = prefs.getInt(ACTIVE_COUNT_KEY, 0)
        if (activeCount == 0) {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            prefs.edit()
                .putInt(PREVIOUS_RINGER_MODE_KEY, audioManager.ringerMode)
                .apply()
            saveInterruptionFilter(context, prefs)
        }
        prefs.edit().putInt(ACTIVE_COUNT_KEY, activeCount + 1).apply()
        applySilentMode(context)
    }

    fun end(context: Context) {
        val prefs = prefs(context)
        val activeCount = prefs.getInt(ACTIVE_COUNT_KEY, 0)
        if (activeCount <= 1) {
            restoreNow(context)
            return
        }
        prefs.edit().putInt(ACTIVE_COUNT_KEY, activeCount - 1).apply()
    }

    fun restoreNow(context: Context) {
        val prefs = prefs(context)
        if (prefs.getInt(ACTIVE_COUNT_KEY, 0) <= 0) return
        restorePreviousMode(context, prefs)
        prefs.edit()
            .remove(ACTIVE_COUNT_KEY)
            .remove(PREVIOUS_RINGER_MODE_KEY)
            .remove(PREVIOUS_INTERRUPTION_FILTER_KEY)
            .apply()
    }

    private fun applySilentMode(context: Context) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
        } catch (_: SecurityException) {
            try {
                val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
            } catch (_: Exception) {
            }
        } catch (_: Exception) {
        }
        try {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                manager.isNotificationPolicyAccessGranted
            ) {
                manager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
            }
        } catch (_: SecurityException) {
        } catch (_: Exception) {
        }
    }

    private fun restorePreviousMode(
        context: Context,
        prefs: android.content.SharedPreferences,
    ) {
        try {
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (prefs.contains(PREVIOUS_RINGER_MODE_KEY)) {
                audioManager.ringerMode = prefs.getInt(
                    PREVIOUS_RINGER_MODE_KEY,
                    AudioManager.RINGER_MODE_NORMAL,
                )
            }
        } catch (_: SecurityException) {
        } catch (_: Exception) {
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
            if (manager.isNotificationPolicyAccessGranted &&
                prefs.contains(PREVIOUS_INTERRUPTION_FILTER_KEY)
            ) {
                manager.setInterruptionFilter(
                    prefs.getInt(
                        PREVIOUS_INTERRUPTION_FILTER_KEY,
                        NotificationManager.INTERRUPTION_FILTER_ALL,
                    ),
                )
            }
        } catch (_: SecurityException) {
        } catch (_: Exception) {
        }
    }

    private fun saveInterruptionFilter(
        context: Context,
        prefs: android.content.SharedPreferences,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
            if (manager.isNotificationPolicyAccessGranted) {
                prefs.edit()
                    .putInt(
                        PREVIOUS_INTERRUPTION_FILTER_KEY,
                        manager.currentInterruptionFilter,
                    )
                    .apply()
            }
        } catch (_: Exception) {
        }
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
