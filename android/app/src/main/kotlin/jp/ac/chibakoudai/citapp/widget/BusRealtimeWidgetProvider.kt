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

class BusRealtimeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.bus_realtime_widget)

        try {
            val data = HomeWidgetPlugin.getData(context)
            val bus = data.getString("bus_realtime", "")

            if (bus?.isNotEmpty() == true) {
                val obj = JSONObject(bus)
                populateBus(context, views, obj)
            } else {
                showEmpty(views)
            }
        } catch (e: Exception) {
            showEmpty(views)
        }

        val intent = Intent(context, MainActivity::class.java)
        intent.putExtra("open_schedule", false)
        val pendingIntent = PendingIntent.getActivity(
            context, appWidgetId, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

        // Refresh button: open app to refresh (simple behavior)
        val refreshIntent = Intent(context, MainActivity::class.java)
        val refreshPending = PendingIntent.getActivity(
            context, appWidgetId + 1000, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_refresh, refreshPending)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun showEmpty(views: RemoteViews) {
        views.setTextViewText(R.id.bus_title, "学バス情報")
        views.setViewVisibility(R.id.route_1_container, android.view.View.GONE)
        views.setViewVisibility(R.id.route_2_container, android.view.View.GONE)
        views.setTextViewText(R.id.bus_footer, "データなし")
    }

    private fun populateBus(context: Context, views: RemoteViews, obj: JSONObject) {
        views.setTextViewText(R.id.bus_title, "学バス情報")
        val routes = if (obj.has("routes")) obj.getJSONArray("routes") else JSONArray()

        fun setRow(index: Int, visible: Boolean, name: String = "", timeText: String = "") {
            val contId = if (index == 0) R.id.route_1_container else R.id.route_2_container
            val nameId = if (index == 0) R.id.route_1_name else R.id.route_2_name
            val timeId = if (index == 0) R.id.route_1_time else R.id.route_2_time
            views.setViewVisibility(contId, if (visible) android.view.View.VISIBLE else android.view.View.GONE)
            if (visible) {
                views.setTextViewText(nameId, name)
                views.setTextViewText(timeId, timeText)
            }
        }

        if (routes.length() >= 1) {
            val r0 = routes.getJSONObject(0)
            val name = r0.optString("name", "")
            val nextTime = r0.optString("nextTime", "--:--")
            val minutes = r0.optInt("minutesUntil", -1)
            val note = r0.optString("note", "")
            val info = if (minutes >= 0) "$nextTime (${minutes}分後)" else nextTime
            val text = if (note.isNotEmpty()) "$info  [$note]" else info
            setRow(0, true, name, text)
        } else setRow(0, false)

        if (routes.length() >= 2) {
            val r1 = routes.getJSONObject(1)
            val name = r1.optString("name", "")
            val nextTime = r1.optString("nextTime", "--:--")
            val minutes = r1.optInt("minutesUntil", -1)
            val note = r1.optString("note", "")
            val info = if (minutes >= 0) "$nextTime (${minutes}分後)" else nextTime
            val text = if (note.isNotEmpty()) "$info  [$note]" else info
            setRow(1, true, name, text)
        } else setRow(1, false)

        views.setTextViewText(R.id.bus_footer, "")
    }
}
