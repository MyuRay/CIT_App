package jp.ac.chibakoudai.citapp.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import jp.ac.chibakoudai.citapp.MainActivity
import jp.ac.chibakoudai.citapp.R
import org.json.JSONObject
import org.json.JSONArray
import android.graphics.Color
import android.content.SharedPreferences
import android.os.Bundle
import kotlin.math.max
import kotlin.math.min

class TodayScheduleWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val TAG = "TodayScheduleWidget"
        private const val MAX_PERIODS = 10
        // AppWidgetOptions の高さはdp単位。高さに応じて表示行数を決める。
        private fun getMaxSlotsForHeight(heightDp: Int): Int {
            return when {
                heightDp < 140 -> 3
                heightDp < 190 -> 4
                heightDp < 240 -> 5
                heightDp < 290 -> 6
                heightDp < 340 -> 7
                heightDp < 390 -> 8
                heightDp < 440 -> 9
                else -> MAX_PERIODS
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            val options = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
                appWidgetManager.getAppWidgetOptions(id)
            } else null
            updateAppWidget(context, appWidgetManager, id, widgetData, options)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
        updateAppWidget(context, appWidgetManager, appWidgetId, widgetData, newOptions)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences,
        options: Bundle? = null
    ) {
        val views = RemoteViews(context.packageName, R.layout.today_schedule_widget)

        try {
            val today = widgetData.getString("today_schedule", "")

            if (today != null && today.isNotEmpty()) {
                try {
                    val obj = JSONObject(today)
                    // 高さ変更時は最大高さを優先して情報量を増やす
                    val maxSlots = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN && options != null) {
                        val maxH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 400)
                        getMaxSlotsForHeight(maxH)
                    } else MAX_PERIODS
                    val showEmptyRows = maxSlots >= 6
                    // 科目名優先のため、詳細は高さに余裕がある時のみ表示
                    val showDetail = maxSlots >= 7
                    populateToday(context, views, obj, maxSlots, showEmptyRows, showDetail)
                } catch (e: Exception) {
                    Log.e(TAG, "JSON parse error", e)
                    showEmpty(views)
                }
            } else {
                Log.d(TAG, "No data found for today_schedule")
                showEmpty(views)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading widget data", e)
            showEmpty(views)
        }

        // Tap to open app (時間割タブへ遷移)
        try {
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("citapp://schedule")
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Error setting click intent", e)
        }

        try {
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget", e)
        }
    }

    private fun showEmpty(views: RemoteViews) {
        try {
            views.setTextViewText(R.id.today_weekday, "")
            views.setTextViewText(R.id.today_date, "")
            views.setTextViewText(R.id.today_title, "今日の時間割")
            views.setViewVisibility(R.id.classes_container, android.view.View.GONE)
            views.setViewVisibility(R.id.empty_message, android.view.View.VISIBLE)
        } catch (e: Exception) {
            Log.e(TAG, "Error in showEmpty", e)
        }
    }

    private fun populateToday(
        context: Context,
        views: RemoteViews,
        today: JSONObject,
        maxSlots: Int,
        showEmptyRows: Boolean,
        showDetail: Boolean
    ) {
        try {
            // ヘッダー情報を設定
            val weekday = today.optString("weekday", "")
            val date = today.optString("date", "")
            val currentPeriod = today.optInt("currentPeriod", -1)
            val scheduleTitle = today.optString("scheduleTitle", "今日の時間割")

            views.setTextViewText(R.id.today_weekday, weekday)
            views.setTextViewText(R.id.today_date, date)
            views.setTextViewText(R.id.today_title, scheduleTitle)

            // period -> class のマップを構築
            val classByPeriod = mutableMapOf<Int, JSONObject>()
            val classes = if (today.has("classes")) today.getJSONArray("classes") else JSONArray()
            for (i in 0 until classes.length()) {
                val item = classes.getJSONObject(i)
                val period = item.optInt("period", 0)
                if (period in 1..MAX_PERIODS) {
                    classByPeriod[period] = item
                }
            }

            if (classByPeriod.isEmpty()) {
                views.setViewVisibility(R.id.classes_container, android.view.View.GONE)
                views.setViewVisibility(R.id.empty_message, android.view.View.VISIBLE)
                return
            }

            views.setViewVisibility(R.id.classes_container, android.view.View.VISIBLE)
            views.setViewVisibility(R.id.empty_message, android.view.View.GONE)
            views.removeAllViews(R.id.classes_container)

            // 1限〜maxSlots限を表示。連続コマは1つのセルとしてまとめる。
            var period = 1
            while (period <= maxSlots) {
                val item = classByPeriod[period]
                if (item != null) {
                    val endFromData = item.optInt("endPeriod", period)
                    val duration = item.optInt("duration", 1).coerceAtLeast(1)
                    val actualEndPeriod = maxOf(endFromData, period + duration - 1).coerceIn(period, MAX_PERIODS)
                    val visibleEndPeriod = min(actualEndPeriod, maxSlots)
                    views.addView(
                        R.id.classes_container,
                        createClassRow(
                            context,
                            period,
                            actualEndPeriod,
                            item,
                            currentPeriod,
                            showDetail,
                            visibleEndPeriod - period + 1
                        )
                    )
                    period = visibleEndPeriod + 1
                } else {
                    if (showEmptyRows) {
                        views.addView(R.id.classes_container, createEmptyRow(context, period))
                    }
                    period += 1
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in populateToday", e)
            showEmpty(views)
        }
    }

    private fun createClassRow(
        context: Context,
        startPeriod: Int,
        endPeriod: Int,
        item: JSONObject,
        currentPeriod: Int,
        showDetail: Boolean,
        blockSpan: Int
    ): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.item_today_class)
        val subject = item.optString("subject", "")
        val room = item.optString("classroom", "")
        val colorHex = item.optString("color", "#2196F3")
        val startTime = item.optString("startTime", "")
        val endTime = item.optString("endTime", "")

        val periodLabel = if (endPeriod > startPeriod) {
            "${startPeriod}-${endPeriod}限"
        } else {
            "${startPeriod}限"
        }
        row.setTextViewText(R.id.text_period, periodLabel)
        row.setTextViewText(R.id.text_subject, subject)
        if (showDetail && room.isNotEmpty()) {
            row.setTextViewText(R.id.text_classroom, room)
            row.setViewVisibility(R.id.text_classroom, android.view.View.VISIBLE)
        } else {
            row.setViewVisibility(R.id.text_classroom, android.view.View.GONE)
        }
        val timeText = if (startTime.isNotEmpty() && endTime.isNotEmpty()) "$startTime-$endTime" else ""
        if (timeText.isNotEmpty()) {
            row.setTextViewText(R.id.text_time, timeText)
            row.setViewVisibility(R.id.text_time, android.view.View.VISIBLE)
        } else {
            row.setViewVisibility(R.id.text_time, android.view.View.GONE)
        }

        val accentColor = parseColorOrDefault(colorHex, Color.parseColor("#2196F3"))
        val periodBadgeColor = enhanceBadgeColor(accentColor)
        val periodTextColor = pickHighContrastTextColor(periodBadgeColor)

        row.setInt(R.id.color_dot, "setBackgroundColor", periodBadgeColor)
        row.setInt(R.id.text_period, "setBackgroundColor", periodBadgeColor)
        row.setTextColor(R.id.text_period, periodTextColor)

        if (currentPeriod > 0 && currentPeriod in startPeriod..endPeriod) {
            try {
                row.setInt(R.id.item_root, "setBackgroundColor", Color.parseColor("#E3F2FD"))
            } catch (_: Exception) {}
        }

        row.setInt(
            R.id.item_root,
            "setMinimumHeight",
            dpToPx(context, blockMinHeightDp(blockSpan))
        )

        val intent = Intent(context, MainActivity::class.java)
        intent.putExtra("open_schedule", true)
        intent.putExtra("open_period", startPeriod)
        intent.data = Uri.parse("citapp://schedule")
        intent.action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        val pending = PendingIntent.getActivity(
            context, startPeriod, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        row.setOnClickPendingIntent(R.id.item_root, pending)
        return row
    }

    private fun parseColorOrDefault(colorHex: String, fallback: Int): Int {
        return try {
            Color.parseColor(colorHex)
        } catch (_: Exception) {
            fallback
        }
    }

    // 彩度/明度を補正して、淡い色でも時限バッジとして識別しやすくする
    private fun enhanceBadgeColor(color: Int): Int {
        val hsv = FloatArray(3)
        Color.colorToHSV(color, hsv)
        hsv[1] = max(0.65f, hsv[1])
        hsv[2] = min(0.80f, max(0.35f, hsv[2]))
        return Color.HSVToColor(hsv)
    }

    private fun pickHighContrastTextColor(bgColor: Int): Int {
        val whiteContrast = contrastRatio(bgColor, Color.WHITE)
        val blackContrast = contrastRatio(bgColor, Color.BLACK)
        return if (whiteContrast >= blackContrast) Color.WHITE else Color.BLACK
    }

    private fun contrastRatio(c1: Int, c2: Int): Double {
        val l1 = relativeLuminance(c1)
        val l2 = relativeLuminance(c2)
        val lighter = max(l1, l2)
        val darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private fun relativeLuminance(color: Int): Double {
        fun linear(channel: Int): Double {
            val v = channel / 255.0
            return if (v <= 0.03928) v / 12.92 else Math.pow((v + 0.055) / 1.055, 2.4)
        }
        val r = linear(Color.red(color))
        val g = linear(Color.green(color))
        val b = linear(Color.blue(color))
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    private fun createEmptyRow(context: Context, period: Int): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.item_today_class_empty)
        row.setTextViewText(R.id.text_period, "${period}限")

        val intent = Intent(context, MainActivity::class.java)
        intent.putExtra("open_schedule", true)
        intent.data = Uri.parse("citapp://schedule")
        intent.action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        val pending = PendingIntent.getActivity(
            context, period + 100, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        row.setOnClickPendingIntent(R.id.item_root, pending)
        return row
    }

    private fun blockMinHeightDp(blockSpan: Int): Int {
        val span = blockSpan.coerceAtLeast(1)
        return (36 * span) + (6 * (span - 1))
    }

    private fun dpToPx(context: Context, dp: Int): Int {
        return (dp * context.resources.displayMetrics.density).toInt()
    }
}
