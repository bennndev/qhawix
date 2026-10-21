package pe.qhawix.qhawix

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.security.MessageDigest

internal class QrSecurityHistoryDatabase(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    override fun onCreate(database: SQLiteDatabase) {
        database.execSQL(
            """CREATE TABLE $TABLE_NAME (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                url_bloqueada TEXT NOT NULL,
                categoria_amenaza TEXT NOT NULL,
                detection_source TEXT NOT NULL,
                url_fingerprint TEXT NOT NULL,
                permitido INTEGER NOT NULL DEFAULT 0 CHECK (permitido IN (0, 1))
            )""".trimIndent(),
        )
        database.execSQL(
            "CREATE INDEX qr_security_history_timestamp_idx " +
                "ON $TABLE_NAME(timestamp DESC)",
        )
        database.execSQL(
            "CREATE INDEX qr_security_history_allowlist_idx " +
                "ON $TABLE_NAME(url_fingerprint) WHERE permitido = 1",
        )
    }

    override fun onUpgrade(
        database: SQLiteDatabase,
        oldVersion: Int,
        newVersion: Int,
    ) {
        if (oldVersion < 2) {
            database.execSQL(
                "ALTER TABLE $TABLE_NAME ADD COLUMN url_fingerprint TEXT",
            )
            database.execSQL(
                "ALTER TABLE $TABLE_NAME ADD COLUMN permitido INTEGER NOT NULL DEFAULT 0 " +
                    "CHECK (permitido IN (0, 1))",
            )
            database.execSQL(
                "CREATE INDEX qr_security_history_allowlist_idx " +
                    "ON $TABLE_NAME(url_fingerprint) WHERE permitido = 1",
            )
        }
        if (oldVersion < 3) {
            // Preserve historical evidence without attributing an old scan to the new provider.
            database.execSQL(
                "UPDATE $TABLE_NAME SET detection_source = 'legacyReputation' " +
                    "WHERE detection_source = 'googleWebRisk'",
            )
        }
    }

    fun recordBlockedIncident(
        timestamp: String,
        blockedUrl: String,
        lookupUrl: String,
        threatCategory: String,
        detectionSource: String,
    ): Long {
        val values = ContentValues().apply {
            put(COLUMN_TIMESTAMP, timestamp)
            put(COLUMN_BLOCKED_URL, blockedUrl)
            put(COLUMN_THREAT_CATEGORY, threatCategory)
            put(COLUMN_DETECTION_SOURCE, detectionSource)
            put(COLUMN_URL_FINGERPRINT, fingerprint(lookupUrl))
            put(COLUMN_ALLOWED, 0)
        }
        return writableDatabase.insertOrThrow(TABLE_NAME, null, values)
    }

    fun isUrlAllowed(lookupUrl: String): Boolean {
        val urlFingerprint = fingerprint(lookupUrl)
        return readableDatabase.query(
            TABLE_NAME,
            arrayOf(COLUMN_ID),
            "$COLUMN_URL_FINGERPRINT = ? AND $COLUMN_ALLOWED = 1",
            arrayOf(urlFingerprint),
            null,
            null,
            null,
            "1",
        ).use { cursor -> cursor.moveToFirst() }
    }

    fun loadIncidents(): List<Map<String, Any>> {
        val incidents = mutableListOf<Map<String, Any>>()
        readableDatabase.query(
            TABLE_NAME,
            arrayOf(
                COLUMN_ID,
                COLUMN_TIMESTAMP,
                COLUMN_BLOCKED_URL,
                COLUMN_THREAT_CATEGORY,
                COLUMN_DETECTION_SOURCE,
                COLUMN_URL_FINGERPRINT,
                COLUMN_ALLOWED,
            ),
            null,
            null,
            null,
            null,
            "$COLUMN_TIMESTAMP DESC, $COLUMN_ID DESC",
        ).use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(COLUMN_ID)
            val timestampIndex = cursor.getColumnIndexOrThrow(COLUMN_TIMESTAMP)
            val urlIndex = cursor.getColumnIndexOrThrow(COLUMN_BLOCKED_URL)
            val categoryIndex = cursor.getColumnIndexOrThrow(COLUMN_THREAT_CATEGORY)
            val sourceIndex = cursor.getColumnIndexOrThrow(COLUMN_DETECTION_SOURCE)
            val fingerprintIndex = cursor.getColumnIndexOrThrow(COLUMN_URL_FINGERPRINT)
            val allowedIndex = cursor.getColumnIndexOrThrow(COLUMN_ALLOWED)
            while (cursor.moveToNext()) {
                incidents += mapOf(
                    "id" to cursor.getLong(idIndex),
                    "timestamp" to cursor.getString(timestampIndex),
                    "url_bloqueada" to cursor.getString(urlIndex),
                    "categoria_amenaza" to cursor.getString(categoryIndex),
                    "detection_source" to cursor.getString(sourceIndex),
                    "permitido" to (cursor.getInt(allowedIndex) == 1),
                    "puede_permitirse" to (
                        !cursor.isNull(fingerprintIndex) &&
                            cursor.getString(sourceIndex) in setOf("urlscan", "legacyReputation") &&
                            cursor.getInt(allowedIndex) == 0
                        ),
                )
            }
        }
        return incidents
    }

    fun allowIncident(id: Long): Boolean {
        val database = writableDatabase
        val values = ContentValues().apply { put(COLUMN_ALLOWED, 1) }
        database.beginTransaction()
        return try {
            val existing = database.query(
                TABLE_NAME,
                arrayOf(COLUMN_URL_FINGERPRINT),
                "$COLUMN_ID = ? AND $COLUMN_DETECTION_SOURCE IN (?, ?) AND $COLUMN_ALLOWED = 0",
                arrayOf(id.toString(), "urlscan", "legacyReputation"),
                null,
                null,
                null,
                "1",
            ).use { cursor ->
                if (!cursor.moveToFirst()) {
                    null
                } else {
                    cursor.getString(
                        cursor.getColumnIndexOrThrow(COLUMN_URL_FINGERPRINT),
                    )
                }
            } ?: return false

            values.put(COLUMN_URL_FINGERPRINT, existing)
            val updated = database.update(
                TABLE_NAME,
                values,
                "$COLUMN_ID = ? AND $COLUMN_DETECTION_SOURCE IN (?, ?) AND $COLUMN_ALLOWED = 0",
                arrayOf(id.toString(), "urlscan", "legacyReputation"),
            ) > 0
            if (updated) database.setTransactionSuccessful()
            updated
        } finally {
            database.endTransaction()
        }
    }

    private fun fingerprint(url: String): String = MessageDigest
        .getInstance("SHA-256")
        .digest(url.toByteArray(Charsets.UTF_8))
        .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }

    companion object {
        private const val DATABASE_NAME = "qhawix_security_history.db"
        private const val DATABASE_VERSION = 3
        private const val TABLE_NAME = "qr_security_history"
        private const val COLUMN_ID = "id"
        private const val COLUMN_TIMESTAMP = "timestamp"
        private const val COLUMN_BLOCKED_URL = "url_bloqueada"
        private const val COLUMN_THREAT_CATEGORY = "categoria_amenaza"
        private const val COLUMN_DETECTION_SOURCE = "detection_source"
        private const val COLUMN_URL_FINGERPRINT = "url_fingerprint"
        private const val COLUMN_ALLOWED = "permitido"
    }
}
