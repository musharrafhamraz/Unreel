package com.scrollcount.app.widget

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.scrollcount.app.MainActivity
import com.scrollcount.app.R

/**
 * Builds RemoteViews that show today's reel count.
 * Only framework widgets are used so the launcher can inflate the layout.
 * An AppCompat progress style here fails in the launcher and the widget
 * falls back to the app icon.
 */
object WidgetRenderer {

    fun buildViews(
        context: Context,
        widgetId: Int,
        totalCount: Int,
        limit: Int,
        isServiceEnabled: Boolean
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_small)

        views.setTextViewText(R.id.widget_count, totalCount.toString())
        views.setTextViewText(
            R.id.widget_label,
            if (isServiceEnabled) {
                context.getString(R.string.widget_reels_today)
            } else {
                context.getString(R.string.widget_counting_paused)
            }
        )
        views.setTextViewText(
            R.id.widget_status,
            if (isServiceEnabled) "TODAY" else "PAUSED"
        )
        views.setProgressBar(
            R.id.widget_progress,
            100,
            if (limit > 0) (totalCount * 100 / limit).coerceIn(0, 100) else 0,
            false
        )

        val desc = if (limit > 0) {
            context.getString(R.string.widget_content_description_with_limit, totalCount, limit)
        } else {
            context.getString(R.string.widget_content_description, totalCount)
        }
        views.setContentDescription(R.id.widget_root, desc)

        val openApp = Intent(context, MainActivity::class.java)
        val pending = PendingIntent.getActivity(
            context,
            widgetId,
            openApp,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pending)

        return views
    }
}
