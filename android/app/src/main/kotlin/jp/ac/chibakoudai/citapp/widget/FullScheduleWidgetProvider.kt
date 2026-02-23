package jp.ac.chibakoudai.citapp.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import android.os.Build
import android.os.Bundle
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import jp.ac.chibakoudai.citapp.MainActivity
import jp.ac.chibakoudai.citapp.R
import org.json.JSONObject
import org.json.JSONArray
import android.graphics.Color
import android.content.SharedPreferences

class FullScheduleWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val MAX_PERIODS = 10
        // ウィジェット高さ（px）に応じた表示スロット数（1-10限まで対応、閾値を低めにして余白を有効活用）
        private fun getMaxSlotsForHeight(heightPx: Int): Int {
            return when {
                heightPx < 100 -> 2
                heightPx < 160 -> 3
                heightPx < 220 -> 4
                heightPx < 280 -> 5
                heightPx < 340 -> 6
                heightPx < 400 -> 7
                heightPx < 460 -> 8
                heightPx < 520 -> 9
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
        val views = RemoteViews(context.packageName, R.layout.weekly_full_schedule_widget)

        try {
            val weekly = widgetData.getString("weekly_full_schedule", "")

            if (weekly != null && weekly.isNotEmpty()) {
                val obj = JSONObject(weekly)
                // 縦向きではMAX_HEIGHTが実際の高さ。min/maxの大きい方を使い余白を減らす
                val maxSlots = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN && options != null) {
                    val minH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 400)
                    val maxH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 400)
                    val h = maxOf(minH, maxH)
                    getMaxSlotsForHeight(h)
                } else MAX_PERIODS
                populateWeekly(context, views, obj, maxSlots)
            } else {
                views.setTextViewText(R.id.weekly_title, "週間時間割")
            }
        } catch (e: Exception) {
            views.setTextViewText(R.id.weekly_title, "週間時間割")
        }

        val pendingIntent = HomeWidgetLaunchIntent.getActivity(
            context, MainActivity::class.java, Uri.parse("citapp://schedule")
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun populateWeekly(
        context: Context,
        views: RemoteViews,
        weekly: JSONObject,
        maxSlots: Int
    ) {
        views.setTextViewText(R.id.weekly_title, "週間時間割")

        val weekdays = arrayOf("monday", "tuesday", "wednesday", "thursday", "friday", "saturday")
        val labels = arrayOf("月", "火", "水", "木", "金", "土")
        val containers = arrayOf(
            R.id.monday_container, R.id.tuesday_container, R.id.wednesday_container,
            R.id.thursday_container, R.id.friday_container, R.id.saturday_container
        )
        val classLists = arrayOf(
            R.id.monday_classes, R.id.tuesday_classes, R.id.wednesday_classes,
            R.id.thursday_classes, R.id.friday_classes, R.id.saturday_classes
        )
        val labelIds = arrayOf(
            R.id.monday_label, R.id.tuesday_label, R.id.wednesday_label,
            R.id.thursday_label, R.id.friday_label, R.id.saturday_label
        )

        for (i in weekdays.indices) {
            val key = weekdays[i]
            val label = labels[i]
            val containerId = containers[i]
            val listId = classLists[i]
            val labelId = labelIds[i]

            views.setTextViewText(labelId, label)
            views.removeAllViews(listId)

            // period -> class のマップを構築
            val classByPeriod = mutableMapOf<Int, JSONObject>()
            val arr = if (weekly.has(key)) weekly.getJSONArray(key) else JSONArray()
            for (j in 0 until arr.length()) {
                val item = arr.getJSONObject(j)
                val period = item.optInt("period", 0)
                if (period in 1..MAX_PERIODS) {
                    classByPeriod[period] = item
                }
            }

            // 土曜日のみ、授業がない場合は列ごと非表示
            if (key == "saturday" && classByPeriod.isEmpty()) {
                views.setViewVisibility(containerId, android.view.View.GONE)
                continue
            }
            views.setViewVisibility(containerId, android.view.View.VISIBLE)

            // 1限〜maxSlots限をスロット表示（空き時限も行として表示し正しい位置に配置）
            for (period in 1..maxSlots) {
                val item = classByPeriod[period]
                val row = if (item != null) {
                    createClassRow(context, period, item, label)
                } else {
                    createEmptyRow(context, period, label)
                }
                views.addView(listId, row)
            }
        }
    }

    private fun createClassRow(
        context: Context,
        period: Int,
        item: JSONObject,
        dayLabel: String
    ): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.item_weekly_class)
        val subject = item.optString("subject", "")
        val room = item.optString("classroom", "")
        val colorHex = item.optString("color", "#2196F3")

        row.setTextViewText(R.id.text_subject, "[$period] $subject")
        row.setTextViewText(R.id.text_room, room)
        try {
            row.setInt(R.id.color_dot, "setBackgroundColor", Color.parseColor(colorHex))
        } catch (_: Exception) {
            row.setInt(R.id.color_dot, "setBackgroundColor", Color.parseColor("#2196F3"))
        }

        val intent = Intent(context, MainActivity::class.java)
        intent.putExtra("open_schedule", true)
        intent.putExtra("open_day", dayLabel)
        intent.putExtra("open_period", period)
        intent.data = Uri.parse("citapp://schedule")
        intent.action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        val pending = PendingIntent.getActivity(
            context, (dayLabel.hashCode() and 0xFFFF) * 10 + period, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        row.setOnClickPendingIntent(R.id.item_root, pending)
        return row
    }

    private fun createEmptyRow(context: Context, period: Int, dayLabel: String): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.item_weekly_class_empty)
        row.setTextViewText(R.id.text_subject, "[$period] —")

        val intent = Intent(context, MainActivity::class.java)
        intent.putExtra("open_schedule", true)
        intent.putExtra("open_day", dayLabel)
        intent.putExtra("open_period", period)
        intent.data = Uri.parse("citapp://schedule")
        intent.action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        val pending = PendingIntent.getActivity(
            context, (dayLabel.hashCode() and 0xFFFF) * 10 + period + 1000, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        row.setOnClickPendingIntent(R.id.item_root, pending)
        return row
    }
}
