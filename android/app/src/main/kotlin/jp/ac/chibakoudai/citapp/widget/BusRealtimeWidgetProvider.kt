package jp.ac.chibakoudai.citapp.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import jp.ac.chibakoudai.citapp.MainActivity
import jp.ac.chibakoudai.citapp.R
import org.json.JSONArray
import org.json.JSONObject

class BusRealtimeWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) update(context, manager, id)
    }
    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        update(context, manager, id)
    }
    private fun update(context: Context, manager: AppWidgetManager, id: Int) {
        val views = RemoteViews(context.packageName, R.layout.bus_realtime_widget)
        views.setTextViewText(R.id.bus_title, "学バス · 次の便")
        views.setViewVisibility(R.id.route_1_container, View.GONE)
        views.setViewVisibility(R.id.route_2_container, View.GONE)
        views.setTextViewText(R.id.bus_footer, "アプリを開いて時刻表を更新")
        try {
            val payload = JSONObject(HomeWidgetPlugin.getData(context).getString("bus_realtime", "{}") ?: "{}")
            val now = System.currentTimeMillis()
            if (payload.optLong("expiresAt") > now) {
                val routes = payload.optJSONArray("routes") ?: JSONArray()
                for (i in 0 until minOf(2, routes.length())) {
                    val route = routes.getJSONObject(i)
                    val departures = route.optJSONArray("departures") ?: JSONArray()
                    var next: JSONObject? = null
                    for (j in 0 until departures.length()) {
                        val departure = departures.getJSONObject(j)
                        if (departure.optLong("departureAt") > now) { next = departure; break }
                    }
                    val container = if (i == 0) R.id.route_1_container else R.id.route_2_container
                    val name = if (i == 0) R.id.route_1_name else R.id.route_2_name
                    val time = if (i == 0) R.id.route_1_time else R.id.route_2_time
                    views.setViewVisibility(container, View.VISIBLE)
                    views.setTextViewText(name, route.optString("name"))
                    // Absolute time stays honest when Android delays widget updates.
                    val label = if (next == null) "本日の運行は終了" else "${next.optString("time")} 発"
                    views.setTextViewText(time, label)
                }
                val updated = WidgetSnapshot.updatedLabel(payload.optLong("updatedAt"))
                views.setTextViewText(R.id.bus_footer, if (routes.length() == 0) "本日の運行予定なし · $updated" else "$updated · 更新時点の次発")
            }
        } catch (_: Exception) { /* Keep a useful empty state on malformed data. */ }
        val open = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("citapp://bus?homeWidget=true"))
        views.setOnClickPendingIntent(R.id.widget_container, open)
        views.setOnClickPendingIntent(R.id.btn_refresh, open)
        manager.updateAppWidget(id, views)
    }
}
