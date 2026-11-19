package jp.ac.chibakoudai.citapp

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

/** Writes only the image provided by Flutter; it never reads the photo library. */
class ScheduleImageSaver(private val activity: Activity) {
    private data class PendingSave(
        val bytes: ByteArray,
        val name: String,
        val result: MethodChannel.Result,
    )

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingSave: PendingSave? = null

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "saveImage") {
            result.notImplemented()
            return
        }
        val bytes = call.argument<ByteArray>("bytes")
        val name = call.argument<String>("name")
        if (bytes == null || bytes.isEmpty() || name == null ||
            !name.matches(Regex("[A-Za-z0-9_-]{1,120}\\.png"))) {
            result.error("save_failed", "保存する画像またはファイル名が正しくありません。", null)
            return
        }
        if (pendingSave != null) {
            result.error("save_failed", "画像の保存が完了するまでお待ちください。", null)
            return
        }
        pendingSave = PendingSave(bytes, name, result)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED) {
            activity.requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                permissionRequestCode,
            )
        } else {
            savePendingImage()
        }
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != permissionRequestCode) return false
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            savePendingImage()
        } else {
            finish("permission_denied", "写真への保存が許可されていません。設定から許可してください。")
        }
        return true
    }

    fun dispose() {
        finish("save_failed", "画面が閉じられたため、保存結果を確認できませんでした。")
        executor.shutdown()
    }

    private fun savePendingImage() {
        val save = pendingSave ?: return
        executor.execute {
            try {
                writeImage(save.bytes, save.name)
                mainHandler.post { finish() }
            } catch (_: SecurityException) {
                mainHandler.post {
                    finish("permission_denied", "写真への保存が許可されていません。設定から許可してください。")
                }
            } catch (_: Exception) {
                mainHandler.post {
                    finish("save_failed", "画像を保存できませんでした。空き容量などを確認して再度お試しください。")
                }
            }
        }
    }

    private fun finish(code: String? = null, message: String? = null) {
        val save = pendingSave ?: return
        pendingSave = null
        if (code == null) save.result.success(null) else save.result.error(code, message, null)
    }

    @Suppress("DEPRECATION")
    private fun writeImage(bytes: ByteArray, name: String) {
        val resolver = activity.applicationContext.contentResolver
        var imageUri: Uri? = null
        var legacyFile: File? = null
        try {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, name)
                put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                put(MediaStore.Images.Media.DATE_TAKEN, System.currentTimeMillis())
            }
            val collection: Uri
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                values.put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/CIT App")
                values.put(MediaStore.Images.Media.IS_PENDING, 1)
            } else {
                collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                val directory = File(
                    Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),
                    "CIT App",
                )
                if (!directory.exists() && !directory.mkdirs()) {
                    throw IOException("Could not create the picture directory")
                }
                // Reserve a new name so a repeated save can never overwrite an earlier image.
                var candidate = File(directory, name)
                var suffix = 1
                while (!candidate.createNewFile()) {
                    candidate = File(directory, "${name.removeSuffix(".png")}_${suffix++}.png")
                }
                legacyFile = candidate
                values.put(MediaStore.Images.Media.DATA, candidate.absolutePath)
                values.put(MediaStore.Images.Media.DISPLAY_NAME, candidate.name)
            }
            val uri = resolver.insert(collection, values)
                ?: throw IOException("Could not create a media item")
            imageUri = uri
            val output = resolver.openOutputStream(uri, "w")
                ?: throw IOException("Could not open the media item")
            output.use { it.write(bytes) }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val published = resolver.update(
                    uri,
                    ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) },
                    null,
                    null,
                )
                if (published != 1) throw IOException("Could not publish the media item")
            }
        } catch (error: Exception) {
            // Do not leave an empty or permanently pending image after a failed write.
            imageUri?.let { uri -> runCatching { resolver.delete(uri, null, null) } }
            legacyFile?.let { file -> runCatching { file.delete() } }
            throw error
        }
    }

    companion object {
        private const val permissionRequestCode = 24031
    }
}
