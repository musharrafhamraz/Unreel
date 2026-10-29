package com.scrollcount.app.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface DailyCountDao {

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertSeen(reel: SeenReelEntity): Long

    @androidx.room.Transaction
    suspend fun recordReel(day: String, appId: String, fingerprint: String): Boolean {
        if (insertSeen(SeenReelEntity(appId, fingerprint)) == -1L) return false
        increment(day, appId, 1, 0)
        return true
    }

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(entity: DailyCountEntity): Long

    @Update
    suspend fun update(entity: DailyCountEntity): Int

    @Query("""
        INSERT INTO daily_counts (day, appId, count, seconds)
        VALUES (:day, :appId, :deltaCount, :deltaSeconds)
        ON CONFLICT(day, appId) DO UPDATE SET
            count = count + :deltaCount,
            seconds = seconds + :deltaSeconds
    """)
    suspend fun increment(day: String, appId: String, deltaCount: Int, deltaSeconds: Int)

    @Query("SELECT * FROM daily_counts WHERE day = :day")
    suspend fun getDay(day: String): List<DailyCountEntity>

    @Query("SELECT * FROM daily_counts WHERE day BETWEEN :startDay AND :endDay ORDER BY day DESC, appId")
    suspend fun getRange(startDay: String, endDay: String): List<DailyCountEntity>

    @Query("SELECT * FROM daily_counts ORDER BY day DESC")
    fun getAll(): Flow<List<DailyCountEntity>>

    @Query("DELETE FROM daily_counts")
    suspend fun clearAll(): Int

    @Query("SELECT * FROM daily_counts ORDER BY day DESC, appId")
    suspend fun exportAll(): List<DailyCountEntity>
}
