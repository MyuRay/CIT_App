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

            // 1限〜maxSlots限をスロット表示（空き時限も行として表示し正しい位置に配置）
            for (period in 1..maxSlots) {
                val item = classByPeriod[period]
                val row = if (item != null) {
                    createClassRow(context, period, item, currentPeriod, showDetail)
                } else {
                    if (showEmptyRows) createEmptyRow(context, period) else null
                }
                if (row != null) {
                    views.addView(R.id.classes_container, row)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in populateToday", e)
            showEmpty(views)
        }
    }

    private fun createClassRow(
        context: Context,
        period: Int,
        item: JSONObject,
        currentPeriod: Int,
        showDetail: Boolean
    ): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.item_today_class)
        val subject = item.optString("subject", "")
        val room = item.optString("classroom", "")
        val colorHex = item.optString("color", "#2196F3")
        val startTime = item.optString("startTime", "")
        val endTime = item.optString("endTime", "")

        row.setTextViewText(R.id.text_period, "${period}限")
        row.setTextViewText(R.id.text_subject, subject)
        if (showDetail && room.isNotEmpty()) {
            row.setTextViewText(R.id.text_classroom, room)
            row.setViewVisibility(R.id.text_classroom, android.view.View.VISIBLE)
        } else {
            row.setViewVisibility(R.id.text_classroom, android.view.View.GONE)
        }
        if (showDetail) {
            val timeText = if (startTime.isNotEmpty() && endTime.isNotEmpty()) "$startTime-$endTime" else ""
            row.setTextViewText(R.id.text_time, timeText)
            row.setViewVisibility(R.id.text_time, android.view.View.VISIBLE)
        } else {
            row.setViewVisibility(R.id.text_time, android.view.View.GONE)
        }

        try {
            row.setInt(R.id.color_dot, "setBackgroundColor", Color.parseColor(colorHex))
        } catch (_: Exception) {
            row.setInt(R.id.color_dot, "setBackgroundColor", Color.parseColor("#2196F3"))
        }

        if (currentPeriod > 0 && period == currentPeriod) {
            try {
                row.setInt(R.id.item_root, "setBackgroundColor", Color.parseColor("#E3F2FD"))
            } catch (_: Exception) {}
        }

        val intent = Intent(context, MainActivity::class.java)
        intent.putExtra("open_schedule", true)
        intent.data = Uri.parse("citapp://schedule")
        intent.action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        val pending = PendingIntent.getActivity(
            context, period, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        row.setOnClickPendingIntent(R.id.item_root, pending)
        return row
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
}
