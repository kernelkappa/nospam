package com.konrad.nospam

import android.content.Context

object PersonalBlocklist {
    /** Rimuove spazi e altri separatori (es. copiati dal registro chiamate),
     * mantenendo solo le cifre e un eventuale "+" iniziale. */
    fun normalize(phoneNumber: String): String {
        val trimmed = phoneNumber.trim()
        val digits = trimmed.filter(Char::isDigit)
        return if (trimmed.startsWith("+")) "+$digits" else digits
    }

    suspend fun add(context: Context, phoneNumber: String, category: String = "personale") {
        val normalized = normalize(phoneNumber)
        val entity = SpamNumberEntity(
            phoneNumber = normalized,
            category = category,
            reportCount = 0,
            digitsOnly = normalized.filter(Char::isDigit),
            source = NumberSource.PERSONAL,
        )
        AppDatabase.getInstance(context).spamNumberDao().insertOne(entity)
    }

    suspend fun remove(context: Context, phoneNumber: String) {
        AppDatabase.getInstance(context).spamNumberDao().deletePersonal(normalize(phoneNumber))
    }
}
