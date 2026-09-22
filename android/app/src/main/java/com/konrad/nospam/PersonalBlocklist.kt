package com.konrad.nospam

import android.content.Context

object PersonalBlocklist {
    suspend fun add(context: Context, phoneNumber: String, category: String = "personale") {
        val entity = SpamNumberEntity(
            phoneNumber = phoneNumber,
            category = category,
            reportCount = 0,
            digitsOnly = phoneNumber.filter(Char::isDigit),
            source = NumberSource.PERSONAL,
        )
        AppDatabase.getInstance(context).spamNumberDao().insertOne(entity)
    }

    suspend fun remove(context: Context, phoneNumber: String) {
        AppDatabase.getInstance(context).spamNumberDao().deletePersonal(phoneNumber)
    }
}
