package com.scrollcount.app.service

/** Android-independent semantic extraction, tested against observed app layouts. */
data class ReelUiNode(
    val id: String = "",
    val label: String = "",
    val ancestorIds: List<String> = emptyList(),
    val ancestorLabels: List<String> = emptyList(),
    val selected: Boolean = false,
    val hasText: Boolean = false,
    val rightFraction: Float = 1f,
    val className: String = ""
) {
    fun within(vararg markers: String): Boolean = (ancestorIds + id).any { id -> markers.any { id.contains(it) } }
}

object ReelUiParser {
    fun inViewer(platform: String, nodes: List<ReelUiNode>): Boolean {
        val markers = when (platform) {
            "instagram" -> listOf("clips_viewer", "root_clips_layout")
            // YouTube changes the outer container often, but keeps the reel-player
            // family of IDs.  Do not rely on reel_recycler alone.
            "youtube_shorts" -> listOf(
                "reel_recycler", "reel_watch", "reel_player", "reel_video",
                "shorts_player", "shorts_video"
            )
            "facebook_reels" -> listOf("reel_player", "reel_viewer")
            else -> listOf("spotlight_player")
        }
        if (nodes.any { node -> markers.any { node.id.contains(it) } }) return true
        if (platform == "facebook_reels") {
            // Facebook deliberately removes most view IDs.  The wording of the
            // controls changed across versions, so use its durable semantic cues
            // rather than requiring two old strings verbatim.
            val labels = nodes.map { it.label.lowercase() }
            val hasViewerControl = labels.any {
                it.contains("tap to show video controls") ||
                    it.contains("show video controls") ||
                    it.contains("reels tab details")
            }
            val hasReelContent = labels.any {
                it.matches(Regex("view .+'s reels")) ||
                    it.contains("original audio") ||
                    it.contains("privacy setting")
            }
            if (hasViewerControl && hasReelContent) return true

            // Some Facebook releases expose no useful descriptions for the
            // player. Their full-screen reel is still a ViewPager, unlike the
            // normal Reels feed, and retains the Reels navigation context.
            val hasPager = nodes.any { it.className.contains("viewpager", true) }
            val hasReelsContext = labels.any { it == "reels" || it.contains("reels, tab") }
            return hasPager && hasReelsContext
        }
        return false
    }

    fun fingerprint(platform: String, nodes: List<ReelUiNode>): String? {
        val authors = sortedSetOf<String>()
        val captions = sortedSetOf<String>()
        val youtubeTitles = sortedSetOf<String>()
        val facebookContent = sortedSetOf<String>()
        for (node in nodes) {
            if (node.label.isBlank()) continue
            if (node.within("author_username", "channel_name", "reel_channel_bar", "reel_channel_title")) {
                if (!node.label.equals("Subscribe", true) && !node.label.equals("Follow", true)) authors.add(node.label)
            }
            if (node.within("caption", "reel_title", "video_title", "shorts_title")) captions.add(node.label)
            if (platform == "youtube_shorts" &&
                (node.within("reel_player_footer_container", "reel_player_overlay", "shorts_player") ||
                    isYouTubeTitleCandidate(node))) {
                Regex("^Go to channel (@\\S+)$").matchEntire(node.label)?.let { authors.add(it.groupValues[1]) }
                if (node.label.startsWith("@") && !node.label.contains(' ')) authors.add(node.label)
                // The title and optional linked-video title occupy the left footer column.
                // Controls/counters are in the right rail, even when they have no IDs.
                if (node.hasText && node.rightFraction <= 0.85f &&
                    !node.label.startsWith("@") &&
                    node.label.lowercase() !in setOf("subscribe", "subscribed", "join", "more", "follow")) {
                    youtubeTitles.add(node.label)
                }
            }
            if (platform == "facebook_reels") {
                Regex("^View (.+)'s reels$").matchEntire(node.label)?.let { authors.add(it.groupValues[1]) }
                Regex("^(.+), privacy setting .+$", RegexOption.IGNORE_CASE)
                    .matchEntire(node.label)?.let { authors.add(it.groupValues[1]) }
                if (node.label.equals("Reels tab details", true) ||
                    node.label.contains("show video controls", true)) {
                    // Facebook removes resource names. The viewer's parent description is its caption.
                    node.ancestorLabels.lastOrNull()?.takeUnless { it.isFacebookChromeLabel() }
                        ?.let { captions.add(it) }
                }
                if (node.label.isFacebookContentCandidate()) facebookContent.add(node.label)
            }
        }
        if (platform == "youtube_shorts" && captions.isEmpty() && youtubeTitles.isNotEmpty()) {
            captions.add(youtubeTitles.joinToString("\n"))
        }
        if (platform == "facebook_reels" && captions.isEmpty() && facebookContent.isNotEmpty()) {
            // Captions are often exposed as a nameless parent rather than a
            // child of the player control. Combining the meaningful visible
            // content gives a stable, per-reel signature without using likes,
            // comments, or other changing controls.
            captions.add(facebookContent.joinToString("\n"))
        }
        // Containers and children sometimes expose the same sentence in pieces.
        val fullCaptions = captions.filter { part -> captions.none { it != part && it.contains(part) } }.toSet()
        return ReelIdentity.fingerprint(platform, authors, fullCaptions)
    }

    private fun isYouTubeTitleCandidate(node: ReelUiNode): Boolean {
        if (!node.hasText || node.rightFraction > 0.85f || node.label.startsWith("@")) return false
        return node.label.lowercase() !in setOf(
            "home", "shorts", "subscriptions", "you", "subscribe", "subscribed",
            "join", "more", "follow", "share", "save", "create", "search"
        ) && !node.label.matches(Regex("[\\d,.]+[km]?", RegexOption.IGNORE_CASE))
    }

    private fun String.isFacebookChromeLabel(): Boolean {
        val label = lowercase()
        return label.contains("reels tab details") || label.contains("show video controls") ||
            label.startsWith("view ") || label.contains("original audio") ||
            label.contains("privacy setting")
    }

    private fun String.isFacebookContentCandidate(): Boolean {
        val label = lowercase()
        if (length < 4 || isFacebookChromeLabel()) return false
        if (label in setOf("reels", "home", "friends", "marketplace", "notifications", "menu", "search", "save", "follow", "share", "more")) return false
        if (label.startsWith("follow ") || label.startsWith("like ") || label.startsWith("share,") ||
            label.contains(" reaction") || label.contains(" comments") || label.matches(Regex("[\\d,.]+[km]?"))) return false
        return true
    }
}
