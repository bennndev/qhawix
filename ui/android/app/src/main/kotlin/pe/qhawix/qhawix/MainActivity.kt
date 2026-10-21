package pe.qhawix.qhawix

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.net.URI
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var pendingImageResult: MethodChannel.Result? = null
    private val securityHistoryExecutor = Executors.newSingleThreadExecutor()
    private val mainThreadHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        clearTemporaryQrImages()

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QR_IMAGE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickQrImage" -> pickQrImage(result)
                "deleteQrImage" -> {
                    deleteQrImage(call.argument<String>("path"))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        val historyDatabase = QrSecurityHistoryDatabase(applicationContext)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            QR_SECURITY_HISTORY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "recordBlockedIncident" -> recordBlockedIncident(
                    call,
                    historyDatabase,
                    result,
                )
                "isUrlAllowed" -> isUrlAllowed(call, historyDatabase, result)
                "getIncidents" -> loadSecurityIncidents(historyDatabase, result)
                "allowIncident" -> allowIncident(call, historyDatabase, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun recordBlockedIncident(
        call: MethodCall,
        database: QrSecurityHistoryDatabase,
        result: MethodChannel.Result,
    ) {
        val timestamp = call.argument<String>("timestamp")
        val blockedUrl = call.argument<String>("url_bloqueada")
        val lookupUrl = call.argument<String>("lookup_url")
        val category = call.argument<String>("categoria_amenaza")
        val source = call.argument<String>("detection_source")
        val categories = category?.split(',')?.map(String::trim).orEmpty()
        val validCategories = setOf(
            "URLSCAN_MALICIOUS",
            "URLSCAN_PHISHING",
            "MALWARE",
            "SOCIAL_ENGINEERING",
            "UNWANTED_SOFTWARE",
            "LOCAL_POLICY",
        )

        if (timestamp == null || !TIMESTAMP_PATTERN.matches(timestamp) ||
            blockedUrl == null ||
            (!blockedUrl.startsWith("https://") && !blockedUrl.startsWith("http://")) ||
            blockedUrl.toByteArray(Charsets.UTF_8).size > MAX_URL_BYTES ||
            blockedUrl.any { Character.isISOControl(it) } ||
            lookupUrl == null || !isValidLookupUrl(lookupUrl) ||
            category == null || categories.isEmpty() ||
            categories.any { it !in validCategories } ||
            source == null || source !in setOf("localPolicy", "urlscan")
        ) {
            result.error("invalid_incident", "The blocked QR incident is invalid.", null)
            return
        }

        securityHistoryExecutor.execute {
            try {
                val rowId = database.recordBlockedIncident(
                    timestamp = timestamp,
                    blockedUrl = blockedUrl,
                    lookupUrl = lookupUrl!!,
                    threatCategory = categories.joinToString(","),
                    detectionSource = source!!,
                )
                mainThreadHandler.post { result.success(rowId) }
            } catch (_: Exception) {
                mainThreadHandler.post {
                    result.error(
                        "history_write_failed",
                        "The blocked QR incident could not be saved.",
                        null,
                    )
                }
            }
        }
    }

    private fun isUrlAllowed(
        call: MethodCall,
        database: QrSecurityHistoryDatabase,
        result: MethodChannel.Result,
    ) {
        val lookupUrl = call.argument<String>("lookup_url")
        if (lookupUrl == null || !isValidLookupUrl(lookupUrl)) {
            result.success(false)
            return
        }

        securityHistoryExecutor.execute {
            try {
                val allowed = database.isUrlAllowed(lookupUrl)
                mainThreadHandler.post { result.success(allowed) }
            } catch (_: Exception) {
                mainThreadHandler.post {
                    result.error(
                        "history_read_failed",
                        "The QR allowlist could not be read.",
                        null,
                    )
                }
            }
        }
    }

    private fun loadSecurityIncidents(
        database: QrSecurityHistoryDatabase,
        result: MethodChannel.Result,
    ) {
        securityHistoryExecutor.execute {
            try {
                val incidents = database.loadIncidents()
                mainThreadHandler.post { result.success(incidents) }
            } catch (_: Exception) {
                mainThreadHandler.post {
                    result.error(
                        "history_read_failed",
                        "The QR security history could not be read.",
                        null,
                    )
                }
            }
        }
    }

    private fun allowIncident(
        call: MethodCall,
        database: QrSecurityHistoryDatabase,
        result: MethodChannel.Result,
    ) {
        val id = call.argument<Number>("id")?.toLong()
        if (id == null || id <= 0) {
            result.success(false)
            return
        }

        securityHistoryExecutor.execute {
            try {
                val updated = database.allowIncident(id)
                mainThreadHandler.post { result.success(updated) }
            } catch (_: Exception) {
                mainThreadHandler.post {
                    result.error(
                        "history_update_failed",
                        "The QR history record could not be updated.",
                        null,
                    )
                }
            }
        }
    }

    private fun isValidLookupUrl(rawUrl: String): Boolean {
        if (rawUrl.toByteArray(Charsets.UTF_8).size > MAX_URL_BYTES ||
            rawUrl.any { Character.isISOControl(it) }
        ) {
            return false
        }
        return try {
            val uri = URI(rawUrl)
            (uri.scheme == "http" || uri.scheme == "https") &&
                !uri.rawAuthority.isNullOrBlank() &&
                !uri.rawAuthority.contains('@') &&
                uri.rawUserInfo == null
        } catch (_: Exception) {
            false
        }
    }

    private fun pickQrImage(result: MethodChannel.Result) {
        if (pendingImageResult != null) {
            result.error("picker_busy", "An image selection is already in progress.", null)
            return
        }

        pendingImageResult = result
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "image/*"
            addCategory(Intent.CATEGORY_OPENABLE)
        }

        try {
            startActivityForResult(
                Intent.createChooser(intent, "Selecciona una imagen con un QR"),
                QR_IMAGE_REQUEST_CODE,
            )
        } catch (_: ActivityNotFoundException) {
            pendingImageResult = null
            result.error("picker_unavailable", "No image picker is available.", null)
        }
    }

    @Deprecated("Deprecated in Android, retained for FlutterActivity picker result compatibility.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != QR_IMAGE_REQUEST_CODE) return

        val callback = pendingImageResult ?: return
        pendingImageResult = null

        if (resultCode != Activity.RESULT_OK) {
            callback.success(null)
            return
        }

        val uri: Uri = data?.data ?: run {
            callback.error("image_not_selected", "No image was selected.", null)
            return
        }

        if (contentResolver.getType(uri)?.startsWith("image/") != true) {
            callback.error("unsupported_image", "The selected file is not an image.", null)
            return
        }

        try {
            callback.success(copyToTemporaryQrImage(uri).absolutePath)
        } catch (_: ImageTooLargeException) {
            callback.error("image_too_large", "The selected image exceeds 20 MiB.", null)
        } catch (_: Exception) {
            callback.error("image_read_failed", "The selected image could not be read.", null)
        }
    }

    private fun copyToTemporaryQrImage(uri: Uri): File {
        val directory = qrImageCacheDirectory()
        if (!directory.exists() && !directory.mkdirs()) {
            throw IOException("Unable to create temporary image directory.")
        }
        directory.listFiles()?.forEach { it.delete() }

        val target = File.createTempFile("qr-shield-", ".image", directory)
        try {
            val input = contentResolver.openInputStream(uri)
                ?: throw IOException("Unable to open selected image.")
            input.use { source ->
                FileOutputStream(target).use { destination ->
                    val buffer = ByteArray(16 * 1024)
                    var totalBytes = 0L
                    while (true) {
                        val count = source.read(buffer)
                        if (count < 0) break
                        totalBytes += count
                        if (totalBytes > MAX_IMAGE_BYTES) throw ImageTooLargeException()
                        destination.write(buffer, 0, count)
                    }
                }
            }
            return target
        } catch (exception: Exception) {
            target.delete()
            throw exception
        }
    }

    private fun deleteQrImage(path: String?) {
        if (path.isNullOrBlank()) return
        val directory = qrImageCacheDirectory().canonicalFile
        val candidate = File(path).canonicalFile
        if (candidate.parentFile == directory &&
            candidate.name.startsWith("qr-shield-") &&
            candidate.isFile
        ) {
            candidate.delete()
        }
    }

    private fun clearTemporaryQrImages() {
        qrImageCacheDirectory().listFiles()?.forEach { it.delete() }
    }

    private fun qrImageCacheDirectory() = File(cacheDir, "qr-shield")

    override fun onDestroy() {
        securityHistoryExecutor.shutdown()
        super.onDestroy()
    }

    private class ImageTooLargeException : IOException()

    companion object {
        private const val QR_IMAGE_CHANNEL = "pe.qhawix.qhawix/qr_image_picker"
        private const val QR_SECURITY_HISTORY_CHANNEL =
            "pe.qhawix.qhawix/qr_security_history"
        private const val QR_IMAGE_REQUEST_CODE = 7318
        private const val MAX_IMAGE_BYTES = 20L * 1024 * 1024
        private const val MAX_URL_BYTES = 8 * 1024
        private val TIMESTAMP_PATTERN = Regex(
            "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{1,9})?Z$",
        )
    }
}
