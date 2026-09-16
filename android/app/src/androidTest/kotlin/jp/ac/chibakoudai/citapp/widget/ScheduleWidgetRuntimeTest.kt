package jp.ac.chibakoudai.citapp.widget

import android.content.Intent
import android.content.res.Configuration
import android.appwidget.AppWidgetManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.RemoteViews
import android.widget.TextView
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import es.antonborri.home_widget.HomeWidgetPlugin
import jp.ac.chibakoudai.citapp.R
import org.json.JSONObject
import org.json.JSONArray
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.time.Instant
import java.io.File

/** Exercises framework RemoteViews inflation; a Flutter build cannot catch it. */
@RunWith(AndroidJUnit4::class)
class ScheduleWidgetRuntimeTest {
    private fun epoch(value: String) = Instant.parse(value).toEpochMilli()

    @Test fun completeDayFitsSmallAndLargeWidgetsEvenAfterAllClassesEnd() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        var failure: Throwable? = null
        instrumentation.runOnMainSync {
            try {
                val lessons = JSONArray()
                for (period in 1..10) lessons.put(JSONObject().apply {
                    put("period", period)
                    put("endPeriod", period)
                    put("subject", "情報システム演習$period")
                    put("classroom", "7号館 $period")
                    put("startTime", "%02d:00".format(period + 8))
                    put("endTime", "%02d:00".format(period + 9))
                    put("color", "#2563EB")
                })
                val weekly = JSONObject().put("hasSchedule", true).put("monday", lessons)
                for (instant in listOf("2026-09-14T00:00:00Z", "2026-09-14T14:59:59Z")) {
                    val today = WidgetSnapshot.today(weekly, epoch(instant))
                    for (scale in listOf(0.8f, 1f, 2f)) {
                        for (night in listOf(Configuration.UI_MODE_NIGHT_NO, Configuration.UI_MODE_NIGHT_YES)) {
                            val config = Configuration(instrumentation.targetContext.resources.configuration).apply {
                                fontScale = scale
                                uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or night
                            }
                            val context = instrumentation.targetContext.createConfigurationContext(config)
                            val density = context.resources.displayMetrics.density
                            for ((width, height) in listOf(180 to 140, 250 to 180, 320 to 340)) {
                                val options = Bundle().apply {
                                    putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, width)
                                    putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, height)
                                }
                                val remote = TodayScheduleWidgetProvider().buildViews(context, today, options)
                                val root = remote.apply(context, FrameLayout(context)) as ViewGroup
                                root.measure(View.MeasureSpec.makeMeasureSpec((width * density).toInt(), View.MeasureSpec.EXACTLY),
                                    View.MeasureSpec.makeMeasureSpec((height * density).toInt(), View.MeasureSpec.EXACTLY))
                                root.layout(0, 0, root.measuredWidth, root.measuredHeight)
                                val rows = mutableListOf<ViewGroup>()
                                fun collect(node: View) {
                                    if (node.id == R.id.item_root) rows.add(node as ViewGroup)
                                    if (node is ViewGroup) for (i in 0 until node.childCount) collect(node.getChildAt(i))
                                }
                                collect(root)
                                val condition = "$instant $width x $height font=$scale night=$night"
                                assertEquals(condition, 10, rows.size)
                                for ((index, row) in rows.withIndex()) {
                                    assertTrue(condition, row.findViewById<TextView>(R.id.text_subject).text.startsWith("${index + 1}限 "))
                                    assertTrue(condition, row.hasOnClickListeners())
                                    val rect = Rect()
                                    row.getDrawingRect(rect)
                                    root.offsetDescendantRectToMyCoords(row, rect)
                                    assertTrue("Row outside widget: $condition $rect", rect.top >= 0 && rect.left >= 0 &&
                                        rect.right <= root.width && rect.bottom <= root.height - root.paddingBottom)
                                    val time = row.findViewById<TextView>(R.id.text_time)
                                    assertEquals(condition, 2, time.lineCount)
                                    assertTrue("Time clipped: $condition", time.layout.height <= time.height)
                                    assertTrue("Class name has no width: $condition", row.findViewById<TextView>(R.id.text_subject).width > 0)
                                }
                                if (scale == 1f && instant.endsWith("14:59:59Z")) {
                                    val bitmap = Bitmap.createBitmap(root.width, root.height, Bitmap.Config.ARGB_8888)
                                    root.draw(Canvas(bitmap))
                                    File(context.cacheDir, "today-all-$width-$height-$night.png").outputStream().use {
                                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
                                    }
                                    bitmap.recycle()
                                }
                            }
                        }
                    }
                }
            } catch (error: Throwable) {
                failure = error
            }
        }
        failure?.let { throw it }
    }

    @Test fun fullDayKeepsContinuousLectureTogetherAndDistinguishesDaysOff() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        var failure: Throwable? = null
        instrumentation.runOnMainSync {
            try {
                val context = instrumentation.targetContext
                val weekly = JSONObject("""{"hasSchedule":true,"monday":[
                    {"period":1,"endPeriod":3,"subject":"演習","startTime":"09:00","endTime":"12:00"},
                    {"period":8,"endPeriod":8,"subject":"講義","startTime":"16:00","endTime":"17:00"}]}""")
                val today = WidgetSnapshot.today(weekly, epoch("2026-09-14T01:30:00Z"))
                val root = TodayScheduleWidgetProvider().buildViews(context, today).apply(context, FrameLayout(context))
                val row = root.findViewById<ViewGroup>(R.id.item_root)
                assertTrue(row.contentDescription.toString().contains("1–3限"))
                assertTrue(row.contentDescription.toString().contains("授業中"))
                assertEquals("09:00\n12:00", row.findViewById<TextView>(R.id.text_time).text.toString())
                val empty = TodayScheduleWidgetProvider().buildViews(context,
                    WidgetSnapshot.today(weekly, epoch("2026-09-15T01:30:00Z"))).apply(context, FrameLayout(context))
                assertEquals("今日は授業がありません", empty.findViewById<TextView>(R.id.empty_message).text.toString())
                assertEquals(View.GONE, empty.findViewById<View>(R.id.classes_container).visibility)
            } catch (error: Throwable) { failure = error }
        }
        failure?.let { throw it }
    }

    @Test fun widgetRowsInflateAcrossFontSizesAndThemes() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        instrumentation.runOnMainSync {
            val base = instrumentation.targetContext
            for (scale in listOf(0.8f, 0.85f, 1f, 1.3f, 2f)) {
                for (night in listOf(Configuration.UI_MODE_NIGHT_NO, Configuration.UI_MODE_NIGHT_YES)) {
                    val config = Configuration(base.resources.configuration).apply {
                        fontScale = scale
                        uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or night
                    }
                    val context = base.createConfigurationContext(config)
                    val layouts = listOf(
                        R.layout.item_weekly_period, R.layout.item_weekly_class,
                        R.layout.item_weekly_class_empty, R.layout.item_today_class,
                        R.layout.item_today_class_empty, R.layout.today_schedule_widget,
                        R.layout.weekly_full_schedule_widget,
                    )
                    for (layout in layouts) {
                        val remote = RemoteViews(context.packageName, layout)
                        val view = remote.apply(context, FrameLayout(context))
                        fun checkAutoSize(node: View) {
                            if (node is TextView && android.os.Build.VERSION.SDK_INT >= 26 &&
                                node.autoSizeTextType == TextView.AUTO_SIZE_TEXT_TYPE_UNIFORM) {
                                assertTrue("Invalid auto-size range, layout=$layout scale=$scale",
                                    node.autoSizeMaxTextSize > node.autoSizeMinTextSize)
                            }
                            if (node is ViewGroup) for (i in 0 until node.childCount) checkAutoSize(node.getChildAt(i))
                        }
                        checkAutoSize(view)
                        val width = (360 * context.resources.displayMetrics.density).toInt()
                        view.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
                            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
                        view.layout(0, 0, view.measuredWidth, view.measuredHeight)
                        assertTrue(view.measuredHeight > 0)
                    }
                }
            }
        }
    }

    @Test fun savedWeekChangesDayAtJapanMidnight() {
        val weekly = JSONObject("""{
            "hasSchedule":true,
            "monday":[{"period":1,"subject":"月曜の授業","startTime":"09:15","endTime":"10:05"}],
            "tuesday":[{"period":2,"subject":"火曜の授業","startTime":"10:15","endTime":"11:05"}]
        }""")
        val before = epoch("2026-09-14T14:59:59Z")
        val boundary = epoch("2026-09-14T15:00:00Z")
        val monday = WidgetSnapshot.today(weekly, before)
        val tuesday = WidgetSnapshot.today(weekly, boundary)
        assertEquals("月", monday.getString("weekday"))
        assertEquals("月曜の授業", monday.getJSONArray("classes").getJSONObject(0).getString("subject"))
        assertEquals("火", tuesday.getString("weekday"))
        assertEquals("9/15", tuesday.getString("date"))
        assertEquals("火曜の授業", tuesday.getJSONArray("classes").getJSONObject(0).getString("subject"))
        assertEquals(boundary, WidgetSnapshot.nextJapanMidnight(before))
        assertEquals(epoch("2026-09-15T15:00:00Z"), WidgetSnapshot.nextJapanMidnight(boundary))
    }

    @Test fun midnightHandlesWeekendsMonthAndYearBoundaries() {
        val weekly = JSONObject("""{"hasSchedule":true,"saturday":[{"period":1,"subject":"土曜"}]}""")
        assertEquals(0, WidgetSnapshot.today(weekly, epoch("2026-09-19T15:00:00Z")).getJSONArray("classes").length())
        assertEquals(epoch("2027-01-01T15:00:00Z"), WidgetSnapshot.nextJapanMidnight(epoch("2026-12-31T15:00:00Z")))
        assertEquals(epoch("2028-02-29T15:00:00Z"), WidgetSnapshot.nextJapanMidnight(epoch("2028-02-29T14:59:59Z")))
    }

    @Test fun refreshReceiverUsesCacheWithoutChangingUserData() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val cache = HomeWidgetPlugin.getData(context)
        val before = cache.getString("weekly_full_schedule", null)
        ScheduleWidgetRefreshReceiver().onReceive(context, Intent(ScheduleWidgetRefreshReceiver.ACTION_REFRESH))
        ScheduleWidgetRefreshReceiver().onReceive(context, Intent(Intent.ACTION_TIMEZONE_CHANGED))
        assertEquals(before, cache.getString("weekly_full_schedule", null))
    }
}
