package jp.ac.chibakoudai.citapp.widget

import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

internal object WidgetSnapshot {
    private val japan = TimeZone.getTimeZone("Asia/Tokyo")
    fun nextJapanMidnight(now: Long = System.currentTimeMillis()): Long =
        Calendar.getInstance(japan).apply {
            timeInMillis = now
            add(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

    fun periodTimes(snapshot: JSONObject, period: Int): Pair<String, String> {
        val slots = snapshot.optJSONArray("timeSlots") ?: JSONArray()
        for (i in 0 until slots.length()) {
            val slot = slots.optJSONObject(i) ?: continue
            if (slot.optInt("period") == period) {
                return slot.optString("startTime") to slot.optString("endTime")
            }
        }
        // Older snapshots contain only the outer boundaries of each lecture.
        // Do not guess intermediate times for a custom timetable.
        var start = ""
        var end = ""
        for (day in listOf("monday", "tuesday", "wednesday", "thursday", "friday", "saturday")) {
            val lessons = snapshot.optJSONArray(day) ?: continue
            for (i in 0 until lessons.length()) {
                val lesson = lessons.optJSONObject(i) ?: continue
                if (start.isEmpty() && lesson.optInt("period") == period) start = lesson.optString("startTime")
                if (end.isEmpty() && lesson.optInt("endPeriod") == period) end = lesson.optString("endTime")
            }
        }
        return start to end
    }
    fun timeLabel(start: String, end: String, separator: String = "–"): String =
        "${start.ifEmpty { "--:--" }}$separator${end.ifEmpty { "--:--" }}"

    fun minutes(now: Long = System.currentTimeMillis()): Int {
        val calendar = Calendar.getInstance(japan).apply { timeInMillis = now }
        return calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
    }
    fun timeMinutes(value: String): Int? {
        val parts = value.split(":")
        if (parts.size != 2) return null
        val hour = parts[0].toIntOrNull() ?: return null
        val minute = parts[1].toIntOrNull() ?: return null
        return if (hour in 0..23 && minute in 0..59) hour * 60 + minute else null
    }
    fun today(data: SharedPreferences, now: Long = System.currentTimeMillis()): JSONObject {
        val weekly = JSONObject(data.getString("weekly_full_schedule", "{}") ?: "{}")
        return today(weekly, now)
    }
    fun today(weekly: JSONObject, now: Long = System.currentTimeMillis()): JSONObject {
        val calendar = Calendar.getInstance(japan).apply { timeInMillis = now }
        val index = (calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7
        val days = listOf("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday")
        val classes = weekly.optJSONArray(days[index]) ?: JSONArray()
        var currentPeriod = -1
        for (i in 0 until classes.length()) {
            val item = classes.getJSONObject(i)
            val start = timeMinutes(item.optString("startTime")) ?: continue
            val end = timeMinutes(item.optString("endTime")) ?: continue
            if (minutes(now) in start until end) currentPeriod = item.optInt("period")
        }
        return JSONObject().apply {
            put("classes", classes)
            put("timeSlots", weekly.optJSONArray("timeSlots") ?: JSONArray())
            put("hasSchedule", weekly.optBoolean("hasSchedule", false))
            put("weekday", listOf("月", "火", "水", "木", "金", "土", "日")[index])
            put("date", "${calendar.get(Calendar.MONTH) + 1}/${calendar.get(Calendar.DAY_OF_MONTH)}")
            put("scheduleTitle", weekly.optString("scheduleTitle", "今日の時間割"))
            put("currentPeriod", currentPeriod)
            put("updatedAt", weekly.optLong("updatedAt"))
        }
    }
    fun updatedLabel(epoch: Long): String {
        if (epoch <= 0) return "アプリを開いて更新"
        val format = SimpleDateFormat("M/d HH:mm", Locale.JAPAN).apply { timeZone = japan }
        return "${format.format(Date(epoch))} 更新"
    }
}
