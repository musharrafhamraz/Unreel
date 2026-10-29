package com.scrollcount.app.bridge

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import java.io.ByteArrayOutputStream
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.embedding.engine.plugins.FlutterPlugin
import com.scrollcount.app.data.ScrollRepository
import com.scrollcount.app.data.SettingsStore
import com.scrollcount.app.service.Notifier
import com.scrollcount.app.widget.WidgetUpdater

class BridgeHandler : FlutterPlugin, MethodCallHandler {

    private var context: Context? = null
    private var messenger: BinaryMessenger? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        messenger = binding.binaryMessenger
        setupChannels()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        tearDownChannels()
        context = null
        messenger = null
    }

    private fun setupChannels() {
        val messenger = this.messenger ?: return
        val context = this.context ?: return

        methodChannel = MethodChannel(messenger, "scrollcount/methods")
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(messenger, "scrollcount/live")
        eventChannel?.setStreamHandler(LiveCountStream())
    }

    private fun tearDownChannels() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val context = this.context ?: return result.error("NO_CONTEXT", "Context not available", null)

        try {
        when (call.method) {
            "getTimeZone" -> result.success(java.util.TimeZone.getDefault().id)
            "isAccessibilityEnabled" -> {
                result.success(SettingsStore.isAccessibilityServiceEnabled(context))
            }
            "openAccessibilitySettings" -> {
                SettingsStore.openAccessibilitySettings(context)
                result.success(null)
            }
            "canDrawOverlays" -> {
                result.success(SettingsStore.canDrawOverlays(context))
            }
            "openOverlaySettings" -> {
                SettingsStore.openOverlaySettings(context)
                result.success(null)
            }
            "openNotificationSettings" -> {
                SettingsStore.openNotificationSettings(context)
                result.success(null)
            }
            "showTestNotification" -> {
                val args = call.arguments as? Map<*, *>
                val title = args?.get("title")?.toString() ?: "Unreel test"
                val body = args?.get("body")?.toString() ?: "Reminders are working."
                val id = (args?.get("id") as? Number)?.toInt() ?: 9000
                result.success(Notifier.showTest(context, title, body, id))
            }
            "getToday" -> {
                result.success(ScrollRepository.getToday(context))
            }
            "getRange" -> {
                val args = call.arguments as? Map<*, *>
                val startDay = args?.get("startDay")?.toString() ?: ""
                val endDay = args?.get("endDay")?.toString() ?: ""
                result.success(ScrollRepository.getRange(context, startDay, endDay))
            }
            "getSettings" -> {
                result.success(SettingsStore.getAllSettings(context))
            }
            "updateSettings" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()
                val normalized = mutableMapOf<String, Any>()
                args.forEach { (key, value) ->
                    if (key is String && value != null) normalized[key] = value
                }
                SettingsStore.updateSettings(context, normalized)
                WidgetUpdater.forceUpdateAllWidgets(context)
                result.success(true)
            }
            "getTrackedApps" -> {
                result.success(SettingsStore.getTrackedAppsInfo(context))
            }
            "getAppIcon" -> {
                val appId = (call.arguments as? Map<*, *>)?.get("appId")?.toString()
                result.success(appIconPng(context, appId))
            }
            "exportCsv" -> {
                result.success(ScrollRepository.exportCsv(context))
            }
            "clearAllData" -> {
                ScrollRepository.clearAllData(context)
                WidgetUpdater.forceUpdateAllWidgets(context)
                result.success(true)
            }
            "openBatterySettings" -> {
                SettingsStore.openBatteryOptimizationSettings(context)
                result.success(null)
            }
            "requestNotificationPermission" -> {
                // Handled by Flutter side for Android 13+
                result.success(true)
            }
            "isWidgetSupportedForPin" -> {
                result.success(WidgetUpdater.isRequestPinSupported(context))
            }
            "requestPinWidget" -> {
                WidgetUpdater.requestPinWidget(context, null)
                result.success(true)
            }
            "previewBlockScreen" -> {
                val intent = android.content.Intent(context, com.scrollcount.app.ui.BlockActivity::class.java)
                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                result.success(true)
            }
            "isWidgetAdded" -> {
                result.success(WidgetUpdater.hasWidgetInstances(context))
            }
            "refreshWidgets" -> {
                WidgetUpdater.forceUpdateAllWidgets(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
        } catch (e: Exception) {
            result.error("NATIVE_ERROR", e.message ?: "Native call failed", null)
        }
    }

    private fun appIconPng(context: Context, appId: String?): ByteArray? {
        val packageName = when (appId) {
            "instagram" -> "com.instagram.android"
            "youtube_shorts" -> "com.google.android.youtube"
            "facebook_reels" -> "com.facebook.katana"
            "snapchat" -> "com.snapchat.android"
            else -> return null
        }
        return try {
            val drawable = context.packageManager.getApplicationIcon(packageName)
            val bitmap = Bitmap.createBitmap(128, 128, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, 128, 128)
            drawable.draw(canvas)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (_: Exception) {
            null
        }
    }

    // Keep registerWith for backward compatibility with v1 embedding
    companion object {
        @JvmStatic
        @Suppress("UNUSED_PARAMETER")
        fun registerWith(registrar: Any) {
            // v1 embedding registration - no-op for v2 embedding
            // The FlutterPlugin registration via onAttachedToEngine is used instead
        }
    }
}
