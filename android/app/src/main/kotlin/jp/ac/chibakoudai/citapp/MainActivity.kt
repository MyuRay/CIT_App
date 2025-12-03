package jp.ac.chibakoudai.citapp

import android.content.pm.ApplicationInfo
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Firebase Analytics Debug Viewを有効化（デバッグビルドのみ）
        val isDebuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (isDebuggable) {
            System.setProperty("debug.firebase.analytics.app", "jp.ac.chibakoudai.citapp")
        }
    }
}