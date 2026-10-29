package com.scrollcount.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import com.scrollcount.app.data.ScrollRepository
import com.scrollcount.app.data.SettingsStore
import com.scrollcount.app.util.DateUtils
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers

/**
 * AppWidgetProvider for the home screen widget.
 * M1 Skeleton - basic structure, will be fully implemented in M6.
 */
class ScrollCountWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        // Perform initial update
        WidgetUpdater.forceUpdateAllWidgets(context)
        // Schedule day rollover alarm
        WidgetUpdater.scheduleDayRolloverAlarm(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        when (action) {
            "android.intent.action.DATE_CHANGED",
            "android.intent.action.TIMEZONE_CHANGED",
            "android.intent.action.BOOT_COMPLETED",
            "com.scrollcount.app.ACTION_DAY_ROLLOVER" -> {
                // Day boundary changed - force update
                WidgetUpdater.forceUpdateAllWidgets(context)
                WidgetUpdater.scheduleDayRolloverAlarm(context)
            }
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // First widget created - schedule alarm
        WidgetUpdater.scheduleDayRolloverAlarm(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Last widget removed - cancel alarm
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        val intent = Intent(context, ScrollCountWidgetProvider::class.java).apply {
            action = "com.scrollcount.app.ACTION_DAY_ROLLOVER"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        // Widget resized - update with appropriate layout
        WidgetUpdater.requestUpdate(context)
    }
}