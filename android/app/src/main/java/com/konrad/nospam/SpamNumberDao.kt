package com.konrad.nospam

import androidx.room3.Dao
import androidx.room3.Insert
import androidx.room3.OnConflictStrategy
import androidx.room3.Query
import androidx.room3.Transaction
import kotlinx.coroutines.flow.Flow

@Dao
interface SpamNumberDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entities: List<SpamNumberEntity>)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOne(entity: SpamNumberEntity)

    @Query("DELETE FROM spam_numbers WHERE source = 'community'")
    suspend fun deleteAllCommunity(): Int

    @Query("DELETE FROM spam_numbers WHERE phoneNumber = :phoneNumber AND source = 'personal'")
    suspend fun deletePersonal(phoneNumber: String): Int

    @Query("SELECT * FROM spam_numbers WHERE digitsOnly = :digitsOnly LIMIT 1")
    suspend fun findByDigitsOnly(digitsOnly: String): SpamNumberEntity?

    @Query("SELECT * FROM spam_numbers ORDER BY phoneNumber")
    fun observeAll(): Flow<List<SpamNumberEntity>>

    @Transaction
    suspend fun replaceCommunityEntries(entities: List<SpamNumberEntity>) {
        deleteAllCommunity()
        insertAll(entities)
    }
}
