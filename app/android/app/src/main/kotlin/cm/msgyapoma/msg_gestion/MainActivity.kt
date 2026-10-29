package cm.msgyapoma.msg_gestion

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// FragmentActivity: required by local_auth for the fingerprint / face prompt.
class MainActivity : FlutterFragmentActivity() {
    // Android 7–9: the storage permission is asked once, then the save goes on.
    private var waiting: (() -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Downloads (lib/data/file_store.dart): a copy in the phone's
        // Pictures/MSG or Download/MSG, and PDFs opened in the phone's viewer.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "msg/files")
            .setMethodCallHandler { call, result ->
                val file = File(call.argument<String>("path")!!)
                val mime = call.argument<String>("mime")!!
                when (call.method) {
                    "save" -> saveToPhone(file, call.argument<String>("name")!!, mime) {
                        result.success(it)
                    }
                    "open" -> result.success(open(file, mime))
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveToPhone(file: File, name: String, mime: String, done: (Boolean) -> Unit) {
        val image = mime.startsWith("image/")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            done(saveWithMediaStore(file, name, mime, image))
            return
        }
        val permission = Manifest.permission.WRITE_EXTERNAL_STORAGE
        if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
            done(saveLegacy(file, name, mime, image))
            return
        }
        waiting = {
            val granted = ContextCompat.checkSelfPermission(this, permission) ==
                PackageManager.PERMISSION_GRANTED
            done(granted && saveLegacy(file, name, mime, image))
        }
        ActivityCompat.requestPermissions(this, arrayOf(permission), STORAGE_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == STORAGE_REQUEST) {
            waiting?.invoke()
            waiting = null
        }
    }

    private fun saveWithMediaStore(file: File, name: String, mime: String, image: Boolean): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                (if (image) Environment.DIRECTORY_PICTURES else Environment.DIRECTORY_DOWNLOADS) + "/MSG",
            )
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val collection = if (image) {
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        } else {
            MediaStore.Downloads.EXTERNAL_CONTENT_URI
        }
        val uri = contentResolver.insert(collection, values) ?: return false
        return try {
            contentResolver.openOutputStream(uri)!!.use { out ->
                file.inputStream().use { it.copyTo(out) }
            }
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            true
        } catch (e: Exception) {
            contentResolver.delete(uri, null, null)
            false
        }
    }

    @Suppress("DEPRECATION")
    private fun saveLegacy(file: File, name: String, mime: String, image: Boolean): Boolean = try {
        val dir = File(
            Environment.getExternalStoragePublicDirectory(
                if (image) Environment.DIRECTORY_PICTURES else Environment.DIRECTORY_DOWNLOADS,
            ),
            "MSG",
        )
        dir.mkdirs()
        val base = name.substringBeforeLast('.')
        val ext = name.substringAfterLast('.', "")
        var target = File(dir, name)
        var n = 1
        while (target.exists()) target = File(dir, "$base ($n).$ext").also { n++ }
        file.copyTo(target)
        // Shows it in the gallery / file manager right away.
        android.media.MediaScannerConnection.scanFile(this, arrayOf(target.path), arrayOf(mime), null)
        true
    } catch (e: Exception) {
        false
    }

    private fun open(file: File, mime: String): Boolean {
        val uri = try {
            FileProvider.getUriForFile(this, "$packageName.files", file)
        } catch (e: IllegalArgumentException) {
            return false
        }
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, mime)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    companion object {
        private const val STORAGE_REQUEST = 4207
    }
}
