package jp.ac.chibakoudai.citapp

import android.content.pm.ApplicationInfo
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var scheduleImageSaver: ScheduleImageSaver? = null
    private var scheduleImageChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val saver = ScheduleImageSaver(this)
        scheduleImageSaver = saver
        scheduleImageChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "jp.ac.chibakoudai.citapp/schedule_image",
        ).apply { setMethodCallHandler(saver::handle) }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        scheduleImageChannel?.setMethodCallHandler(null)
        scheduleImageChannel = null
        scheduleImageSaver?.dispose()
        scheduleImageSaver = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (scheduleImageSaver?.onRequestPermissionsResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Firebase Analytics Debug Viewを有効化（デバッグビルドのみ）
        val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (isDebuggable) {
            System.setProperty("debug.firebase.analytics.app", "jp.ac.chibakoudai.citapp")
        }
    }
}
