package com.scrollcount.app.service

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.scrollcount.app.R
import com.scrollcount.app.data.ScrollRepository

/**
 * Draggable reel-count bubble. The brain's face follows today's total.
 */
object CountOverlay {

    private const val PREFS = "scrollcount_overlay"
    private const val KEY_X = "x"
    private const val KEY_Y = "y"

    private val mainHandler = Handler(Looper.getMainLooper())
    private var frameView: View? = null
    private var brainView: ImageView? = null
    private var countLabel: TextView? = null
    private var windowManager: WindowManager? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var askedForPermission = false
    private var shownMoodArt = 0


    fun showCurrent(context: Context) {
        val total = (ScrollRepository.getToday(context)["total"] as? Number)?.toInt() ?: 0
        show(context, total, askIfMissing = false)
    }

    fun show(context: Context, count: Int, askIfMissing: Boolean = false) {
        val appContext = context.applicationContext
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        if (!Settings.canDrawOverlays(appContext)) {
            if (askIfMissing) requestPermission(appContext)
            return
        }

        mainHandler.post {
            val manager = appContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            if (frameView == null) {
                attach(appContext, manager, count)
            } else {
                bind(count)
            }
        }
    }

    fun update(context: Context, count: Int) {
        show(context, count, askIfMissing = false)
    }

    fun hide(context: Context) {
        mainHandler.post {
            val view = frameView ?: return@post
            val manager = windowManager
            frameView = null
            brainView = null
            countLabel = null
            windowManager = null
            overlayParams = null
            shownMoodArt = 0
            try {
                manager?.removeView(view)
            } catch (_: Exception) {
            }
        }
    }

    private fun attach(context: Context, manager: WindowManager, count: Int) {
        val card = buildCard(context)
        val frame = FrameLayout(context).apply {
            setPadding(dp(context, 4), dp(context, 4), dp(context, 4), dp(context, 4))
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
            addView(card)
            setOnTouchListener { view, event -> drag(view, event) }
        }

        val metrics = context.resources.displayMetrics
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val defaultX = (metrics.widthPixels - dp(context, 100)).coerceAtLeast(0)
        val defaultY = dp(context, 96)
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = if (prefs.contains(KEY_X)) prefs.getInt(KEY_X, defaultX) else defaultX
            y = if (prefs.contains(KEY_Y)) prefs.getInt(KEY_Y, defaultY) else defaultY
        }

        try {
            manager.addView(frame, params)
            frameView = frame
            windowManager = manager
            overlayParams = params
            bind(count)
        } catch (_: Exception) {
            frameView = null
            windowManager = null
            overlayParams = null
        }
    }

    private fun buildCard(context: Context): View {
        val brain = ImageView(context).apply {
            layoutParams = LinearLayout.LayoutParams(dp(context, 32), dp(context, 32))
            scaleType = ImageView.ScaleType.FIT_CENTER
            setBackgroundColor(Color.TRANSPARENT)
        }
        brainView = brain

        val count = TextView(context).apply {
            setTextColor(Color.WHITE)
            textSize = 13f
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            includeFontPadding = false
            setShadowLayer(dp(context, 2).toFloat(), 0f, dp(context, 1).toFloat(), 0xCC000000.toInt())
        }
        countLabel = count

        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(Color.TRANSPARENT)
            setPadding(0, 0, dp(context, 2), 0)
            addView(brain)
            addView(count)
        }
    }

    private fun bind(count: Int) {
        val art = artFor(count)
        val countChanged = countLabel?.text?.toString() != count.toString()
        countLabel?.text = count.toString()
        if (shownMoodArt != art) {
            brainView?.setImageResource(art)
            shownMoodArt = art
            pop(brainView)
        }
        if (countChanged) pop(countLabel)
        frameView?.contentDescription = "$count reels"
    }

    private fun pop(view: View?) {
        val target = view ?: return
        target.animate().cancel()
        target.scaleX = 1.12f
        target.scaleY = 1.12f
        target.animate().scaleX(1f).scaleY(1f).setDuration(180).start()
    }

    private fun drag(view: View, event: MotionEvent): Boolean {
        val params = overlayParams ?: return false
        val manager = windowManager ?: return false
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                view.setTag(R.id.widget_root, floatArrayOf(event.rawX, event.rawY, params.x.toFloat(), params.y.toFloat()))
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                val origin = view.getTag(R.id.widget_root) as? FloatArray ?: return true
                val nextX = (origin[2] + event.rawX - origin[0]).toInt()
                val nextY = (origin[3] + event.rawY - origin[1]).toInt()
                val metrics = view.resources.displayMetrics
                params.x = nextX.coerceIn(0, (metrics.widthPixels - view.width).coerceAtLeast(0))
                params.y = nextY.coerceIn(0, (metrics.heightPixels - view.height).coerceAtLeast(0))
                try {
                    manager.updateViewLayout(view, params)
                } catch (_: Exception) {
                }
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                view.context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    .edit()
                    .putInt(KEY_X, params.x)
                    .putInt(KEY_Y, params.y)
                    .apply()
                return true
            }
        }
        return false
    }

    private fun artFor(count: Int): Int = when {
        count <= 20 -> R.drawable.brain_happy
        count <= 50 -> R.drawable.brain_neutral
        count <= 70 -> R.drawable.brain_sad
        count <= 100 -> R.drawable.brain_exhausted
        count <= 150 -> R.drawable.brain_dizzy
        else -> R.drawable.brain_fried
    }

    private fun requestPermission(context: Context) {
        if (askedForPermission) return
        askedForPermission = true
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    private fun dp(context: Context, value: Int): Int {
        return (value * context.resources.displayMetrics.density).toInt().coerceAtLeast(1)
    }
}
