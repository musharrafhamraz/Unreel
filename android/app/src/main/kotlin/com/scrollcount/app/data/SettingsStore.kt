package com.scrollcount.app.data

import android.content.Context
import android.content.SharedPreferences
import android.provider.Settings
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.scrollcount.app.util.DateUtils
import java.lang.reflect.Type

/**
 * Wrapper around SharedPreferences for all app settings.
 * Native-side only - Flutter reads/writes via platform channel.
 */
object SettingsStore {

    private const val PREFS_NAME = "scrollcount_settings"
    private const val KEY_GLOBAL_LIMIT = "global_limit"
    private const val KEY_PER_APP_LIMITS = "per_app_limits"
    private const val KEY_TRACKED_APPS = "tracked_apps"
    private const val KEY_BLOCKING_ENABLED = "blocking_enabled"
    private const val KEY_STRICT_MODE = "strict_mode"
    private const val KEY_SNOOZE_MINUTES = "snooze_minutes"
    private const val KEY_RESET_HOUR = "reset_hour"
    private const val KEY_WARN_AT_PERCENT = "warn_at_percent"
    private const val KEY_OVERLAY_MODE = "overlay_mode"
    private const val KEY_THEME_MODE = "theme_mode"
    private const val KEY_ONBOARDING_COMPLETED = "onboarding_completed"
    private const val KEY_STRICT_LOCK_UNTIL = "strict_lock_until"
    private const val KEY_NOTIFICATION_PERMISSION_GRANTED = "notification_permission_granted"

    private val gson = Gson()
    private val typeToken = object : TypeToken<Map<String, Int>>() {}.type

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    // Default settings
    private val defaultTrackedApps = listOf("instagram", "youtube_shorts", "facebook_reels", "snapchat")
    private val defaultPerAppLimits = mapOf(
        "instagram" to 0,
        "youtube_shorts" to 0,
        "facebook_reels" to 0,
        "snapchat" to 0
    )

    fun getAllSettings(context: Context): Map<String, Any> {
        val prefs = getPrefs(context)
        return mapOf(
            "globalLimit" to prefs.getInt(KEY_GLOBAL_LIMIT, 100),
            "perAppLimits" to (gson.fromJson(prefs.getString(KEY_PER_APP_LIMITS, gson.toJson(defaultPerAppLimits)), typeToken) ?: defaultPerAppLimits),
            "trackedApps" to getTrackedApps(context),
            "blockingEnabled" to prefs.getBoolean(KEY_BLOCKING_ENABLED, true),
            "strictMode" to prefs.getBoolean(KEY_STRICT_MODE, false),
            "snoozeMinutes" to prefs.getInt(KEY_SNOOZE_MINUTES, 5),
            "resetHour" to prefs.getInt(KEY_RESET_HOUR, 0),
            "warnAtPercent" to prefs.getInt(KEY_WARN_AT_PERCENT, 80),
            "overlayMode" to prefs.getBoolean(KEY_OVERLAY_MODE, false),
            "themeMode" to (prefs.getString(KEY_THEME_MODE, "system") ?: "system"),
            "onboardingCompleted" to prefs.getBoolean(KEY_ONBOARDING_COMPLETED, false),
        )
    }

    fun updateSettings(context: Context, settings: Map<String, Any>) {
        val prefs = getPrefs(context).edit()
        settings.forEach { (key, value) ->
            when (key) {
                "globalLimit" -> asInt(value)?.let { prefs.putInt(KEY_GLOBAL_LIMIT, it) }
                "perAppLimits" -> prefs.putString(KEY_PER_APP_LIMITS, gson.toJson(value))
                "trackedApps" -> prefs.putString(KEY_TRACKED_APPS, gson.toJson(normalizeTrackedApps((value as? List<*>)?.filterIsInstance<String>() ?: emptyList())))
                "blockingEnabled" -> asBool(value)?.let { prefs.putBoolean(KEY_BLOCKING_ENABLED, it) }
                "strictMode" -> asBool(value)?.let { prefs.putBoolean(KEY_STRICT_MODE, it) }
                "snoozeMinutes" -> asInt(value)?.let { prefs.putInt(KEY_SNOOZE_MINUTES, it) }
                "resetHour" -> asInt(value)?.let { prefs.putInt(KEY_RESET_HOUR, it) }
                "warnAtPercent" -> asInt(value)?.let { prefs.putInt(KEY_WARN_AT_PERCENT, it) }
                "overlayMode" -> asBool(value)?.let { prefs.putBoolean(KEY_OVERLAY_MODE, it) }
                "themeMode" -> prefs.putString(KEY_THEME_MODE, value.toString())
                "onboardingCompleted" -> asBool(value)?.let { prefs.putBoolean(KEY_ONBOARDING_COMPLETED, it) }
            }
        }
        prefs.commit()
    }

    private fun asInt(value: Any?): Int? = when (value) {
        is Int -> value
        is Long -> value.toInt()
        is Double -> value.toInt()
        is Float -> value.toInt()
        is Number -> value.toInt()
        is String -> value.toIntOrNull()
        else -> null
    }

    private fun asBool(value: Any?): Boolean? = when (value) {
        is Boolean -> value
        is String -> value.equals("true", ignoreCase = true)
        is Number -> value.toInt() != 0
        else -> null
    }

    fun getGlobalLimit(context: Context): Int {
        return getPrefs(context).getInt(KEY_GLOBAL_LIMIT, 100)
    }

    fun getPerAppLimit(context: Context, appId: String): Int {
        val prefs = getPrefs(context)
        val json = prefs.getString(KEY_PER_APP_LIMITS, gson.toJson(defaultPerAppLimits))
        val map = gson.fromJson(json, typeToken) as Map<String, Int>
        return map[appId] ?: 0
    }

    fun getTrackedApps(context: Context): List<String> {
        val prefs = getPrefs(context)
        val json = prefs.getString(KEY_TRACKED_APPS, gson.toJson(defaultTrackedApps))
        val type = TypeToken.getParameterized(List::class.java, String::class.java).type
        return normalizeTrackedApps(gson.fromJson<List<String>>(json, type) ?: defaultTrackedApps)
    }

    internal fun normalizeTrackedApps(values: List<String>): List<String> = values.map {
        com.scrollcount.app.service.PlatformConfigs.forPackage(it)?.id ?: it
    }.filter { it in defaultTrackedApps }.distinct()

    fun isBlockingEnabled(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_BLOCKING_ENABLED, true)
    }

    fun isStrictMode(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_STRICT_MODE, false)
    }

    fun getSnoozeMinutes(context: Context): Int {
        return getPrefs(context).getInt(KEY_SNOOZE_MINUTES, 5)
    }

    fun getResetHour(context: Context): Int {
        return getPrefs(context).getInt(KEY_RESET_HOUR, 0)
    }

    fun getWarnAtPercent(context: Context): Int {
        return getPrefs(context).getInt(KEY_WARN_AT_PERCENT, 80)
    }

    fun isOverlayMode(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_OVERLAY_MODE, false)
    }

    fun getStrictLockUntil(context: Context): Long {
        return getPrefs(context).getLong(KEY_STRICT_LOCK_UNTIL, 0)
    }

    fun setStrictLockUntil(context: Context, timestamp: Long) {
        getPrefs(context).edit().putLong(KEY_STRICT_LOCK_UNTIL, timestamp).apply()
    }

    fun isStrictModeLocked(context: Context): Boolean {
        val lockUntil = getStrictLockUntil(context)
        return lockUntil > 0 && System.currentTimeMillis() < lockUntil
    }

    fun clearStrictLock(context: Context) {
        getPrefs(context).edit().putLong(KEY_STRICT_LOCK_UNTIL, 0).apply()
    }

    fun isNotificationPermissionGranted(context: Context): Boolean {
        return getPrefs(context).getBoolean(KEY_NOTIFICATION_PERMISSION_GRANTED, false)
    }

    fun setNotificationPermissionGranted(context: Context, granted: Boolean) {
        getPrefs(context).edit().putBoolean(KEY_NOTIFICATION_PERMISSION_GRANTED, granted).apply()
    }

    fun isAccessibilityServiceEnabled(context: Context): Boolean {
        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: ""
        return enabledServices.contains("com.scrollcount.app.service.ScrollAccessibilityService")
    }

    fun openAccessibilitySettings(context: Context) {
        val service = android.content.ComponentName(
            "com.scrollcount.app",
            "com.scrollcount.app.service.ScrollAccessibilityService"
        )
        val details = android.content.Intent("android.settings.ACCESSIBILITY_DETAILS_SETTINGS").apply {
            putExtra(android.content.Intent.EXTRA_COMPONENT_NAME, service)
            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            context.startActivity(details)
        } catch (_: Exception) {
            val fallback = android.content.Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            fallback.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(fallback)
        }
    }

    fun canDrawOverlays(context: Context): Boolean {
        return android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.M ||
            Settings.canDrawOverlays(context)
    }

    fun openNotificationSettings(context: Context) {
        val intent = android.content.Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    fun openOverlaySettings(context: Context) {
        val intent = android.content.Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            android.net.Uri.parse("package:${context.packageName}")
        )
        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun openBatteryOptimizationSettings(context: Context) {
        val packageName = context.packageName
        val intent = android.content.Intent().apply {
            action = android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
            data = android.net.Uri.parse("package:$packageName")
            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            // Fallback to general battery settings
            val fallbackIntent = android.content.Intent(android.provider.Settings.ACTION_BATTERY_SAVER_SETTINGS)
            fallbackIntent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(fallbackIntent)
        }
    }

    fun getTrackedAppsInfo(context: Context): List<Map<String, Any>> {
        // Show disabled platforms too, otherwise they cannot be enabled again.
        val trackedApps = defaultTrackedApps
        val packageManager = context.packageManager
        return trackedApps.map { appId ->
            val appInfo = when (appId) {
                "instagram" -> Triple("com.instagram.android", "Instagram Reels", true)
                "youtube_shorts" -> Triple("com.google.android.youtube", "YouTube Shorts", true)
                "facebook_reels" -> Triple("com.facebook.katana", "Facebook Reels", true)
                "snapchat" -> Triple("com.snapchat.android", "Snapchat Spotlight", false)
                else -> Triple("", appId, false)
            }
            val packageName = appInfo.first
            val displayName = appInfo.second
            val detectionConfigured = appInfo.third
            var installed = false
            if (packageName.isNotEmpty()) {
                try {
                    packageManager.getPackageInfo(packageName, 0)
                    installed = true
                } catch (e: Exception) {
                    installed = false
                }
            }
            mapOf(
                "appId" to appId,
                "displayName" to displayName,
                "packageName" to packageName,
                "installed" to installed,
                "detectionConfigured" to detectionConfigured
            )
        }
    }
}
