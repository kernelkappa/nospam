package com.konrad.nospam

import androidx.room3.Entity
import androidx.room3.PrimaryKey

object PrefixMode {
    const val BLOCK = "block"
    const val IDENTIFY = "identify"
}

@Entity(tableName = "spam_prefixes")
data class SpamPrefixEntity(
    // Senza "+", solo cifre: confrontata con l'inizio del numero in arrivo.
    @PrimaryKey val digitsOnlyPrefix: String,
    val label: String,
    val mode: String,
    val source: String,
)
