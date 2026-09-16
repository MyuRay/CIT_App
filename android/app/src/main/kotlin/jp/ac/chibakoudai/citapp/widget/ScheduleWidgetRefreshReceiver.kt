package jp.ac.chibakoudai.citapp.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin

/** Refresh saved timetables without starting Flutter or downloading user data. */
class ScheduleWidgetRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action !in setOf(
                ACTION_REFRESH, Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_MY_PACKAGE_REPLACED, Intent.ACTION_TIME_CHANGED,
                Intent.ACTION_TIMEZONE_CHANGED, Intent.ACTION_DATE_CHANGED,
            )) return
        try {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TodayScheduleWidgetProvider::class.java))
            TodayScheduleWidgetProvider().onUpdate(context, manager, ids, HomeWidgetPlugin.getData(context))
        } catch (error: Exception) {
            Log.e(TAG, "Unable to refresh today's schedule", error)
        } finally {
            scheduleNext(context)
        }
    }

    companion object {
        const val ACTION_REFRESH = "jp.ac.chibakoudai.citapp.widget.REFRESH_SCHEDULE_DAY"
        private const val TAG = "ScheduleWidgetRefresh"
        private const val REQUEST_CODE = 8201

        private fun intent(context: Context) = Intent(context, ScheduleWidgetRefreshReceiver::class.java)
            .setAction(ACTION_REFRESH)

        fun scheduleNext(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            if (manager.getAppWidgetIds(ComponentName(context, TodayScheduleWidgetProvider::class.java)).isEmpty()) {
                cancel(context)
                return
            }
            val pending = PendingIntent.getBroadcast(context, REQUEST_CODE, intent(context),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val alarm = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            // One daily inexact alarm. No exact-alarm permission or running
            // service is needed; Android may defer delivery to conserve power.
            alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, WidgetSnapshot.nextJapanMidnight(), pending)
        }

        fun cancel(context: Context) {
            val pending = PendingIntent.getBroadcast(context, REQUEST_CODE, intent(context),
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE) ?: return
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pending)
            pending.cancel()
        }
    }
}
