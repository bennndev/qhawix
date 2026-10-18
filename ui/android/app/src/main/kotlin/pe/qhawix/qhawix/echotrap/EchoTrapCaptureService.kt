package pe.qhawix.qhawix.echotrap

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import pe.qhawix.qhawix.R
import kotlin.concurrent.thread

/** Visible, user-started microphone capture for EchoTrap. Never writes audio to disk. */
class EchoTrapCaptureService : Service() {
    private var recorder: AudioRecord? = null
    @Volatile private var running = false
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, notification())
        beginCapture()
    }

    private fun beginCapture() {
        if (running) return
        val sampleRate = 16000
        val windowBytes = sampleRate * 2 * 4 // four seconds, mono PCM16
        val minBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minBuffer <= 0) {
            postError("Este teléfono no permite iniciar la captura de audio.")
            stopSelf()
            return
        }
        val audio = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            maxOf(minBuffer, windowBytes),
        )
        if (audio.state != AudioRecord.STATE_INITIALIZED) {
            audio.release()
            postError("No se pudo abrir el micrófono. Android podría estar reservándolo para la llamada.")
            stopSelf()
            return
        }
        recorder = audio
        running = true
        audio.startRecording()
        thread(name = "echotrap-audio", isDaemon = true) {
            val buffer = ByteArray(windowBytes)
            while (running) {
                var filled = 0
                while (running && filled < buffer.size) {
                    val count = audio.read(buffer, filled, buffer.size - filled, AudioRecord.READ_BLOCKING)
                    if (count <= 0) {
                        postError("Android no está entregando audio. Prueba con el altavoz activado.")
                        running = false
                        break
                    }
                    filled += count
                }
                if (running && filled == buffer.size) {
                    val window = buffer.copyOf()
                    mainHandler.post { eventSink?.success(window) }
                }
            }
            try { audio.stop() } catch (_: Exception) { }
            audio.release()
        }
    }

    private fun postError(message: String) {
        mainHandler.post { eventSink?.error("audio_unavailable", message, null) }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Protección EchoTrap", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun notification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(this, CHANNEL_ID) else Notification.Builder(this)
        return builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("EchoTrap está activo")
            .setContentText("Micrófono encendido por solicitud tuya. Toca detener en la app para finalizar.")
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        running = false
        try { recorder?.stop() } catch (_: Exception) { }
        recorder = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val CHANNEL_ID = "echotrap_capture"
        private const val NOTIFICATION_ID = 7319
        @Volatile var eventSink: EventChannel.EventSink? = null
    }
}
