package com.konrad.nospam

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

enum class ReportCategory(val apiValue: String) {
    SPAM("spam"),
    SCAM("scam"),
    TELEMARKETING("telemarketing"),
    ROBOCALL("robocall"),
    OTHER("other"),
}

class ReportSubmissionException(val statusCode: Int) : Exception("Supabase returned HTTP $statusCode")

object ReportService {
    suspend fun submit(context: Context, phoneNumberE164: String, category: ReportCategory) {
        withContext(Dispatchers.IO) {
            val connection = URL("${SupabaseConfig.URL}/rest/v1/reports").openConnection() as HttpURLConnection
            try {
                connection.requestMethod = "POST"
                connection.setRequestProperty("apikey", SupabaseConfig.PUBLISHABLE_KEY)
                connection.setRequestProperty("Authorization", "Bearer ${SupabaseConfig.PUBLISHABLE_KEY}")
                connection.setRequestProperty("Content-Type", "application/json")
                connection.setRequestProperty("Prefer", "return=minimal")
                connection.doOutput = true

                val payload = JSONObject().apply {
                    put("phone_number", phoneNumberE164)
                    put("category", category.apiValue)
                    put("device_hash", DeviceIdentity.hashedDeviceId(context))
                    put("app_platform", "android")
                }

                OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { it.write(payload.toString()) }

                val statusCode = connection.responseCode
                if (statusCode !in 200..299) {
                    throw ReportSubmissionException(statusCode)
                }
            } finally {
                connection.disconnect()
            }
        }
    }
}
