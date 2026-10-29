package com.scrollcount.app.service

import com.google.gson.annotations.SerializedName

/**
 * Data classes for detection rules loaded from JSON.
 */
object DetectionRules {

    data class RulesContainer(
        @SerializedName("version") val version: Int,
        @SerializedName("apps") val apps: List<AppRules>
    )

    data class AppRules(
        @SerializedName("id") val id: String,
        @SerializedName("displayName") val displayName: String,
        @SerializedName("packageName") val packageName: String,
        @SerializedName("reelsScreenIndicators") val reelsScreenIndicators: List<String>,
        @SerializedName("pagerNodeIds") val pagerNodeIds: List<String>,
        @SerializedName("videoIdentityHints") val videoIdentityHints: List<String>
    )
}