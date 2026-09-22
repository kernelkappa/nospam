package com.konrad.nospam

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.net.HttpURLConnection
import java.net.URL

object SpamDatabaseSync {
    private const val REMOTE_URL = "https://kernelkappa.github.io/nospam/spam_db.json"
    private const val PREFIX_REMOTE_URL = "https://kernelkappa.github.io/nospam/spam_prefixes.json"

    suspend fun sync(context: Context) {
        val entities = withContext(Dispatchers.IO) { parseEntities(fetchBody(REMOTE_URL)) }
        AppDatabase.getInstance(context).spamNumberDao().replaceCommunityEntries(entities)

        val prefixEntities = withContext(Dispatchers.IO) { parsePrefixEntities(fetchBody(PREFIX_REMOTE_URL)) }
        AppDatabase.getInstance(context).spamPrefixDao().replaceAll(prefixEntities)
    }

    private fun fetchBody(url: String): String {
        val connection = URL(url).openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "GET"
            val statusCode = connection.responseCode
            if (statusCode !in 200..299) {
                throw IllegalStateException("HTTP $statusCode from $url")
            }
            return connection.inputStream.bufferedReader().use { it.readText() }
        } finally {
            connection.disconnect()
        }
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

    private fun parsePrefixEntities(json: String): List<SpamPrefixEntity> {
        val array = JSONArray(json)
        return buildList {
            for (i in 0 until array.length()) {
                val entry = array.getJSONObject(i)
                val prefix = entry.getString("prefix")
                add(
                    SpamPrefixEntity(
                        digitsOnlyPrefix = prefix.filter(Char::isDigit),
                        label = entry.getString("label"),
                        mode = entry.getString("mode"),
                        source = entry.getString("source"),
                    ),
                )
            }
        }
    }
}
