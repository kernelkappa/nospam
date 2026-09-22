package com.konrad.nospam

import androidx.room3.Dao
import androidx.room3.Insert
import androidx.room3.OnConflictStrategy
import androidx.room3.Query
import androidx.room3.Transaction

@Dao
interface SpamPrefixDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entities: List<SpamPrefixEntity>)

    @Query("DELETE FROM spam_prefixes")
    suspend fun deleteAll(): Int

    @Query("SELECT * FROM spam_prefixes")
    suspend fun findAll(): List<SpamPrefixEntity>

    @Transaction
    suspend fun replaceAll(entities: List<SpamPrefixEntity>) {
        deleteAll()
        insertAll(entities)
    }
}
