package com.scrollcount.app.service

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.pm.ServiceInfo
import android.graphics.Rect
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.scrollcount.app.data.SettingsStore

/**
 * Counts a reel only when a NEW reel stays on screen for DWELL_MS.
 * Fingerprints (author + caption) come from ReelFingerprint, dedup and
 * dwell timers from ReelTracker; duplicates and instant skips never count.
 */
class ScrollAccessibilityService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var counter: ReelCounter
    private lateinit var tracker: ReelTracker
    private var screenHeight = 1
    private var activePackage: String? = null

    /** True while exactly one scan callback is queued on the handler. */
    private var scanQueued = false

    private val scanRunnable = Runnable {
        scanQueued = false
        scanActiveWindow()
        if (activePackage != null) scheduleScan()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        if (::tracker.isInitialized) tracker.cancelAll()
        if (::counter.isInitialized) counter.shutdown()
        counter = ReelCounter(applicationContext)
        tracker = ReelTracker(
            applicationContext,
            confirmStillVisible = { pkg, fingerprint -> stillShowing(pkg, fingerprint) },
            onReelConfirmed = { appId, fingerprint ->
                counter.onDetectionResult(DetectionEngine.DetectionResult(true, appId, fingerprint))
            }
        )
        screenHeight = resources.displayMetrics.heightPixels.coerceAtLeast(1)
        Log.d(TAG, "Service connected")

        val info = serviceInfo ?: AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_VIEW_SCROLLED or
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
            AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
            AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        info.notificationTimeout = 50
        // Observe app exits as well; filtering to tracked apps misses Home/lock/other apps.
        info.packageNames = null
        serviceInfo = info
        startCountingForeground()
        try {
            CountOverlay.showCurrent(applicationContext)
        } catch (e: Exception) {
            Log.w(TAG, "Overlay failed", e)
        }
    }

    /**
     * Keeps this process alive after the Flutter screen closes and after a
     * debug session drops. Xiaomi otherwise kills the counter with the app.
     */
    private fun startCountingForeground() {
        try {
            val notification = Notifier.counterNotification(this)
            if (Build.VERSION.SDK_INT >= 34) {
                startForeground(
                    Notifier.COUNTER_NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(Notifier.COUNTER_NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not pin the counting process", e)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!::counter.isInitialized || !::tracker.isInitialized) return
        val pkg = event?.packageName?.toString() ?: return
        if (pkg !in PACKAGES) {
            if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) scheduleScan()
            return
        }
        if (pkg != activePackage) {
            val previous = activePackage
            activePackage = pkg
            // Kills the old app's dwell timer; time in the other app is
            // handled by the counter's leave callback below.
            Log.d(TAG, "active app $previous -> $pkg")
            previous?.let { tracker.onPackageLeft(it) }
            counter.onDetectionResult(DetectionEngine.DetectionResult(false, null, null))
        }
        if (!isTracked(PACKAGES.getValue(pkg))) return

        // All events funnel through one debounced scan so heavy node work
        // happens at most once every SCAN_DELAY_MS, never per event.
        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_SCROLLED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> scheduleScan()
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
        if (::tracker.isInitialized) tracker.cancelAll()
        if (::counter.isInitialized) counter.onDetectionResult(DetectionEngine.DetectionResult(false, null, null))
        cancelScan()
        activePackage = null
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        stopCounting()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        stopCounting()
        super.onDestroy()
    }

    private fun stopCounting() {
        cancelScan()
        if (::tracker.isInitialized) tracker.cancelAll()
        if (::counter.isInitialized) counter.shutdown()
        CountOverlay.hide(applicationContext)
        try {
            if (Build.VERSION.SDK_INT >= 24) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Foreground stop failed", e)
        }
    }

    /**
     * Trailing-edge throttle (NOT a reset-on-every-event debounce): the
     * first event queues exactly one scan SCAN_DELAY_MS out; events arriving
     * inside that window are absorbed; the queued scan RUNS even if floods
     * continue. A reset debounce STARVES under the continuous accessibility
     * stream a video player emits — and with count-on-scan (instead of the
     * old count-on-event) that meant the scan never ran and reels were
     * never inspected: counting fully stopped. The throttle caps heavy node
     * work at <=5 scans/second without a single point of starvation.
     */
    private fun scheduleScan() {
        if (scanQueued) return
        scanQueued = true
        handler.postDelayed(scanRunnable, SCAN_DELAY_MS)
    }

    private fun cancelScan() {
        if (!scanQueued) return
        handler.removeCallbacks(scanRunnable)
        scanQueued = false
    }

    /**
     * The reel count bubble is its own window. rootInActiveWindow often
     * returns that bubble, so the viewer underneath is never read and
     * the count stops. Pick the tracked app's window instead.
     */
    private fun findTrackedRoot(pkg: String): AccessibilityNodeInfo? {
        val power = getSystemService(POWER_SERVICE) as android.os.PowerManager
        val keyguard = getSystemService(KEYGUARD_SERVICE) as android.app.KeyguardManager
        if (!power.isInteractive || keyguard.isKeyguardLocked) return null
        val windowList = windows
        if (windowList != null) {
            var match: AccessibilityNodeInfo? = null
            var matchArea = -1
            val bounds = Rect()
            for (window in windowList) {
                val root = window.root
                if (root?.packageName?.toString() == pkg &&
                    window.type == android.view.accessibility.AccessibilityWindowInfo.TYPE_APPLICATION &&
                    (window.isActive || window.isFocused)) {
                    root.getBoundsInScreen(bounds)
                    val area = bounds.width() * bounds.height()
                    if (area > matchArea) {
                        match?.recycle()
                        match = root
                        matchArea = area
                    } else {
                        root.recycle()
                    }
                } else {
                    root?.recycle()
                }
                window.recycle()
            }
            if (match != null) return match
        }
        val active = rootInActiveWindow ?: return null
        if (active.packageName?.toString() == pkg) return active
        active.recycle()
        return null
    }

    private fun scanActiveWindow() {
        val pkg = activePackage ?: return
        val config = PlatformConfigs.forPackage(pkg) ?: return
        val root = if (isTracked(config.id)) findTrackedRoot(pkg) else null
        if (root == null) {
            tracker.onPackageLeft(pkg)
            counter.onDetectionResult(DetectionEngine.DetectionResult(false, null, null))
            activePackage = null
            return
        }
        screenHeight = resources.displayMetrics.heightPixels.coerceAtLeast(1)
        try {
            val detected = DetectionEngine.detectReelsScreen(this, root, pkg, screenHeight)
            if (!detected.isReelsScreen) {
                // Home feed / search / profile: not a counting context.
                // Grace-delivered in ReelTracker — a missed scan from window
                // re-layout must not keep restarting the dwell timer.
                Log.d(TAG, "scan $pkg outside short-video section")
                tracker.onSectionMissing(pkg)
                counter.onDetectionResult(DetectionEngine.DetectionResult(false, null, null))
                return
            }
            // Presence only (null signature): keeps the counter's reel-screen
            // timing alive without counting. A count happens only through the
            // tracker's confirmed 5-second dwell below.
            counter.onDetectionResult(DetectionEngine.DetectionResult(true, config.id, null))
            val fingerprint = detected.videoSignature
            Log.d(TAG, "scan $pkg in-section fp=${fingerprint?.take(8) ?: "null"}")
            tracker.onFingerprint(pkg, config, fingerprint)
        } catch (e: Exception) {
            Log.w(TAG, "Detection failed", e)
        } finally {
            root.recycle()
        }
    }

    private fun isTracked(appId: String): Boolean {
        return try {
            SettingsStore.getTrackedApps(this).contains(appId)
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Dwell confirmation, called from ReelTracker when the 5-second timer
     * fires: re-checks the section, the active app, and re-reads the current
     * fingerprint so the reel is counted only while it is still on screen.
     */
    private fun stillShowing(pkg: String, fingerprint: String): Boolean {
        if (pkg != activePackage) return false
        val config = PlatformConfigs.forPackage(pkg) ?: return false
        if (!isTracked(config.id)) return false
        val root = findTrackedRoot(pkg) ?: return false
        try {
            val detected = DetectionEngine.detectReelsScreen(this, root, pkg, screenHeight)
            if (!detected.isReelsScreen) return false
            val fresh = detected.videoSignature
            // Unknown content cannot prove continuous viewing of this reel.
            val still = fresh == fingerprint
            Log.d(TAG, "confirm $pkg fresh=${fresh?.take(8) ?: "null"} still=$still")
            return still
        } catch (e: Exception) {
            return false
        } finally {
            root.recycle()
        }
    }

    companion object {
        private const val TAG = "Unreel"

        /** Debounce: one scan at most every 200 ms, no matter the event rate. */
        private const val SCAN_DELAY_MS = 200L

        private val PACKAGES = mapOf(
            "com.instagram.android" to "instagram",
            "com.google.android.youtube" to "youtube_shorts",
            "com.facebook.katana" to "facebook_reels",
            "com.facebook.lite" to "facebook_reels",
            "com.snapchat.android" to "snapchat"
        )
    }
}
