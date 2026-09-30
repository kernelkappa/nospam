package com.konrad.nospam

import android.app.Application
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration
import java.util.concurrent.TimeUnit

class NoSpamApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Ads non personalizzate: evita la complessita' del consenso GDPR
        // per le ads personalizzate in UE (vedi anche il lato iOS).
        MobileAds.setRequestConfiguration(
            RequestConfiguration.Builder()
                .setPublisherPrivacyPersonalizationState(
                    RequestConfiguration.PublisherPrivacyPersonalizationState.DISABLED,
                )
                .build(),
        )
        MobileAds.initialize(this)

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
