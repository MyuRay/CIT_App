package jp.ac.chibakoudai.citapp.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import jp.ac.chibakoudai.citapp.MainActivity
import jp.ac.chibakoudai.citapp.R
import org.json.JSONObject
import org.json.JSONArray
import android.graphics.Color

class FullScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.weekly_full_schedule_widget)

        try {
            val data = HomeWidgetPlugin.getData(context)
            val weekly = data.getString("weekly_full_schedule", "")

            if (weekly?.isNotEmpty() == true) {
                val obj = JSONObject(weekly)
                populateWeekly(context, views, obj)
            } else {
                views.setTextViewText(R.id.weekly_title, "週間時間割")
            }
        } catch (e: Exception) {
            views.setTextViewText(R.id.weekly_title, "週間時間割")
        }

        // Tap to open app
        val intent = Intent(context, MainActivity::class.java)
        intent.putExtra("open_schedule", true)
        val pendingIntent = PendingIntent.getActivity(
            context, appWidgetId, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun populateWeekly(context: Context, views: RemoteViews, weekly: JSONObject) {
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

            val hasDay = weekly.has(key)
            val arr = if (hasDay) weekly.getJSONArray(key) else JSONArray()

            // 土曜日のみ、授業がない場合は列ごと非表示
            if (key == "saturday" && (arr.length() == 0)) {
                views.setViewVisibility(containerId, android.view.View.GONE)
                continue
            } else {
                views.setViewVisibility(containerId, android.view.View.VISIBLE)
            }

            val maxItems = 10
            val count = kotlin.math.min(arr.length(), maxItems)
            for (j in 0 until count) {
                val item = arr.getJSONObject(j)
                val period = item.optInt("period", 0)
                val subject = item.optString("subject", "")
                val room = item.optString("classroom", "")
                val colorHex = item.optString("color", "#2196F3")

                val row = RemoteViews(context.packageName, R.layout.item_weekly_class)
                row.setTextViewText(R.id.text_subject, "[$period] $subject")
                row.setTextViewText(R.id.text_room, room)
                try {
                    row.setInt(R.id.color_dot, "setBackgroundColor", Color.parseColor(colorHex))
                } catch (_: Exception) {}

                // 行クリックでアプリ起動（対象曜日・時限を渡す）
                val intent = Intent(context, MainActivity::class.java)
                intent.putExtra("open_schedule", true)
                intent.putExtra("open_day", label)
                intent.putExtra("open_period", period)
                val requestCode = (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
                val pending = PendingIntent.getActivity(
                    context, requestCode, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                row.setOnClickPendingIntent(R.id.item_root, pending)

                views.addView(listId, row)
            }
        }
    }
}
