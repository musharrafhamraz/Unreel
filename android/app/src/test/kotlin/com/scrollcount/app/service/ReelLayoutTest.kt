package com.scrollcount.app.service

import org.junit.Assert.*
import org.junit.Test
import org.w3c.dom.Element
import javax.xml.parsers.DocumentBuilderFactory

class ReelLayoutTest {
    private fun layout(name: String): List<ReelUiNode> {
        val doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(javaClass.getResourceAsStream("/reel-layouts/$name.xml"))
        val result = mutableListOf<ReelUiNode>()
        fun walk(node: Element, ids: List<String>, labels: List<String>) {
            val id = node.getAttribute("resource-id").substringAfter(":id/")
            val text = node.getAttribute("text")
            val label = ReelIdentity.normalize(text.ifBlank { node.getAttribute("content-desc") })
            val coords = Regex("\\d+").findAll(node.getAttribute("bounds")).map { it.value.toInt() }.toList()
            if (coords.size == 4 && coords[2] > coords[0] && coords[3] > coords[1]) result.add(ReelUiNode(id, label, ids, labels, node.getAttribute("selected") == "true", text.isNotBlank(), coords[2] / 1080f, node.getAttribute("class")))
            for (i in 0 until node.childNodes.length) {
                val child = node.childNodes.item(i) as? Element ?: continue
                walk(child, if (id.isBlank()) ids else ids + id, if (label.isBlank()) labels else labels + label)
            }
        }
        walk(doc.documentElement, emptyList(), emptyList())
        return result
    }
    @Test fun capturedViewersProduceIdentities() {
        for ((fixture, platform) in listOf("instagram" to "instagram", "facebook" to "facebook_reels", "youtube" to "youtube_shorts")) {
            val nodes = layout(fixture)
            assertTrue(fixture, ReelUiParser.inViewer(platform, nodes))
            assertNotNull(fixture, ReelUiParser.fingerprint(platform, nodes))
        }
    }
    @Test fun instagramUnnamedCaptionChildrenDistinguishSameCreatorReels() {
        val nodes = layout("instagram")
        assertTrue(nodes.any { it.id.isEmpty() && it.within("clips_caption_component") && it.label.isNotBlank() })
        val changed = nodes.map { if (it.within("clips_caption_component") && it.label.isNotBlank()) it.copy(label = "Another reel caption") else it }
        assertNotEquals(ReelUiParser.fingerprint("instagram", nodes), ReelUiParser.fingerprint("instagram", changed))
        assertNotNull(ReelUiParser.fingerprint("instagram", changed))
    }
    @Test fun facebookTabAloneIsNotAViewer() {
        assertFalse(ReelUiParser.inViewer("facebook_reels", listOf(ReelUiNode(label = "Reels, tab 2 of 6"))))
    }
    @Test fun facebookReactionCountsDoNotChangeIdentity() {
        val nodes = layout("facebook")
        val changed = nodes.map { if (it.label.contains("reactions") || it.label.contains("comments") || it.label.startsWith("Share,")) it.copy(label = "999 reactions") else it }
        assertEquals(ReelUiParser.fingerprint("facebook_reels", nodes), ReelUiParser.fingerprint("facebook_reels", changed))
    }
    @Test fun youtubeIgnoresTimeAndRightRailButDetectsNewTitle() {
        val nodes = layout("youtube")
        val first = ReelUiParser.fingerprint("youtube_shorts", nodes)
        val changed = nodes.map { if (it.rightFraction > 0.85f && it.label.isNotBlank()) it.copy(label = "999") else it }
        assertEquals(first, ReelUiParser.fingerprint("youtube_shorts", changed))
        val second = nodes.map { if (it.label == "Sample Short title") it.copy(label = "Another Short title") else it }
        assertNotEquals(first, ReelUiParser.fingerprint("youtube_shorts", second))
    }
    @Test fun youtubeUsesNewerReelPlayerContainersAndTextTitleFallback() {
        val nodes = listOf(
            ReelUiNode(id = "reel_player_page_container"),
            ReelUiNode(label = "@creator", hasText = true, rightFraction = 0.4f),
            ReelUiNode(label = "A current Shorts title", hasText = true, rightFraction = 0.7f)
        )
        assertTrue(ReelUiParser.inViewer("youtube_shorts", nodes))
        assertNotNull(ReelUiParser.fingerprint("youtube_shorts", nodes))
    }
    @Test fun facebookAcceptsUpdatedControlsAndUsesTheirCaptionAncestor() {
        val nodes = listOf(
            ReelUiNode(label = "View Creator's reels"),
            ReelUiNode(label = "Tap to show video controls", ancestorLabels = listOf("A Facebook reel caption"))
        )
        assertTrue(ReelUiParser.inViewer("facebook_reels", nodes))
        assertNotNull(ReelUiParser.fingerprint("facebook_reels", nodes))
    }
    @Test fun facebookUsesVisibleCaptionAndPagerWhenFacebookHidesPlayerDescriptions() {
        val nodes = listOf(
            ReelUiNode(label = "Reels", selected = true),
            ReelUiNode(className = "androidx.viewpager.widget.ViewPager"),
            ReelUiNode(label = "A reel caption supplied by Facebook", hasText = true)
        )
        assertTrue(ReelUiParser.inViewer("facebook_reels", nodes))
        assertNotNull(ReelUiParser.fingerprint("facebook_reels", nodes))
    }
}
