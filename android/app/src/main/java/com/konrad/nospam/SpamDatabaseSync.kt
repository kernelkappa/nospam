package com.konrad.nospam

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.net.HttpURLConnection
import java.net.URL

object SpamDatabaseSync {
    private const val REMOTE_URL = "https://kernelkappa.github.io/nospam/spam_db.json"

    suspend fun sync(context: Context) {
        val entities = withContext(Dispatchers.IO) {
            val connection = URL(REMOTE_URL).openConnection() as HttpURLConnection
            try {
                connection.requestMethod = "GET"
                val statusCode = connection.responseCode
                if (statusCode !in 200..299) {
                    throw IllegalStateException("HTTP $statusCode from $REMOTE_URL")
                }
                val body = connection.inputStream.bufferedReader().use { it.readText() }
                parseEntities(body)
            } finally {
                connection.disconnect()
            }
        }

        AppDatabase.getInstance(context).spamNumberDao().replaceCommunityEntries(entities)
    }

    private fun parseEntities(json: String): List<SpamNumberEntity> {
        val array = JSONArray(json)
        return buildList {
            for (i in 0 until array.length()) {
                val entry = array.getJSONObject(i)
                val phoneNumber = entry.getString("number")
                add(
                    SpamNumberEntity(
                        phoneNumber = phoneNumber,
                        category = entry.getString("category"),
                        reportCount = entry.getInt("report_count"),
                        digitsOnly = phoneNumber.filter(Char::isDigit),
                        source = NumberSource.COMMUNITY,
                    ),
                )
            }
        }
    }
}
