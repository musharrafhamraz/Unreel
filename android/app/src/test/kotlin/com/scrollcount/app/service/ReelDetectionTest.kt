package com.scrollcount.app.service

import org.junit.Assert.*
import org.junit.Test

class ReelDetectionTest {
    @Test fun repeatedEventsEmitOnlyOnce() {
        val state = ReelDwellState()
        assertNull(state.observe("a", 0))
        assertNull(state.observe("a", 4999))
        assertEquals("a", state.observe("a", 5000))
        assertNull(state.observe("a", 10000))
    }
    @Test fun rapidSwipeRestartsDwell() {
        val state = ReelDwellState()
        state.observe("a", 0)
        assertNull(state.observe("b", 4900))
        assertNull(state.observe("b", 5000))
        assertEquals("b", state.observe("b", 9900))
    }
    @Test fun unreadableContentAndExitsRequireFreshDwell() {
        val state = ReelDwellState()
        state.observe("a", 0)
        state.observe(null, 4500)
        assertNull(state.observe("a", 5000))
        state.reset()
        assertNull(state.observe("a", 10000))
        assertEquals("a", state.observe("a", 15000))
    }
    @Test fun sameCreatorDifferentCaptionHasDifferentIdentity() {
        assertNotEquals(ReelIdentity.fingerprint("ig", setOf("creator"), setOf("first")),
            ReelIdentity.fingerprint("ig", setOf("creator"), setOf("second")))
    }
    @Test fun captionSuffixIsNotDiscarded() {
        val prefix = "a".repeat(80)
        assertNotEquals(ReelIdentity.fingerprint("ig", setOf("creator"), setOf(prefix + "1")),
            ReelIdentity.fingerprint("ig", setOf("creator"), setOf(prefix + "2")))
    }
    @Test fun whitespaceIsStableAndPlatformsAreSeparate() {
        assertEquals(ReelIdentity.fingerprint("ig", setOf("creator"), setOf("a  b\nc")),
            ReelIdentity.fingerprint("ig", setOf("creator"), setOf("a b c")))
        assertNotEquals(ReelIdentity.fingerprint("ig", setOf("creator"), setOf("caption")),
            ReelIdentity.fingerprint("yt", setOf("creator"), setOf("caption")))
    }
    @Test fun partialOrMultiplePagesAreNotAnIdentity() {
        assertNull(ReelIdentity.fingerprint("ig", setOf("creator"), emptySet()))
        assertNull(ReelIdentity.fingerprint("ig", setOf("creator"), setOf("one", "two")))
    }
}
