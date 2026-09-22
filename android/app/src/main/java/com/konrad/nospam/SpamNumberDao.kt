package com.konrad.nospam

import androidx.room3.Dao
import androidx.room3.Insert
import androidx.room3.OnConflictStrategy
import androidx.room3.Query
import androidx.room3.Transaction

@Dao
interface SpamNumberDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entities: List<SpamNumberEntity>)

    @Query("DELETE FROM spam_numbers")
    suspend fun deleteAll()

    @Query("SELECT * FROM spam_numbers WHERE digitsOnly = :digitsOnly LIMIT 1")
    suspend fun findByDigitsOnly(digitsOnly: String): SpamNumberEntity?

    @Query("SELECT COUNT(*) FROM spam_numbers")
    suspend fun count(): Int

    @Transaction
    suspend fun replaceAll(entities: List<SpamNumberEntity>) {
        deleteAll()
        insertAll(entities)
    }
}
