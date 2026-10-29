package com.scrollcount.app.service

import android.view.accessibility.AccessibilityNodeInfo
import java.security.MessageDigest

object ReelFingerprint {
    fun compute(config: PlatformConfig, root: AccessibilityNodeInfo?): String? =
        root?.let { ReelUiParser.fingerprint(config.id, ReelUiSnapshot.capture(it)) }
}
/** Pure identity policy, shared by the detector and regression tests. */
object ReelIdentity {
    fun normalize(text: String): String = text.replace(Regex("\\s+"), " ").trim()

    fun fingerprint(platform: String, authors: Set<String>, captions: Set<String>): String? {
        // Two visible pages during a swipe are ambiguous. A creator alone is not a reel.
        if (authors.size > 1 || captions.size != 1) return null
        val caption = normalize(captions.single())
        if (caption.isBlank()) return null
        val parts = listOf(platform, authors.singleOrNull()?.let(::normalize).orEmpty(), caption)
        val input = parts.joinToString("") { "${it.length}:$it" }
        return MessageDigest.getInstance("SHA-256").digest(input.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }
    }
}

