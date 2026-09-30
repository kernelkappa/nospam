package com.konrad.nospam

import android.app.Application
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class NoSpamApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // L'SDK AdMob viene avviato da ConsentManager (da MainActivity) solo
        // dopo la raccolta del consenso GDPR (Google UMP).
        scheduleDailySync()
    }

    private fun scheduleDailySync() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val request = PeriodicWorkRequestBuilder<SpamSyncWorker>(24, TimeUnit.HOURS)
            .setConstraints(constraints)
            .build()

        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "spam-db-daily-sync",
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }
}
