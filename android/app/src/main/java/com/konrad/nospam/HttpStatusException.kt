package com.konrad.nospam

/** Risposta HTTP non 2xx da un endpoint che l'app interroga direttamente (es. spam_db.json). */
class HttpStatusException(val statusCode: Int, url: String) : Exception("HTTP $statusCode from $url")
