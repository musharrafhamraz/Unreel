package com.scrollcount.app.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.scrollcount.app.R

/**
 * System notifications. The in-app snackbar is separate and easy to mistake
 * for a notification on this phone.
 */
object Notifier {
    const val ALERTS_CHANNEL_ID = "scrollcount_alerts"
    private const val COUNTER_CHANNEL_ID = "scrollcount_counter"
    const val COUNTER_NOTIFICATION_ID = 42

    fun notificationsAllowed(context: Context): Boolean {
        val manager = manager(context)
        return manager.areNotificationsEnabled()
    }

    fun showTest(context: Context, title: String, body: String, id: Int): Boolean {
        if (!notificationsAllowed(context)) return false
        ensureAlertsChannel(context)
        val notification = NotificationCompat.Builder(context, ALERTS_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setDefaults(Notification.DEFAULT_ALL)
            .setColor(0xFF4F46E5.toInt())
            .build()
        manager(context).notify(id, notification)
        return true
    }

    fun counterNotification(context: Context): Notification {
        ensureCounterChannel(context)
        return NotificationCompat.Builder(context, COUNTER_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_notify)
            .setContentTitle("Unreel is counting")
            .setContentText("Reel counting stays on while the app is closed")
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    fun ensureAlertsChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = manager(context)
        val existing = manager.getNotificationChannel(ALERTS_CHANNEL_ID)
        if (existing != null && existing.importance < NotificationManager.IMPORTANCE_HIGH) {
            manager.deleteNotificationChannel(ALERTS_CHANNEL_ID)
        }
        // Older test channels were created too quietly, and Android will not raise them.
        manager.deleteNotificationChannel("cognitive_reset_test")
        val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .build()
        val channel = NotificationChannel(
            ALERTS_CHANNEL_ID,
            "Unreel reminders",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Task reminders and the test button"
            enableVibration(true)
            setSound(sound, audio)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    private fun ensureCounterChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            COUNTER_CHANNEL_ID,
            "Counting",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows that reel counting is still running"
            setSound(null, null)
            enableVibration(false)
        }
        manager(context).createNotificationChannel(channel)
    }

    private fun manager(context: Context): NotificationManager {
        return context.getSystemService(NotificationManager::class.java)
    }
}
