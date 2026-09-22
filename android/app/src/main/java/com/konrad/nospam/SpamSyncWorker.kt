package com.konrad.nospam

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

class SpamSyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result =
        try {
            SpamDatabaseSync.sync(applicationContext)
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
}
