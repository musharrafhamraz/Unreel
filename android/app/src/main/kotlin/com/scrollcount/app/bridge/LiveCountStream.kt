package com.scrollcount.app.bridge

import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler

/**
 * Singleton holder for the live count EventSink.
 * The AccessibilityService pushes updates here when Flutter UI is attached.
 * When Flutter detaches, sink is null and updates are simply dropped.
 */
object LiveCountStreamHolder {
    const val ACTION = "com.scrollcount.app.LIVE_COUNT"

    @Volatile
    var sink: EventSink? = null

    fun push(event: Map<String, Any>) {
        sink?.success(event)
    }

    /** The counter runs in its own process, so the open app hears counts through this. */
    fun publish(context: Context, day: String, appId: String, count: Int, total: Int) {
        val intent = Intent(ACTION).setPackage(context.packageName).apply {
            putExtra("day", day)
            putExtra("appId", appId)
            putExtra("count", count)
            putExtra("total", total)
        }
        context.sendBroadcast(intent)
    }
}

/**
 * EventChannel stream handler for live count updates.
 * Only active while Flutter UI is attached.
 */
class LiveCountStream : StreamHandler {

    override fun onListen(arguments: Any?, events: EventSink) {
        LiveCountStreamHolder.sink = events
        Log.d("Unreel", "LiveCountStream: Flutter attached")
    }

    override fun onCancel(arguments: Any?) {
        LiveCountStreamHolder.sink = null
        Log.d("Unreel", "LiveCountStream: Flutter detached")
    }
}