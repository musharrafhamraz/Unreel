package com.scrollcount.app.data

import android.content.Context
import com.google.gson.Gson
import com.scrollcount.app.ScrollCountApplication
import com.scrollcount.app.util.DateUtils
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileWriter

/**
 * Repository for reading/writing scroll count data.
 * All DB operations run on IO dispatcher.
 */
object ScrollRepository {

    suspend fun recordReel(context: Context, day: String, appId: String, fingerprint: String): Int? {
        val dao = getDb(context).dailyCountDao()
        if (!dao.recordReel(day, appId, fingerprint)) return null
        return dao.getDay(day).sumOf { it.count }
    }

    suspend fun addSeconds(context: Context, day: String, appId: String, seconds: Int) {
        getDb(context).dailyCountDao().increment(day, appId, 0, seconds)
    }

    private val gson = Gson()

    private fun getDb(context: Context): AppDatabase {
        return (context.applicationContext as ScrollCountApplication).getDatabase()
    }

    /**
     * Get today's stats including per-app breakdown.
     */
    fun getToday(context: Context): Map<String, Any> {
        val day = DateUtils.getCurrentLogicalDay(context)
        return runBlocking { getDayData(context, day) }
    }

    /**
     * Get stats for a date range.
     */
    fun getRange(context: Context, startDay: String, endDay: String): List<Map<String, Any>> {
        return runBlocking {
            val dao = getDb(context).dailyCountDao()
            val entities = dao.getRange(startDay, endDay)
            entities.map { entity ->
                mapOf(
                    "day" to entity.day,
                    "appId" to entity.appId,
                    "count" to entity.count,
                    "seconds" to entity.seconds
                )
            }
        }
    }

    private suspend fun getDayData(context: Context, day: String): Map<String, Any> {
        val dao = getDb(context).dailyCountDao()
        val entities = dao.getDay(day)
        val perApp = entities.map { entity ->
            mapOf(
                "appId" to entity.appId,
                "count" to entity.count,
                "seconds" to entity.seconds
            )
        }
        val totalCount = entities.sumOf { it.count }
        val totalSeconds = entities.sumOf { it.seconds }
        return mapOf(
            "day" to day,
            "total" to totalCount,
            "totalSeconds" to totalSeconds,
            "perApp" to perApp
        )
    }

    /**
     * Increment count for today.
     */
    fun incrementToday(context: Context, appId: String, deltaCount: Int, deltaSeconds: Int) {
        val day = DateUtils.getCurrentLogicalDay(context)
        runBlocking {
            getDb(context).dailyCountDao().increment(day, appId, deltaCount, deltaSeconds)
        }
    }

    /**
     * Export all data as CSV string.
     */
    fun exportCsv(context: Context): String {
        return runBlocking {
            val dao = getDb(context).dailyCountDao()
            val entities = dao.exportAll()
            val sb = StringBuilder()
            sb.appendLine("day,app_id,count,seconds")
            entities.forEach { e ->
                sb.appendLine("${e.day},${e.appId},${e.count},${e.seconds}")
            }
            return@runBlocking sb.toString()
        }
    }

    /**
     * Export CSV to a file and return the file path.
     */
    fun exportCsvToFile(context: Context): String {
        val csv = exportCsv(context)
        val file = File(context.getExternalFilesDir(null), "scrollcount_export_${DateUtils.getCurrentLogicalDay(context)}.csv")
        FileWriter(file).use { it.write(csv) }
        return file.absolutePath
    }

    /**
     * Clear all data from the database.
     */
    fun clearAllData(context: Context) {
        CoroutineScope(Dispatchers.IO).launch {
            getDb(context).dailyCountDao().clearAll()
        }
    }

    // Helper to run suspend functions synchronously (for platform channel calls)
    private inline fun <T> runBlocking(crossinline block: suspend () -> T): T {
        return kotlinx.coroutines.runBlocking { block() }
    }
}
