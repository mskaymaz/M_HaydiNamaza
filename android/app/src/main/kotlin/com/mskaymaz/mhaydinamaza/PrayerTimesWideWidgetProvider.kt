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
import java.util.Calendar

class PrayerTimesWideWidgetProvider : AppWidgetProvider() {
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
            val views = RemoteViews(context.packageName, R.layout.prayer_times_wide_widget)
            val next = PrayerWidgetScheduler.nextEvent(context)
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            val contentIntent = PendingIntent.getActivity(
                context,
                9922,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.prayer_wide_widget_root, contentIntent)

            if (next == null) {
                bindEmpty(views)
                return views
            }

            views.setTextViewText(R.id.prayer_wide_date, next.dateLabel.ifBlank { "Bugünün vakitleri" })
            views.setTextViewText(R.id.prayer_wide_fajr_time, next.fajrTime)
            views.setTextViewText(R.id.prayer_wide_sunrise_time, next.sunriseTime)
            views.setTextViewText(R.id.prayer_wide_dhuhr_time, next.dhuhrTime)
            views.setTextViewText(R.id.prayer_wide_asr_time, next.asrTime)
            views.setTextViewText(R.id.prayer_wide_maghrib_time, next.maghribTime)
            views.setTextViewText(R.id.prayer_wide_isha_time, next.ishaTime)
            bindActiveCell(views, next)
            views.setTextViewText(
                R.id.prayer_wide_remaining_label,
                "${next.prayerLabel} vaktine kalan süre:"
            )
            views.setViewVisibility(R.id.prayer_wide_countdown, View.VISIBLE)
            val remaining = next.triggerAtMillis - System.currentTimeMillis()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val base = SystemClock.elapsedRealtime() + remaining
                views.setChronometer(R.id.prayer_wide_countdown, base, null, true)
                views.setChronometerCountDown(R.id.prayer_wide_countdown, true)
            } else {
                views.setTextViewText(R.id.prayer_wide_countdown, formatRemaining(remaining))
            }
            return views
        }

        private fun bindEmpty(views: RemoteViews) {
            views.setTextViewText(R.id.prayer_wide_date, "Bugünün vakitleri")
            views.setTextViewText(R.id.prayer_wide_fajr_time, "--:--")
            views.setTextViewText(R.id.prayer_wide_sunrise_time, "--:--")
            views.setTextViewText(R.id.prayer_wide_dhuhr_time, "--:--")
            views.setTextViewText(R.id.prayer_wide_asr_time, "--:--")
            views.setTextViewText(R.id.prayer_wide_maghrib_time, "--:--")
            views.setTextViewText(R.id.prayer_wide_isha_time, "--:--")
            hideActiveIndicators(views)
            views.setTextViewText(R.id.prayer_wide_remaining_label, "Kalan süre:")
            views.setTextViewText(R.id.prayer_wide_countdown, "--:--:--")
        }

        private fun bindActiveCell(
            views: RemoteViews,
            event: PrayerWidgetScheduler.WidgetEvent
        ) {
            hideActiveIndicators(views)
            val activeId = activeIndicatorId(event) ?: return
            views.setViewVisibility(activeId, View.VISIBLE)
        }

        private fun hideActiveIndicators(views: RemoteViews) {
            val ids = intArrayOf(
                R.id.prayer_wide_active_indicator_fajr,
                R.id.prayer_wide_active_indicator_sunrise,
                R.id.prayer_wide_active_indicator_dhuhr,
                R.id.prayer_wide_active_indicator_asr,
                R.id.prayer_wide_active_indicator_maghrib,
                R.id.prayer_wide_active_indicator_isha
            )
            for (id in ids) {
                views.setViewVisibility(id, View.GONE)
            }
        }

        private fun activeIndicatorId(event: PrayerWidgetScheduler.WidgetEvent): Int? {
            val fajr = minuteOfDay(event.fajrTime) ?: return null
            val sunrise = minuteOfDay(event.sunriseTime) ?: return null
            val dhuhr = minuteOfDay(event.dhuhrTime) ?: return null
            val asr = minuteOfDay(event.asrTime) ?: return null
            val maghrib = minuteOfDay(event.maghribTime) ?: return null
            val isha = minuteOfDay(event.ishaTime) ?: return null
            val now = Calendar.getInstance()
            val current = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
            return when {
                current >= isha -> R.id.prayer_wide_active_indicator_isha
                current >= maghrib -> R.id.prayer_wide_active_indicator_maghrib
                current >= asr -> R.id.prayer_wide_active_indicator_asr
                current >= dhuhr -> R.id.prayer_wide_active_indicator_dhuhr
                current >= sunrise -> R.id.prayer_wide_active_indicator_sunrise
                current >= fajr -> R.id.prayer_wide_active_indicator_fajr
                else -> R.id.prayer_wide_active_indicator_fajr
            }
        }

        private fun minuteOfDay(time: String): Int? {
            val parts = time.split(":")
            if (parts.size < 2) return null
            val hour = parts[0].toIntOrNull() ?: return null
            val minute = parts[1].toIntOrNull() ?: return null
            return (hour * 60) + minute
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
