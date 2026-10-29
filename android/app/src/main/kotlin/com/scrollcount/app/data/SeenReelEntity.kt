package com.scrollcount.app.data

import androidx.room.Entity

/** Stored atomically with the count, without eviction of previously counted reels. */
@Entity(tableName = "seen_reels", primaryKeys = ["appId", "fingerprint"])
data class SeenReelEntity(val appId: String, val fingerprint: String)
