package com.scrollcount.app.service

import android.view.accessibility.AccessibilityNodeInfo

/** Detection and identity use the same visible snapshot and platform policy. */
object DetectionEngine {
    private var lastDiagnostic = 0L
    data class DetectionResult(val isReelsScreen: Boolean, val appId: String?, val videoSignature: String?)

    fun detectReelsScreen(
        context: android.content.Context,
        rootNode: AccessibilityNodeInfo?,
        packageName: String,
        screenHeight: Int
    ): DetectionResult {
        val config = PlatformConfigs.forPackage(packageName) ?: return DetectionResult(false, null, null)
        if (rootNode == null) return DetectionResult(false, null, null)
        val nodes = ReelUiSnapshot.capture(rootNode)
        val inViewer = ReelUiParser.inViewer(config.id, nodes)
        val fingerprint = if (inViewer) ReelUiParser.fingerprint(config.id, nodes) else null
        if (inViewer && fingerprint == null &&
            context.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE != 0 &&
            android.os.SystemClock.elapsedRealtime() - lastDiagnostic > 10000) {
            lastDiagnostic = android.os.SystemClock.elapsedRealtime()
            java.io.File(context.cacheDir, "reel-diagnostic.json").writeText(com.google.gson.Gson().toJson(nodes))
        }
        return DetectionResult(inViewer, if (inViewer) config.id else null,
            fingerprint)
    }
}
