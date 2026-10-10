package com.konrad.nospam

import android.content.Context
import android.os.Build
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

/**
 * Invia un log di errore anonimo (solo tipo errore e contesto tecnico, mai
 * input dell'utente) al backend, che lo inoltra via email. Non deve mai
 * interrompere il flusso che lo ha generato: fallisce in silenzio.
 */
object ErrorReporter {
    /** "info" per stati noti/previsti (non da investigare), "error" per i problemi veri. */
    fun report(context: Context, error: Throwable, errorContext: String, level: String = "error") {
        val appVersion = try {
            context.packageManager.getPackageInfo(context.packageName, 0).versionName
        } catch (e: Exception) {
            null
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val connection = URL("${SupabaseConfig.URL}/rest/v1/error_reports").openConnection() as HttpURLConnection
                try {
                    connection.requestMethod = "POST"
                    connection.setRequestProperty("apikey", SupabaseConfig.PUBLISHABLE_KEY)
                    connection.setRequestProperty("Authorization", "Bearer ${SupabaseConfig.PUBLISHABLE_KEY}")
                    connection.setRequestProperty("Content-Type", "application/json")
                    connection.setRequestProperty("Prefer", "return=minimal")
                    connection.doOutput = true

                    val stackTrace = error.stackTraceToString().take(2000)
                    val payload = JSONObject().apply {
                        put("platform", "android")
                        put("context", errorContext)
                        put("message", "$error\n$stackTrace")
                        put("app_version", appVersion)
                        put("os_version", "Android ${Build.VERSION.RELEASE} (SDK ${Build.VERSION.SDK_INT})")
                        put("level", level)
                    }
                    OutputStreamWriter(connection.outputStream, Charsets.UTF_8).use { it.write(payload.toString()) }
                    connection.responseCode
                } finally {
                    connection.disconnect()
                }
            } catch (e: Exception) {
                // Il reporting non deve mai generare un altro errore.
            }
        }
    }
}
