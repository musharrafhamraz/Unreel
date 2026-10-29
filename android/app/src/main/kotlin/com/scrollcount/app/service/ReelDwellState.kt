package com.scrollcount.app.service

/** Requires continuous readable identity. Time is monotonic, not the wall clock. */
class ReelDwellState(private val dwellMs: Long = 5000L) {
    private var identity: String? = null
    private var since = 0L
    private var emitted = false

    fun observe(fingerprint: String?, now: Long): String? {
        if (fingerprint == null) { reset(); return null }
        if (identity != fingerprint) {
            identity = fingerprint
            since = now
            emitted = false
        }
        if (emitted || now - since < dwellMs) return null
        emitted = true
        return fingerprint
    }

    fun reset() { identity = null; emitted = false }
}
