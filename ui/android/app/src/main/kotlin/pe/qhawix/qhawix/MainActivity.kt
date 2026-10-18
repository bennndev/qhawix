package pe.qhawix.qhawix

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.speech.tts.TextToSpeech
import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.role.RoleManager
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.ContactsContract
import android.util.Base64
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import pe.qhawix.qhawix.echotrap.EchoTrapCaptureService
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.Locale
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var speech: TextToSpeech? = null
    private var screeningRoleResult: MethodChannel.Result? = null
    private var pendingImageResult: MethodChannel.Result? = null
    private var qrSecurityHistoryDatabase: QrSecurityHistoryDatabase? = null
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
        qrSecurityHistoryDatabase = historyDatabase
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
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pe.qhawix.qhawix/echotrap")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "dial" -> {
                        val number = call.argument<String>("number")?.filter { it.isDigit() || it == '+' }
                        if (number.isNullOrBlank()) result.error("invalid_number", "Número vacío o no válido", null)
                        else try {
                            startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:$number")))
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("dial_failed", error.localizedMessage, null)
                        }
                    }
                    "startCapture" -> {
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                            result.error("microphone_permission", "Se necesita permiso del micrófono", null)
                        } else try {
                            ContextCompat.startForegroundService(this, Intent(this, EchoTrapCaptureService::class.java))
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("capture_failed", error.localizedMessage, null)
                        }
                    }
                    "stopCapture" -> {
                        stopService(Intent(this, EchoTrapCaptureService::class.java))
                        result.success(null)
                    }
                    "speakWarning" -> {
                        val text = call.argument<String>("text") ?: "Precaución. No compartas claves ni códigos."
                        speak(text)
                        result.success(null)
                    }
                    "showRiskAlert" -> {
                        val level = call.argument<String>("level")
                        val text = call.argument<String>("text")
                        if (level == null || (level != "red" && level != "yellow") || text == null || text.isBlank()) {
                            result.error("invalid_alert", "Aviso de EchoTrap no válido", null)
                        } else {
                            showRiskAlert(level, text)
                            result.success(null)
                        }
                    }
                    "setTrustedPhones" -> {
                        val phones = call.argument<List<Any?>>("phones")?.mapNotNull { it as? String }.orEmpty()
                        saveTrustedPhoneHashes(phones)
                        result.success(null)
                    }
                    "loadDeviceContacts" -> loadDeviceContacts(result)
                    "isCallScreeningEnabled" -> result.success(isCallScreeningEnabled())
                    "requestCallScreening" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                            result.error("unsupported_android", "El aviso de llamadas requiere Android 10 o posterior.", null)
                        } else {
                            val roles = getSystemService(RoleManager::class.java)
                            if (roles.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) result.success(null)
                            else if (screeningRoleResult != null) result.error("role_request_pending", "La solicitud de permiso sigue abierta.", null)
                            else {
                                screeningRoleResult = result
                                startActivityForResult(roles.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING), SCREENING_ROLE_REQUEST)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "pe.qhawix.qhawix/echotrap/audio")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    EchoTrapCaptureService.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    EchoTrapCaptureService.eventSink = null
                }
            })
    }

    private fun recordBlockedIncident(
        call: MethodCall,
        database: QrSecurityHistoryDatabase,
        result: MethodChannel.Result,
    ) {
        val timestamp = call.argument<String>("timestamp")
        val blockedUrl = call.argument<String>("url_bloqueada")
        val category = call.argument<String>("categoria_amenaza")
        val source = call.argument<String>("detection_source")
        val categories = category?.split(',')?.map(String::trim).orEmpty()
        val validCategories = setOf(
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
            category == null || categories.isEmpty() ||
            categories.any { it !in validCategories } ||
            source == null || source !in setOf("localPolicy", "googleWebRisk")
        ) {
            result.error("invalid_incident", "The blocked QR incident is invalid.", null)
            return
        }

        securityHistoryExecutor.execute {
            try {
                val rowId = database.recordBlockedIncident(
                    timestamp = timestamp,
                    blockedUrl = blockedUrl,
                    threatCategory = categories.joinToString(","),
                    detectionSource = source,
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
    private fun handleQrImageResult(resultCode: Int, data: Intent?) {
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

    private fun speak(text: String) {
        if (speech == null) {
            speech = TextToSpeech(this) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    speech?.language = Locale.forLanguageTag("es-PE")
                    speech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "echotrap-warning")
                }
            }
        } else {
            speech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "echotrap-warning")
        }
    }

    private fun loadDeviceContacts(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            result.error("contacts_permission", "Primero permite el acceso a tus contactos.", null)
            return
        }

        Thread {
            try {
                val contacts = mutableListOf<Map<String, String>>()
                contentResolver.query(
                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                    arrayOf(
                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                        ContactsContract.CommonDataKinds.Phone.NUMBER,
                    ),
                    null,
                    null,
                    "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} COLLATE NOCASE ASC",
                )?.use { cursor ->
                    val nameColumn = cursor.getColumnIndexOrThrow(
                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                    )
                    val phoneColumn = cursor.getColumnIndexOrThrow(
                        ContactsContract.CommonDataKinds.Phone.NUMBER,
                    )
                    while (cursor.moveToNext()) {
                        val name = cursor.getString(nameColumn)?.trim().orEmpty()
                        val phone = cursor.getString(phoneColumn)?.trim().orEmpty()
                        if (name.isNotEmpty() && phone.isNotEmpty()) {
                            contacts.add(mapOf("name" to name, "phone" to phone))
                        }
                    }
                }
                runOnUiThread { result.success(contacts) }
            } catch (_: SecurityException) {
                runOnUiThread {
                    result.error("contacts_permission", "Android no permitió leer tus contactos.", null)
                }
            } catch (_: Exception) {
                runOnUiThread {
                    result.error("contacts_unavailable", "No se pudo cargar la agenda del teléfono.", null)
                }
            }
        }.start()
    }

    private fun showRiskAlert(level: String, text: String) {
        val manager = getSystemService(NotificationManager::class.java)
        val channelId = "echotrap_risk_alerts"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val vibration = if (level == "red") longArrayOf(0, 250, 120, 350) else longArrayOf(0, 180)
            val channel = NotificationChannel(
                channelId,
                "Alertas de riesgo EchoTrap",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Avisos visuales y vibración durante el análisis voluntario de una llamada."
                enableVibration(true)
                vibrationPattern = vibration
            }
            manager.createNotificationChannel(channel)
        }
        val openApp = android.app.PendingIntent.getActivity(
            this,
            7320,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE,
        )
        val title = if (level == "red") "Detente: posible intento de fraude" else "Precaución con esta llamada"
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setContentIntent(openApp)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .apply {
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                    setVibrate(if (level == "red") longArrayOf(0, 250, 120, 350) else longArrayOf(0, 180))
                }
            }
            .build()
        try {
            manager.notify(7320, notification)
        } catch (_: SecurityException) {
            // The caller still gets the in-app warning if notifications are disabled.
        }
    }

    private fun isCallScreeningEnabled(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
        getSystemService(RoleManager::class.java).isRoleHeld(RoleManager.ROLE_CALL_SCREENING)

    private fun saveTrustedPhoneHashes(phones: List<String>) {
        val preferences = getSharedPreferences("echotrap_screening", MODE_PRIVATE)
        var salt = preferences.getString("salt", null)
        if (salt == null) {
            val bytes = ByteArray(32).also { SecureRandom().nextBytes(it) }
            salt = Base64.encodeToString(bytes, Base64.NO_WRAP)
        }
        val hashes = phones.map { phone -> hashPhone(salt!!, phone) }.toSet()
        preferences.edit().putString("salt", salt).putStringSet("trusted_hashes", hashes).apply()
    }

    private fun hashPhone(salt: String, phone: String): String {
        val normalized = phone.filter { it.isDigit() }
        val bytes = MessageDigest.getInstance("SHA-256").digest("$salt:$normalized".toByteArray())
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == QR_IMAGE_REQUEST_CODE) {
            handleQrImageResult(resultCode, data)
        } else if (requestCode == SCREENING_ROLE_REQUEST) {
            screeningRoleResult?.success(isCallScreeningEnabled())
            screeningRoleResult = null
        }
    }

    override fun onDestroy() {
        speech?.stop()
        speech?.shutdown()
        qrSecurityHistoryDatabase?.close()
        securityHistoryExecutor.shutdown()
        super.onDestroy()
    }

    private class ImageTooLargeException : IOException()

    companion object {
        private const val SCREENING_ROLE_REQUEST = 7318
        private const val QR_IMAGE_REQUEST_CODE = 7321
        private const val QR_IMAGE_CHANNEL = "pe.qhawix.qhawix/qr_image_picker"
        private const val QR_SECURITY_HISTORY_CHANNEL =
            "pe.qhawix.qhawix/qr_security_history"
        private const val MAX_IMAGE_BYTES = 20L * 1024 * 1024
        private const val MAX_URL_BYTES = 8 * 1024
        private val TIMESTAMP_PATTERN = Regex(
            "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{1,9})?Z$",
        )
    }
}
