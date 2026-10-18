package pe.qhawix.qhawix.echotrap

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.Connection
import android.content.Intent
import android.os.Build
import android.util.Base64
import androidx.core.app.NotificationCompat
import pe.qhawix.qhawix.MainActivity
import pe.qhawix.qhawix.R
import java.security.MessageDigest

/** Checks only the incoming number. It always allows the call and never accesses audio. */
class EchoTrapCallScreeningService : CallScreeningService() {
    override fun onScreenCall(details: Call.Details) {
        val incoming = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && details.callDirection == Call.Details.DIRECTION_INCOMING
        if (!incoming) return
        val handle = details.handle?.schemeSpecificPart.orEmpty()
        val isSavedContact = isTrustedNumber(handle)
        val spoofingSignal = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            details.callerNumberVerificationStatus == Connection.VERIFICATION_STATUS_FAILED
        if (spoofingSignal) {
            showCallerNotice(handle, true)
        } else if (!isSavedContact) {
            showCallerNotice(handle, false)
        }

        val response = CallResponse.Builder()
            .setDisallowCall(false)
            .setRejectCall(false)
            .setSilenceCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()
        respondToCall(details, response)
    }

    private fun isTrustedNumber(phone: String): Boolean {
        val prefs = getSharedPreferences("echotrap_screening", MODE_PRIVATE)
        val salt = prefs.getString("salt", null) ?: return false
        val hashes = prefs.getStringSet("trusted_hashes", emptySet()) ?: emptySet()
        val normalized = phone.filter { it.isDigit() }
        if (normalized.isEmpty()) return false
        val digest = MessageDigest.getInstance("SHA-256").digest("$salt:$normalized".toByteArray())
        val hash = Base64.encodeToString(digest, Base64.NO_WRAP)
        return hashes.contains(hash)
    }

    private fun showCallerNotice(phone: String, spoofingSignal: Boolean) {
        val manager = getSystemService(NotificationManager::class.java)
        val channelId = "echotrap_incoming_calls"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(channelId, "Avisos de llamadas EchoTrap", NotificationManager.IMPORTANCE_HIGH))
        }
        val openApp = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val suffix = phone.takeLast(4).takeIf { it.isNotBlank() }?.let { "Termina en $it" } ?: "Número oculto"
        val title = if (spoofingSignal) "Posible suplantación del número" else "Llamada de número no guardado"
        val explanation = if (spoofingSignal) {
            "La verificación de red no coincidió con el número mostrado. Puede estar suplantado; no confirma quién llama."
        } else {
            "Número no guardado no significa que sea spam. La llamada continuará normalmente. No compartas claves ni códigos."
        }
        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText("$suffix. $explanation")
            .setStyle(NotificationCompat.BigTextStyle().bigText("$suffix. $explanation"))
            .setContentIntent(openApp)
            .setAutoCancel(true)
            .build()
        try { manager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification) } catch (_: SecurityException) { }
    }
}
