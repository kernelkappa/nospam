package com.konrad.nospam

import androidx.room3.Entity
import androidx.room3.PrimaryKey

object NumberSource {
    const val COMMUNITY = "community"
    const val PERSONAL = "personal"
}

@Entity(tableName = "spam_numbers")
data class SpamNumberEntity(
    @PrimaryKey val phoneNumber: String,
    val category: String,
    val reportCount: Int,
    // Le chiamate in arrivo possono non includere il prefisso "+": confrontiamo
    // sempre su questa colonna, popolata togliendo tutti i caratteri non numerici.
    val digitsOnly: String,
    val source: String,
)
