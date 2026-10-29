package com.scrollcount.app.service

import android.content.Context
import android.os.SystemClock

/** The service samples continuously; durable duplicate prevention belongs to Room. */
class ReelTracker(
    private val context: Context,
    private val confirmStillVisible: (String, String) -> Boolean,
    private val onReelConfirmed: (String, String) -> Unit
) {
    private val states = mutableMapOf<String, ReelDwellState>()

    fun onFingerprint(pkg: String, config: PlatformConfig, fingerprint: String?) {
        val state = states.getOrPut(pkg) { ReelDwellState() }
        val confirmed = state.observe(fingerprint, SystemClock.elapsedRealtime()) ?: return
        if (confirmStillVisible(pkg, confirmed)) {
            onReelConfirmed(config.id, confirmed)
        } else {
            state.reset() // A failed final read must be able to arm again.
        }
    }

    fun onSectionMissing(pkg: String) { states.remove(pkg) }
    fun onPackageLeft(pkg: String) { states.remove(pkg) }
    fun cancelAll() { states.clear() }
}
