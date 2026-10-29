package com.scrollcount.app.util

import android.content.Context
import com.scrollcount.app.data.SettingsStore
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Utilities for logical day calculations with custom reset hour.
 */
object DateUtils {

    private const val DATE_FORMAT = "yyyy-MM-dd"

    /**
     * Get the current logical day key (yyyy-MM-dd) based on the reset hour setting.
     * Times before resetHour count toward the previous day.
     */
    fun getCurrentLogicalDay(context: Context): String {
        val resetHour = SettingsStore.getResetHour(context)
        return getLogicalDay(System.currentTimeMillis(), resetHour)
    }

    /**
     * Get logical day key for a given timestamp and reset hour.
     */
    fun getLogicalDay(timestamp: Long, resetHour: Int): String {
        val cal = Calendar.getInstance(TimeZone.getDefault(), Locale.getDefault())
        cal.timeInMillis = timestamp
        if (cal.get(Calendar.HOUR_OF_DAY) < resetHour) {
            cal.add(Calendar.DAY_OF_MONTH, -1)
        }
        return SimpleDateFormat(DATE_FORMAT, Locale.getDefault()).format(cal.time)
    }

    /**
     * Get the timestamp of the next logical day boundary (reset hour).
     */
    fun getNextDayBoundary(context: Context): Long {
        val resetHour = SettingsStore.getResetHour(context)
        val cal = Calendar.getInstance(TimeZone.getDefault(), Locale.getDefault())
        cal.timeInMillis = System.currentTimeMillis()
        if (cal.get(Calendar.HOUR_OF_DAY) >= resetHour) {
            cal.add(Calendar.DAY_OF_MONTH, 1)
        }
        cal.set(Calendar.HOUR_OF_DAY, resetHour)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }

    /**
     * Format a day key (yyyy-MM-dd) for display.
     */
    fun formatDayForDisplay(dayKey: String): String {
        try {
            val date = SimpleDateFormat(DATE_FORMAT, Locale.getDefault()).parse(dayKey)
            return SimpleDateFormat("EEE, MMM d", Locale.getDefault()).format(date!!)
        } catch (e: Exception) {
            return dayKey
        }
    }

    /**
     * Check if a day key is today (logical day).
     */
    fun isToday(context: Context, dayKey: String): Boolean {
        return dayKey == getCurrentLogicalDay(context)
    }

    /**
     * Get day key for N days ago.
     */
    fun getDayKeyDaysAgo(context: Context, daysAgo: Int): String {
        val cal = Calendar.getInstance(TimeZone.getDefault(), Locale.getDefault())
        val resetHour = SettingsStore.getResetHour(context)
        cal.timeInMillis = System.currentTimeMillis()
        if (cal.get(Calendar.HOUR_OF_DAY) < resetHour) {
            cal.add(Calendar.DAY_OF_MONTH, -1)
        }
        cal.add(Calendar.DAY_OF_MONTH, -daysAgo)
        cal.set(Calendar.HOUR_OF_DAY, resetHour)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return SimpleDateFormat(DATE_FORMAT, Locale.getDefault()).format(cal.time)
    }
}