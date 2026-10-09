package com.konrad.nospam

import android.content.Context
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

/**
 * Traduce un errore gestito in un messaggio comprensibile per l'utente: se
 * la causa è qualcosa che può risolvere lui (la connessione da
 * controllare), lo dice esplicitamente invece di mostrare l'eccezione
 * tecnica grezza.
 */
object UserFacingError {
    fun message(context: Context, error: Throwable): String =
        when (error) {
            is UnknownHostException -> context.getString(R.string.error_no_internet)
            is SocketTimeoutException -> context.getString(R.string.error_timeout)
            is HttpStatusException -> context.getString(R.string.error_server_unavailable, error.statusCode)
            is ReportSubmissionException -> context.getString(R.string.error_server_unavailable, error.statusCode)
            is IOException -> context.getString(R.string.error_no_internet)
            else -> error.message ?: error.toString()
        }
}
