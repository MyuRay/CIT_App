package jp.ac.chibakoudai.citapp.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import jp.ac.chibakoudai.citapp.MainActivity
import jp.ac.chibakoudai.citapp.R
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.min

class TodayScheduleWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val TAG = "TodayScheduleWidget"
        private const val MAX_PERIODS = 10
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray, data: SharedPreferences) {
        for (id in ids) update(context, manager, id, data, manager.getAppWidgetOptions(id))
        ScheduleWidgetRefreshReceiver.scheduleNext(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        ScheduleWidgetRefreshReceiver.scheduleNext(context)
    }

    override fun onDisabled(context: Context) {
        ScheduleWidgetRefreshReceiver.cancel(context)
        super.onDisabled(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        update(context, manager, id, HomeWidgetPlugin.getData(context), options)
        ScheduleWidgetRefreshReceiver.scheduleNext(context)
    }

    private fun update(context: Context, manager: AppWidgetManager, id: Int, data: SharedPreferences, options: Bundle) {
        val today = try {
            WidgetSnapshot.today(data)
        } catch (error: Exception) {
            Log.e(TAG, "Unable to read today's schedule", error)
            JSONObject()
        }
        try {
            manager.updateAppWidget(id, buildViews(context, today, options))
        } catch (error: Exception) {
            Log.e(TAG, "Unable to update today's widget", error)
        }
    }

    /** Uses the whole saved day; current time only affects the active-lecture highlight. */
    internal fun buildViews(context: Context, today: JSONObject, options: Bundle = Bundle()): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.today_schedule_widget)
        val density = context.resources.displayMetrics.density
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250).coerceAtLeast(160)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 180).coerceAtLeast(120)
        val showUpdated = height >= 180
        val contentHeight = height - if (showUpdated) 58 else 42
        val classes = today.optJSONArray("classes") ?: JSONArray()
        val byPeriod = sortedMapOf<Int, JSONObject>()
        for (index in 0 until classes.length()) {
            val lesson = classes.optJSONObject(index) ?: continue
            val period = lesson.optInt("period")
            if (period in 1..MAX_PERIODS) byPeriod[period] = lesson
        }
        val lessons = byPeriod.values.toList()
        val columnCount = if (lessons.size > 1 && contentHeight / lessons.size < 28 && width >= 160) 2 else 1
        val rowsPerColumn = (lessons.size + columnCount - 1) / columnCount
        val rowHeight = min(72f, contentHeight.toFloat() / rowsPerColumn.coerceAtLeast(1) - 2).coerceAtLeast(12f)

        views.setTextViewText(R.id.today_weekday, today.optString("weekday"))
        views.setTextViewText(R.id.today_date, today.optString("date"))
        views.setTextViewText(R.id.today_title, today.optString("scheduleTitle", "今日の時間割"))
        // Keep the heading within its reserved space, including at large system font sizes.
        views.setTextViewTextSize(R.id.today_weekday, TypedValue.COMPLEX_UNIT_PX, 15 * density)
        views.setTextViewTextSize(R.id.today_date, TypedValue.COMPLEX_UNIT_PX, 12 * density)
        views.setTextViewTextSize(R.id.today_title, TypedValue.COMPLEX_UNIT_PX, 12 * density)
        views.setTextViewTextSize(R.id.today_updated, TypedValue.COMPLEX_UNIT_PX, 9 * density)
        views.setTextViewText(R.id.today_updated, WidgetSnapshot.updatedLabel(today.optLong("updatedAt")))
        views.setViewVisibility(R.id.today_updated, if (showUpdated) View.VISIBLE else View.GONE)
        views.removeAllViews(R.id.classes_container)
        views.setViewVisibility(R.id.classes_container, if (lessons.isEmpty()) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.empty_message, if (lessons.isEmpty()) View.VISIBLE else View.GONE)
        views.setTextViewText(R.id.empty_message,
            if (today.optBoolean("hasSchedule")) "今日は授業がありません" else "アプリで時間割を選択してください")
        for (columnIndex in 0 until columnCount) {
            val column = RemoteViews(context.packageName, R.layout.today_schedule_column)
            val start = columnIndex * rowsPerColumn
            for (index in start until min(start + rowsPerColumn, lessons.size)) {
                column.addView(R.id.today_column,
                    createClassRow(context, lessons[index], today.optInt("currentPeriod", -1), rowHeight))
            }
            views.addView(R.id.classes_container, column)
        }
        views.setOnClickPendingIntent(R.id.widget_container,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("citapp://schedule")))
        return views
    }

    private fun createClassRow(context: Context, lesson: JSONObject, currentPeriod: Int, rowHeight: Float): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.item_today_class)
        val period = lesson.optInt("period")
        val endPeriod = lesson.optInt("endPeriod", period).coerceIn(period, MAX_PERIODS)
        val periodLabel = if (endPeriod > period) "$period–${endPeriod}限" else "${period}限"
        val subject = lesson.optString("subject")
        val room = lesson.optString("classroom")
        val start = lesson.optString("startTime")
        val end = lesson.optString("endTime")
        val current = currentPeriod in period..endPeriod
        val density = context.resources.displayMetrics.density
        val scale = context.resources.configuration.fontScale
        val timeSize = min(10f * scale, min(12f, rowHeight * 0.40f))
        val subjectSize = min(13f * scale, rowHeight * 0.43f)
        val roomSize = min(10f * scale, rowHeight * 0.37f)
        row.setTextViewText(R.id.text_subject, "$periodLabel $subject")
        row.setTextViewText(R.id.text_classroom, if (current) "授業中${if (room.isEmpty()) "" else " · $room"}" else room)
        row.setViewVisibility(R.id.text_classroom, if (current || room.isNotEmpty()) View.VISIBLE else View.GONE)
        row.setTextViewText(R.id.text_time, WidgetSnapshot.timeLabel(start, end, "\n"))
        row.setTextViewTextSize(R.id.text_time, TypedValue.COMPLEX_UNIT_PX, timeSize * density)
        row.setTextViewTextSize(R.id.text_subject, TypedValue.COMPLEX_UNIT_PX, subjectSize * density)
        row.setTextViewTextSize(R.id.text_classroom, TypedValue.COMPLEX_UNIT_PX, roomSize * density)
        row.setInt(R.id.text_time, "setWidth", ((timeSize * 3.2f + 2) * density).toInt())
        row.setInt(R.id.text_time, "setHeight", (rowHeight * density).toInt())
        row.setContentDescription(R.id.item_root,
            "$periodLabel、${WidgetSnapshot.timeLabel(start, end)}、$subject、$room${if (current) "、授業中" else ""}")
        val color = try { Color.parseColor(lesson.optString("color", "#2196F3")) } catch (_: Exception) { Color.BLUE }
        row.setInt(R.id.color_dot, "setBackgroundColor", color)
        if (current) row.setInt(R.id.item_root, "setBackgroundColor", context.getColor(R.color.widget_current_background))
        val intent = Intent(context, MainActivity::class.java).apply {
            putExtra("open_schedule", true)
            putExtra("open_period", period)
            data = Uri.parse("citapp://schedule")
            action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        }
        row.setOnClickPendingIntent(R.id.item_root, PendingIntent.getActivity(context, period, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        return row
    }
}
