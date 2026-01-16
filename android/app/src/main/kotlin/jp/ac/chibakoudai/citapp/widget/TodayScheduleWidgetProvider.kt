package jp.ac.chibakoudai.citapp.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import jp.ac.chibakoudai.citapp.MainActivity
import jp.ac.chibakoudai.citapp.R
import org.json.JSONObject
import org.json.JSONArray
import android.graphics.Color

class TodayScheduleWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val TAG = "TodayScheduleWidget"
    }
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.today_schedule_widget)

        try {
            val data = HomeWidgetPlugin.getData(context)
            val today = data.getString("today_schedule", "")

            if (today != null && today.isNotEmpty()) {
                try {
                    val obj = JSONObject(today)
                    populateToday(context, views, obj)
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

        // Tap to open app
        try {
            val intent = Intent(context, MainActivity::class.java)
            intent.putExtra("open_schedule", true)
            val pendingIntent = PendingIntent.getActivity(
                context, appWidgetId, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
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

    private fun populateToday(context: Context, views: RemoteViews, today: JSONObject) {
        try {
            // ヘッダー情報を設定
            val weekday = today.optString("weekday", "")
            val date = today.optString("date", "")
            val currentPeriod = today.optInt("currentPeriod", -1)

            views.setTextViewText(R.id.today_weekday, weekday)
            views.setTextViewText(R.id.today_date, date)
            views.setTextViewText(R.id.today_title, "今日の時間割")

            // 授業リストをクリア
            views.removeAllViews(R.id.classes_container)

            val classes = if (today.has("classes")) today.getJSONArray("classes") else JSONArray()

            if (classes.length() == 0) {
                views.setViewVisibility(R.id.classes_container, android.view.View.GONE)
                views.setViewVisibility(R.id.empty_message, android.view.View.VISIBLE)
                return
            }

            views.setViewVisibility(R.id.classes_container, android.view.View.VISIBLE)
            views.setViewVisibility(R.id.empty_message, android.view.View.GONE)

            // 最大5件まで表示（中サイズウィジェット用）
            val maxItems = 5
            val count = kotlin.math.min(classes.length(), maxItems)

            for (i in 0 until count) {
                try {
                    val item = classes.getJSONObject(i)
                    val period = item.optInt("period", 0)
                    val subject = item.optString("subject", "")
                    val room = item.optString("classroom", "")
                    val colorHex = item.optString("color", "#2196F3")
                    val startTime = item.optString("startTime", "")
                    val endTime = item.optString("endTime", "")
                    val duration = item.optInt("duration", 1)

                    val row = RemoteViews(context.packageName, R.layout.item_today_class)
                    
                    // 時限表示
                    row.setTextViewText(R.id.text_period, "${period}限")
                    
                    // 科目名
                    row.setTextViewText(R.id.text_subject, subject)
                    
                    // 教室
                    if (room.isNotEmpty()) {
                        row.setTextViewText(R.id.text_classroom, room)
                        row.setViewVisibility(R.id.text_classroom, android.view.View.VISIBLE)
                    } else {
                        row.setViewVisibility(R.id.text_classroom, android.view.View.GONE)
                    }
                    
                    // 時間表示
                    val timeText = if (startTime.isNotEmpty() && endTime.isNotEmpty()) {
                        "$startTime-$endTime"
                    } else {
                        ""
                    }
                    row.setTextViewText(R.id.text_time, timeText)
                    
                    // 色の設定
                    try {
                        row.setInt(R.id.color_dot, "setBackgroundColor", Color.parseColor(colorHex))
                    } catch (_: Exception) {
                        // 色のパースに失敗した場合はデフォルト色を使用
                        row.setInt(R.id.color_dot, "setBackgroundColor", Color.parseColor("#2196F3"))
                    }

                    // 現在の時限をハイライト（背景色を変更）
                    if (currentPeriod > 0 && period == currentPeriod) {
                        try {
                            row.setInt(R.id.item_root, "setBackgroundColor", Color.parseColor("#E3F2FD"))
                        } catch (_: Exception) {}
                    }

                    // 行クリックでアプリ起動（時間割画面を開く）
                    val intent = Intent(context, MainActivity::class.java)
                    intent.putExtra("open_schedule", true)
                    val requestCode = (System.currentTimeMillis() % Int.MAX_VALUE).toInt() + i
                    val pending = PendingIntent.getActivity(
                        context, requestCode, intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    row.setOnClickPendingIntent(R.id.item_root, pending)

                    views.addView(R.id.classes_container, row)
                } catch (e: Exception) {
                    Log.e(TAG, "Error adding class item $i", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in populateToday", e)
            showEmpty(views)
        }
    }
}
