package com.konrad.nospam

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
    fun message(error: Throwable): String =
        when (error) {
            is UnknownHostException -> "Nessuna connessione Internet: controlla la connessione e riprova."
            is SocketTimeoutException -> "La richiesta ha impiegato troppo tempo: riprova più tardi."
            is HttpStatusException -> "Il server non è raggiungibile al momento (codice ${error.statusCode}). Riprova più tardi."
            is ReportSubmissionException -> "Il server non è raggiungibile al momento (codice ${error.statusCode}). Riprova più tardi."
            is IOException -> "Nessuna connessione Internet: controlla la connessione e riprova."
            else -> error.message ?: error.toString()
        }
}
