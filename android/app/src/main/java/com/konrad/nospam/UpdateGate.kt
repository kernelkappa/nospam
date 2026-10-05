package com.konrad.nospam

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

/**
 * Legge da remoto la versione minima richiesta e blocca l'app se quella
 * installata e' sotto quella soglia. Decidiamo noi, release per release, se
 * alzare la soglia (vedi docs/app_config.json) — non ogni pubblicazione
 * forza l'aggiornamento.
 */
object UpdateGate {
    private const val CONFIG_URL = "https://kernelkappa.github.io/nospam/app_config.json"
    private const val PACKAGE_NAME = "com.konrad.nospam"

    /** Non blocca mai per un errore di rete: in dubbio, lascia usare l'app. */
    suspend fun isUpdateRequired(context: Context): Boolean = withContext(Dispatchers.IO) {
        try {
            val connection = URL(CONFIG_URL).openConnection() as HttpURLConnection
            val body = try {
                connection.requestMethod = "GET"
                if (connection.responseCode !in 200..299) return@withContext false
                connection.inputStream.bufferedReader().use { it.readText() }
            } finally {
                connection.disconnect()
            }
            val minVersionCode = JSONObject(body).getInt("android_min_version_code")
            val currentVersionCode = currentVersionCode(context)
            currentVersionCode < minVersionCode
        } catch (e: Exception) {
            false
        }
    }

    private fun currentVersionCode(context: Context): Int {
        val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode.toInt()
        } else {
            @Suppress("DEPRECATION")
            packageInfo.versionCode
        }
    }

    fun openStoreListing(context: Context) {
        val marketIntent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$PACKAGE_NAME")).apply {
            setPackage("com.android.vending")
        }
        try {
            context.startActivity(marketIntent)
        } catch (e: ActivityNotFoundException) {
            context.startActivity(
                Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("https://play.google.com/store/apps/details?id=$PACKAGE_NAME"),
                ),
            )
        }
    }
}

@Composable
fun UpdateRequiredScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    Column(
        modifier = modifier.fillMaxSize().padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text("Aggiornamento disponibile", style = MaterialTheme.typography.headlineSmall)
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            "È disponibile una nuova versione di NoSpam con correzioni importanti. " +
                "Aggiorna per continuare a usare l'app.",
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(24.dp))
        Button(onClick = { UpdateGate.openStoreListing(context) }) {
            Text("Aggiorna ora")
        }
    }
}
