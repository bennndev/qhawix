package pe.qhawix.qhawix

import android.content.Intent
import android.net.Uri
import android.speech.tts.TextToSpeech
import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.role.RoleManager
import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import androidx.core.content.ContextCompat
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import pe.qhawix.qhawix.echotrap.EchoTrapCaptureService
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.Locale

class MainActivity : FlutterActivity() {
    private var speech: TextToSpeech? = null
    private var screeningRoleResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
        if (requestCode == SCREENING_ROLE_REQUEST) {
            screeningRoleResult?.success(isCallScreeningEnabled())
            screeningRoleResult = null
        }
    }

    override fun onDestroy() {
        speech?.stop()
        speech?.shutdown()
        super.onDestroy()
    }

    companion object { private const val SCREENING_ROLE_REQUEST = 7318 }
}
