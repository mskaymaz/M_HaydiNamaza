package com.mskaymaz.mhaydinamaza

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews

class PrayerTimeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateAll(context, appWidgetManager, appWidgetIds)
        PrayerWidgetScheduler.updateWidgets(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            PrayerWidgetScheduler.ACTION_REFRESH,
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> PrayerWidgetScheduler.updateWidgets(context)
        }
    }

    companion object {
        fun updateAll(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            for (id in appWidgetIds) {
                appWidgetManager.updateAppWidget(id, buildViews(context))
            }
        }

        private fun buildViews(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.prayer_time_widget)
            val next = PrayerWidgetScheduler.nextEvent(context)
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            val contentIntent = PendingIntent.getActivity(
                context,
                9921,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.prayer_widget_root, contentIntent)

            if (next == null) {
                views.setTextViewText(R.id.prayer_widget_label, "Vakit")
                views.setTextViewText(R.id.prayer_widget_time, "--:--")
                views.setViewVisibility(R.id.prayer_widget_countdown, View.VISIBLE)
                views.setTextViewText(R.id.prayer_widget_remaining_label, "Kalan Süre")
                views.setTextViewText(R.id.prayer_widget_countdown, "--:--:--")
                return views
            }

            views.setTextViewText(R.id.prayer_widget_label, next.remainingPrayerLabel)
            views.setTextViewText(R.id.prayer_widget_time, next.timeLabel)
            views.setTextViewText(R.id.prayer_widget_remaining_label, "Kalan Süre")
            views.setViewVisibility(R.id.prayer_widget_countdown, View.VISIBLE)

            val remaining = next.remainingTriggerAtMillis - System.currentTimeMillis()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val base = SystemClock.elapsedRealtime() + remaining
                views.setChronometer(R.id.prayer_widget_countdown, base, null, true)
                views.setChronometerCountDown(R.id.prayer_widget_countdown, true)
            } else {
                views.setTextViewText(
                    R.id.prayer_widget_countdown,
                    formatRemaining(remaining)
                )
            }
            return views
        }

        private fun formatRemaining(remainingMillis: Long): String {
            val totalSeconds = (remainingMillis.coerceAtLeast(0L) / 1000L)
            val hours = totalSeconds / 3600L
            val minutes = (totalSeconds % 3600L) / 60L
            val seconds = totalSeconds % 60L
            return "${hours.toString().padStart(2, '0')}:${
                minutes.toString().padStart(2, '0')
            }:${seconds.toString().padStart(2, '0')}"
        }
    }
}
