package pe.qhawix.qhawix

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

internal class QrSecurityHistoryDatabase(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    override fun onCreate(database: SQLiteDatabase) {
        database.execSQL(
            """CREATE TABLE $TABLE_NAME (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                url_bloqueada TEXT NOT NULL,
                categoria_amenaza TEXT NOT NULL,
                detection_source TEXT NOT NULL
            )""".trimIndent(),
        )
        database.execSQL(
            "CREATE INDEX qr_security_history_timestamp_idx " +
                "ON $TABLE_NAME(timestamp DESC)",
        )
    }

    override fun onUpgrade(
        database: SQLiteDatabase,
        oldVersion: Int,
        newVersion: Int,
    ) {
        // Add versioned migrations here when the history schema changes.
    }

    fun recordBlockedIncident(
        timestamp: String,
        blockedUrl: String,
        threatCategory: String,
        detectionSource: String,
    ): Long {
        val values = ContentValues().apply {
            put(COLUMN_TIMESTAMP, timestamp)
            put(COLUMN_BLOCKED_URL, blockedUrl)
            put(COLUMN_THREAT_CATEGORY, threatCategory)
            put(COLUMN_DETECTION_SOURCE, detectionSource)
        }
        return writableDatabase.insertOrThrow(TABLE_NAME, null, values)
    }

    companion object {
        private const val DATABASE_NAME = "qhawix_security_history.db"
        private const val DATABASE_VERSION = 1
        private const val TABLE_NAME = "qr_security_history"
        private const val COLUMN_TIMESTAMP = "timestamp"
        private const val COLUMN_BLOCKED_URL = "url_bloqueada"
        private const val COLUMN_THREAT_CATEGORY = "categoria_amenaza"
        private const val COLUMN_DETECTION_SOURCE = "detection_source"
    }
}
