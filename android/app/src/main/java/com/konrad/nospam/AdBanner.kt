package com.konrad.nospam

import android.widget.FrameLayout
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.AdSize
import com.google.android.gms.ads.AdView
import kotlinx.coroutines.delay

/**
 * ID di TEST ufficiale Google (banner formato fisso 320x50), sicuro da usare
 * in sviluppo. Sostituire con l'ID reale AdMob prima di pubblicare.
 */
private const val AD_UNIT_ID = "ca-app-pub-3940256099942544/6300978111"

/**
 * Il refresh automatico configurabile da dashboard AdMob ha un minimo di 30
 * secondi imposto da Google (refresh più aggressivi rischiano la sospensione
 * dell'account per "invalid traffic"), quindi qui il banner si ricarica
 * manualmente ogni 30 secondi con lo stesso intervallo minimo.
 */
private const val REFRESH_INTERVAL_MS = 30_000L

/**
 * Non mostra nulla finché ConsentManager non ha concluso la raccolta del
 * consenso GDPR (l'SDK AdMob non è nemmeno inizializzato prima di allora).
 */
@Composable
fun AdBanner(modifier: Modifier = Modifier) {
    if (!ConsentManager.canRequestAds.value) return

    val context = LocalContext.current
    val adView = remember {
        AdView(context).apply {
            setAdSize(AdSize.BANNER)
            adUnitId = AD_UNIT_ID
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
            )
        }
    }

    LaunchedEffect(adView) {
        while (true) {
            adView.loadAd(AdRequest.Builder().build())
            delay(REFRESH_INTERVAL_MS)
        }
    }

    DisposableEffect(adView) {
        onDispose { adView.destroy() }
    }

    AndroidView(factory = { adView }, modifier = modifier.fillMaxWidth())
}
