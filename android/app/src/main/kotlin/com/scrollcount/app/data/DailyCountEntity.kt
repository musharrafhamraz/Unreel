package com.scrollcount.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "daily_counts", indices = [androidx.room.Index(value = ["day", "appId"], unique = true)])
data class DailyCountEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val day: String, // yyyy-MM-dd logical day
    val appId: String, // instagram, youtube_shorts, facebook_reels, snapchat
    val count: Int = 0,
    val seconds: Int = 0
)