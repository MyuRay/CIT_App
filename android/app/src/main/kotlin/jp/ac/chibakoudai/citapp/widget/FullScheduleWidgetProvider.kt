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
        private const val ROW_GAP_DP = 2
        // AppWidgetOptions の高さはdp単位。高さに応じて表示行数を決める。
        private fun getMaxSlotsForHeight(heightDp: Int): Int {
            return when {
                heightDp < 110 -> 2
                heightDp < 150 -> 3
                heightDp < 190 -> 4
                heightDp < 230 -> 5
                heightDp < 270 -> 6
                heightDp < 310 -> 7
                heightDp < 350 -> 8
                heightDp < 390 -> 9
                else -> MAX_PERIODS
            }
        }
    }

    private fun dpToPx(context: Context, dp: Int): Int {
        val density = context.resources.displayMetrics.density
        return (dp * density).toInt()
    }

    private fun blockMinHeightDp(span: Int, slotHeightDp: Int): Int {
        val safeSpan = span.coerceAtLeast(1)
        return slotHeightDp * safeSpan + ROW_GAP_DP * (safeSpan - 1)
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
                // 高さ変更時は最大高さを優先して情報量を増やす
                val maxHeightDp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN && options != null) {
                    options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 400)
                } else 400
                val densitySlots = getMaxSlotsForHeight(maxHeightDp)
                val showEmptyRows = densitySlots >= 6
                // 科目名が潰れにくいよう、教室表示はかなり高い時だけ有効化
                val showRoom = densitySlots >= 9
                // タイトル/曜日行ぶんを引いた残りを10限で割って、縦を使い切る行高を算出
                val estimatedHeaderDp = 34
                val slotHeightDp = ((maxHeightDp - estimatedHeaderDp - (ROW_GAP_DP * (MAX_PERIODS - 1))) / MAX_PERIODS)
                    .coerceIn(16, 56)
                populateWeekly(
                    context,
                    views,
                    obj,
                    MAX_PERIODS,
                    showEmptyRows,
                    showRoom,
                    slotHeightDp
                )
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
        maxSlots: Int,
        showEmptyRows: Boolean,
        showRoom: Boolean,
        slotHeightDp: Int
    ) {
        val scheduleTitle = weekly.optString("scheduleTitle", "週間時間割")
        views.setTextViewText(R.id.weekly_title, scheduleTitle)

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
        val periodsListId = R.id.periods_list
        val labelIds = arrayOf(
            R.id.monday_label, R.id.tuesday_label, R.id.wednesday_label,
            R.id.thursday_label, R.id.friday_label, R.id.saturday_label
        )

        views.removeAllViews(periodsListId)
        for (period in 1..MAX_PERIODS) {
            views.addView(periodsListId, createPeriodRow(context, period, slotHeightDp))
        }

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

            // 1限〜maxSlots限を表示。連続コマは1つのブロックとしてまとめる
            var period = 1
            var pendingEmptySpan = 0
            while (period <= maxSlots) {
                val item = classByPeriod[period]
                if (item != null) {
                    if (!showEmptyRows && pendingEmptySpan > 0) {
                        views.addView(
                            listId,
                            createSpacerRow(context, pendingEmptySpan, slotHeightDp)
                        )
                        pendingEmptySpan = 0
                    }
                    val endFromData = item.optInt("endPeriod", period)
                    val duration = item.optInt("duration", 1).coerceAtLeast(1)
                    val computedEnd = period + duration - 1
                    val endPeriod = minOf(maxSlots, maxOf(endFromData, computedEnd))
                    val span = (endPeriod - period + 1).coerceAtLeast(1)
                    views.addView(
                        listId,
                        createClassRow(
                            context,
                            period,
                            endPeriod,
                            item,
                            label,
                            showRoom,
                            span,
                            slotHeightDp
                        )
                    )
                    period = endPeriod + 1
                } else {
                    if (showEmptyRows) {
                        views.addView(listId, createEmptyRow(context, period, label, 1, slotHeightDp))
                    } else {
                        pendingEmptySpan += 1
                    }
                    period += 1
                }
            }
            if (!showEmptyRows && pendingEmptySpan > 0) {
                views.addView(listId, createSpacerRow(context, pendingEmptySpan, slotHeightDp))
            }
        }
    }

    private fun createClassRow(
        context: Context,
        startPeriod: Int,
        endPeriod: Int,
        item: JSONObject,
        dayLabel: String,
        showRoom: Boolean,
        blockSpan: Int,
        slotHeightDp: Int
    ): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.item_weekly_class)
        val subject = item.optString("subject", "")
        val room = item.optString("classroom", "")
        val colorHex = item.optString("color", "#2196F3")
        row.setTextViewText(R.id.text_subject, subject)
        if (showRoom && room.isNotEmpty()) {
            row.setTextViewText(R.id.text_room, room)
            row.setViewVisibility(R.id.text_room, android.view.View.VISIBLE)
        } else {
            row.setViewVisibility(R.id.text_room, android.view.View.GONE)
        }
        val bgColor = try {
            Color.parseColor(colorHex)
        } catch (_: Exception) {
            Color.parseColor("#2196F3")
        }
        row.setInt(R.id.item_root, "setBackgroundColor", bgColor)
        row.setViewVisibility(R.id.color_dot, android.view.View.GONE)
        // ユーザー要望: 講義情報テキストは黒固定
        row.setTextColor(R.id.text_subject, Color.BLACK)
        row.setTextColor(R.id.text_room, Color.BLACK)

        // 連続コマ数に応じて高さを拡張し、下側に余白が余りにくくする
        row.setInt(
            R.id.item_root,
            "setMinimumHeight",
            dpToPx(context, blockMinHeightDp(blockSpan, slotHeightDp))
        )

        val intent = Intent(context, MainActivity::class.java)
        intent.putExtra("open_schedule", true)
        intent.putExtra("open_day", dayLabel)
        intent.putExtra("open_period", startPeriod)
        intent.data = Uri.parse("citapp://schedule")
        intent.action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
        val pending = PendingIntent.getActivity(
            context, (dayLabel.hashCode() and 0xFFFF) * 10 + startPeriod, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        row.setOnClickPendingIntent(R.id.item_root, pending)
        return row
    }

    private fun createEmptyRow(
        context: Context,
        period: Int,
        dayLabel: String,
        blockSpan: Int,
        slotHeightDp: Int
    ): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.item_weekly_class_empty)
        row.setTextViewText(R.id.text_subject, "[$period] —")
        row.setInt(
            R.id.item_root,
            "setMinimumHeight",
            dpToPx(context, blockMinHeightDp(blockSpan, slotHeightDp))
        )

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

    private fun createSpacerRow(context: Context, blockSpan: Int, slotHeightDp: Int): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.item_weekly_class_empty)
        row.setTextViewText(R.id.text_subject, "")
        row.setViewVisibility(R.id.text_subject, android.view.View.GONE)
        row.setViewVisibility(R.id.text_room, android.view.View.GONE)
        row.setViewVisibility(R.id.color_dot, android.view.View.GONE)
        row.setInt(R.id.item_root, "setBackgroundColor", Color.TRANSPARENT)
        row.setInt(
            R.id.item_root,
            "setMinimumHeight",
            dpToPx(context, blockMinHeightDp(blockSpan, slotHeightDp))
        )
        return row
    }

    private fun createPeriodRow(context: Context, period: Int, slotHeightDp: Int): RemoteViews {
        val row = RemoteViews(context.packageName, R.layout.item_weekly_period)
        row.setTextViewText(R.id.text_period, "${period}限")
        row.setInt(
            R.id.text_period,
            "setMinHeight",
            dpToPx(context, blockMinHeightDp(1, slotHeightDp))
        )
        return row
    }
}
