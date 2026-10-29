package com.scrollcount.app.service

/** Platform identity; semantic layouts are handled by ReelUiParser. */
data class PlatformConfig(
    val id: String,
    val packageName: String,
    val sectionContainerId: String? = null,
    val authorId: String? = null,
    val captionId: String? = null
)

object PlatformConfigs {
    val INSTAGRAM = PlatformConfig("instagram", "com.instagram.android",
        "com.instagram.android:id/clips_viewer_view_pager",
        "com.instagram.android:id/clips_author_username",
        "com.instagram.android:id/clips_caption_component")
    val YOUTUBE = PlatformConfig("youtube_shorts", "com.google.android.youtube",
        "com.google.android.youtube:id/reel_recycler")
    val FACEBOOK = PlatformConfig("facebook_reels", "com.facebook.katana")
    val FACEBOOK_LITE = PlatformConfig("facebook_reels", "com.facebook.lite")
    val SNAPCHAT = PlatformConfig("snapchat", "com.snapchat.android")
    private val byPackage = listOf(INSTAGRAM, YOUTUBE, FACEBOOK, FACEBOOK_LITE, SNAPCHAT).associateBy { it.packageName }
    fun forPackage(packageName: String): PlatformConfig? = byPackage[packageName]
    fun all(): List<PlatformConfig> = byPackage.values.toList()
}
