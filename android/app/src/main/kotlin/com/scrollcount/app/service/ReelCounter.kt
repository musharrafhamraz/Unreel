package com.scrollcount.app.service

import android.content.Context
import android.os.SystemClock
import android.util.Log
import com.scrollcount.app.bridge.LiveCountStreamHolder
import com.scrollcount.app.data.ScrollRepository
import com.scrollcount.app.util.DateUtils
import com.scrollcount.app.widget.WidgetUpdater
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel

/** Serial writes; a count and its durable identity are committed in one transaction. */
class ReelCounter(private val context: Context) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val writes = Channel<suspend () -> Unit>(Channel.UNLIMITED)
    private var app: String? = null
    private var day: String? = null
    private var started = 0L

    init {
        scope.launch {
            for (write in writes) {
                for (attempt in 0..2) {
                    try { write(); break } catch (e: Exception) {
                        Log.e("Unreel", "Count write failed (attempt ${attempt + 1})", e)
                        if (attempt < 2) delay(250L * (attempt + 1))
                    }
                }
            }
            scope.cancel()
        }
    }

    fun onDetectionResult(result: DetectionEngine.DetectionResult) {
        val today = DateUtils.getCurrentLogicalDay(context)
        val now = SystemClock.elapsedRealtime()
        if (!result.isReelsScreen || app != result.appId || day != today) finishSession(now)
        if (!result.isReelsScreen) return
        val appId = result.appId ?: return
        if (app == null) { app = appId; day = today; started = now }
        // Checkpoint watch time so a process death loses at most a few seconds.
        if (now - started >= 5000) {
            saveSeconds(appId, today, ((now - started) / 1000).toInt())
            started += ((now - started) / 1000) * 1000
        }
        val fingerprint = result.videoSignature ?: return
        writes.trySend {
            val total = ScrollRepository.recordReel(context, today, appId, fingerprint)
            if (total != null) {
                withContext(Dispatchers.Main) {
                    CountOverlay.update(context, total)
                    LiveCountStreamHolder.publish(context, today, appId, 1, total)
                }
                WidgetUpdater.forceUpdateAllWidgets(context)
            }
        }
    }

    private fun saveSeconds(appId: String, logicalDay: String, seconds: Int) {
        if (seconds > 0) writes.trySend { ScrollRepository.addSeconds(context, logicalDay, appId, seconds) }
    }

    private fun finishSession(now: Long) {
        app?.let { saveSeconds(it, day!!, ((now - started) / 1000).toInt()) }
        app = null
        day = null
    }

    fun shutdown() {
        finishSession(SystemClock.elapsedRealtime())
        writes.close() // Drain queued writes before cancelling the scope.
    }
}
