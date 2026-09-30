package com.konrad.nospam

import android.app.Activity
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import com.google.android.gms.ads.MobileAds
import com.google.android.ump.ConsentRequestParameters
import com.google.android.ump.UserMessagingPlatform

/**
 * Raccoglie il consenso GDPR tramite Google UMP: il form viene mostrato solo
 * se l'utente e' geolocalizzato in SEE/UK/Svizzera, altrimenti si prosegue
 * subito. Android non ha un equivalente di App Tracking Transparency (l'AD_ID
 * non richiede un prompt di sistema), quindi qui il consenso e' l'unico
 * passaggio. L'SDK AdMob viene avviato solo dopo, cosi' la personalizzazione
 * riflette la scelta reale dell'utente invece di essere disattivata a priori.
 */
object ConsentManager {
    val canRequestAds: MutableState<Boolean> = mutableStateOf(false)

    private var didStart = false

    fun start(activity: Activity) {
        if (didStart) return
        didStart = true

        val params = ConsentRequestParameters.Builder().build()
        val consentInformation = UserMessagingPlatform.getConsentInformation(activity)

        consentInformation.requestConsentInfoUpdate(
            activity,
            params,
            {
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity) { formError ->
                    if (formError != null) {
                        android.util.Log.w("ConsentManager", "Errore form di consenso: ${formError.message}")
                    }
                    finish(activity, consentInformation.canRequestAds())
                }
            },
            { requestConsentError ->
                android.util.Log.w("ConsentManager", "Errore aggiornamento consenso: ${requestConsentError.message}")
                finish(activity, consentInformation.canRequestAds())
            },
        )
    }

    private fun finish(activity: Activity, canRequestAdsNow: Boolean) {
        if (!canRequestAdsNow) return
        MobileAds.initialize(activity.applicationContext)
        canRequestAds.value = true
    }
}
