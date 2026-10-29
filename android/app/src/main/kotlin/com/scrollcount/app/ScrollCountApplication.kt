package com.scrollcount.app

import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.room.Room
import com.scrollcount.app.bridge.LiveCountStreamHolder
import com.scrollcount.app.data.AppDatabase
import com.scrollcount.app.service.Notifier

class ScrollCountApplication : Application() {

    private var database: AppDatabase? = null

    private val liveCountReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val day = intent.getStringExtra("day") ?: return
            val appId = intent.getStringExtra("appId") ?: return
            LiveCountStreamHolder.push(
                mapOf(
                    "day" to day,
                    "appId" to appId,
                    "count" to intent.getIntExtra("count", 1),
                    "total" to intent.getIntExtra("total", 0)
                )
            )
        }
    }

    override fun onCreate() {
        super.onCreate()
        database = Room.databaseBuilder(
            applicationContext,
            AppDatabase::class.java,
            "scrollcount-db"
        ).fallbackToDestructiveMigration()
            .enableMultiInstanceInvalidation()
            .build()

        if (isMainProcess()) {
            Notifier.ensureAlertsChannel(this)
            val filter = IntentFilter(LiveCountStreamHolder.ACTION)
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(liveCountReceiver, filter, RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(liveCountReceiver, filter)
            }
        }
    }

    private fun isMainProcess(): Boolean {
        val name = if (Build.VERSION.SDK_INT >= 28) {
            getProcessName()
        } else {
            packageName
        }
        return name == packageName
    }

    fun getDatabase(): AppDatabase {
        return database!!
    }
}