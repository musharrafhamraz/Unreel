package com.scrollcount.app.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import com.scrollcount.app.data.ScrollRepository
import com.scrollcount.app.data.SettingsStore
import com.scrollcount.app.service.CountOverlay
import com.scrollcount.app.util.DateUtils
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Handles widget updates - throttled, screen-aware, with day rollover alarms.
 * M1 Skeleton - basic structure, will be fully implemented in M6.
 */
object WidgetUpdater {

    private const val UPDATE_THROTTLE_MS = 5000L
    private var lastUpdateTime = 0L

    /**
     * Request a widget update (throttled and screen-aware).
     */
    fun requestUpdate(context: Context) {
        val now = System.currentTimeMillis()
        if (now - lastUpdateTime < UPDATE_THROTTLE_MS) return

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        if (!powerManager.isInteractive) return

        lastUpdateTime = now
        performUpdate(context)
    }

    /**
     * Force immediate update (e.g., after data clear, day rollover).
     */
    fun forceUpdateAllWidgets(context: Context) {
        lastUpdateTime = 0
        performUpdate(context)
    }

    private fun performUpdate(context: Context) {
        CoroutineScope(Dispatchers.IO).launch {
            val todayData = ScrollRepository.getToday(context)
            val totalCount = (todayData["total"] as? Number)?.toInt() ?: 0
            CountOverlay.update(context, totalCount)

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val widgetIds = appWidgetManager.getAppWidgetIds(ComponentName(context, ScrollCountWidgetProvider::class.java))
            if (widgetIds.isEmpty()) return@launch
            val limit = SettingsStore.getGlobalLimit(context)
            val isServiceEnabled = SettingsStore.isAccessibilityServiceEnabled(context)

            widgetIds.forEach { widgetId ->
                val views = WidgetRenderer.buildViews(
                    context, widgetId, totalCount, limit, isServiceEnabled
                )
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        }
    }

    /**
     * Schedule the next day rollover alarm.
     */
    fun scheduleDayRolloverAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val nextBoundary = DateUtils.getNextDayBoundary(context)

        val intent = Intent(context, ScrollCountWidgetProvider::class.java).apply {
            action = "com.scrollcount.app.ACTION_DAY_ROLLOVER"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Cancel existing
        alarmManager.cancel(pendingIntent)

        // Set inexact alarm that fires at the day boundary
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, nextBoundary, pendingIntent)
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, nextBoundary, pendingIntent)
        }
    }

    /**
     * Check if the launcher supports pinning widgets.
     */
    fun isRequestPinSupported(context: Context): Boolean {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            appWidgetManager.isRequestPinAppWidgetSupported
        } else {
            false
        }
    }

    /**
     * Request to pin the widget to the home screen.
     */
    fun requestPinWidget(context: Context, activity: android.app.Activity?) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, ScrollCountWidgetProvider::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (appWidgetManager.isRequestPinAppWidgetSupported) {
                val successCallback = PendingIntent.getBroadcast(
                    context, 0,
                    Intent("com.scrollcount.app.WIDGET_PINNED"),
                    PendingIntent.FLAG_IMMUTABLE
                )
                val today = ScrollRepository.getToday(context)
                val total = (today["total"] as? Number)?.toInt() ?: 0
                val limit = SettingsStore.getGlobalLimit(context)
                val enabled = SettingsStore.isAccessibilityServiceEnabled(context)
                val preview = WidgetRenderer.buildViews(context, 0, total, limit, enabled)
                val extras = Bundle().apply {
                    putParcelable(AppWidgetManager.EXTRA_APPWIDGET_PREVIEW, preview)
                }
                appWidgetManager.requestPinAppWidget(componentName, extras, successCallback)
            }
        }
    }

    /**
     * Check if any widget instances exist.
     */
    fun hasWidgetInstances(context: Context): Boolean {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val widgetIds = appWidgetManager.getAppWidgetIds(ComponentName(context, ScrollCountWidgetProvider::class.java))
        return widgetIds.isNotEmpty()
    }
}