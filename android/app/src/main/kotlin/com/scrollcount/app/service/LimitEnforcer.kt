package com.scrollcount.app.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.scrollcount.app.data.SettingsStore
import com.scrollcount.app.ui.BlockActivity

/**
 * Enforces daily limits with warnings and blocking.
 * M1 Skeleton - basic structure, will be fully implemented in M2.
 */
class LimitEnforcer(private val context: Context) {

    private val NOTIFICATION_CHANNEL_ID = "limit_alerts"
    private val NOTIFICATION_ID_WARNING = 1001
    private val NOTIFICATION_ID_LIMIT = 1002

    private var warned80Percent = false
    private var warned100Percent = false
    private var isBlocked = false

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Limit Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications when you approach or hit your daily reel limit"
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    /**
     * Call when count changes to check limits.
     */
    fun onCountChanged(appId: String, newCount: Int, totalToday: Int) {
        val globalLimit = SettingsStore.getGlobalLimit(context)
        val perAppLimit = SettingsStore.getPerAppLimit(context, appId)
        val effectiveLimit = if (perAppLimit > 0) perAppLimit else globalLimit

        if (effectiveLimit <= 0) {
            // No limit set
            resetWarnings()
            return
        }

        val warnAtPercent = SettingsStore.getWarnAtPercent(context)
        val warnThreshold = (effectiveLimit * warnAtPercent / 100)

        // Check 80% warning
        if (!warned80Percent && totalToday >= warnThreshold) {
            warned80Percent = true
            showWarningNotification(totalToday, effectiveLimit)
        }

        // Check 100% limit
        if (!warned100Percent && totalToday >= effectiveLimit) {
            warned100Percent = true
            isBlocked = true
            showLimitNotification(totalToday, effectiveLimit)
            enforceBlock()
        }
    }

    private fun showWarningNotification(current: Int, limit: Int) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setContentTitle("Reel Limit Warning")
            .setContentText("You've watched $current of $limit reels today (${SettingsStore.getWarnAtPercent(context)}%)")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
        manager.notify(NOTIFICATION_ID_WARNING, builder.build())
    }

    private fun showLimitNotification(current: Int, limit: Int) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Daily Limit Reached")
            .setContentText("You've hit your limit of $limit reels for today")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setAutoCancel(false)
        manager.notify(NOTIFICATION_ID_LIMIT, builder.build())
    }

    private fun enforceBlock() {
        if (!SettingsStore.isBlockingEnabled(context)) return
        // BlockActivity will be launched from AccessibilityService when reels screen is detected
    }

    /**
     * Check if currently blocked and should enforce.
     */
    fun shouldBlock(appId: String): Boolean {
        if (!isBlocked) return false
        if (!SettingsStore.isBlockingEnabled(context)) return false

        val globalLimit = SettingsStore.getGlobalLimit(context)
        val perAppLimit = SettingsStore.getPerAppLimit(context, appId)
        val effectiveLimit = if (perAppLimit > 0) perAppLimit else globalLimit

        return effectiveLimit > 0
    }

    /**
     * Perform the blocking action (back/home).
     */
    fun performBlockAction(service: android.accessibilityservice.AccessibilityService) {
        service.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK)
        // TODO: If still on reels after 500ms, perform HOME
    }

    /**
     * Show the block screen.
     */
    fun showBlockScreen() {
        val intent = Intent(context, BlockActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        }
        context.startActivity(intent)
    }

    private fun resetWarnings() {
        warned80Percent = false
        warned100Percent = false
        isBlocked = false
    }

    /**
     * Call at day rollover to reset state.
     */
    fun onDayRollover() {
        resetWarnings()
    }
}