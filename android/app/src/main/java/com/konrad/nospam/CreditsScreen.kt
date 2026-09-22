package com.konrad.nospam

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp

private data class DataSource(
    val name: String,
    val description: String,
    val license: String?,
    val url: String,
)

private val dataSources = listOf(
    DataSource(
        name = "Segnalazioni utenti NoSpam",
        description = "Numeri segnalati direttamente dalla community di NoSpam (almeno 5 segnalazioni da utenti diversi).",
        license = null,
        url = "https://github.com/kernelkappa/nospam",
    ),
    DataSource(
        name = "ShopSicuro",
        description = "Progetto MIMIT \"Squadra Antifrode\" · Federazione iConsumatori.",
        license = null,
        url = "https://www.shopsicuro.it/numeri-spam",
    ),
    DataSource(
        name = "blocklist-telefonica-italia",
        description = "Lista aperta e mantenuta dalla community, a cura di thesqual87 / Kallm.",
        license = "CC BY-SA 4.0",
        url = "https://github.com/thesqual87/blocklist-telefonica-italia",
    ),
    DataSource(
        name = "lista-telefonos-spam",
        description = "Lista di numeri spam spagnoli, a cura di mv12star.",
        license = "Unlicense (pubblico dominio)",
        url = "https://github.com/mv12star/lista-telefonos-spam",
    ),
    DataSource(
        name = "nophonespam-fr",
        description = "Intervalli di prefissi telemarketing francesi, a cura di jeromerobert (fonte dati " +
            "anche dell'app open source NoPhoneSpam). Nessuna licenza esplicita dichiarata dall'autore.",
        license = null,
        url = "https://github.com/jeromerobert/nophonespam-fr",
    ),
    DataSource(
        name = "Watchlist wangiri",
        description = "Prefissi internazionali spesso citati in segnalazioni di truffe \"wangiri\" (uno " +
            "squillo per indurre a richiamare un numero a tariffazione speciale). Solo avviso, le chiamate " +
            "non vengono bloccate perché sono interi paesi con tante chiamate legittime.",
        license = null,
        url = "https://www.europol.europa.eu/publications-events/publications/wangiri-%E2%80%93-telephone-scam",
    ),
)

@Composable
fun CreditsScreen(modifier: Modifier = Modifier) {
    val context = LocalContext.current

    Column(
        modifier = modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        Text(text = "Fonti dati", style = MaterialTheme.typography.titleMedium)

        dataSources.forEach { source ->
            Column {
                Text(text = source.name, style = MaterialTheme.typography.titleSmall)
                Text(text = source.description, style = MaterialTheme.typography.bodyMedium)
                source.license?.let {
                    Text(text = "Licenza: $it", style = MaterialTheme.typography.bodySmall)
                }
                TextButton(
                    onClick = {
                        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(source.url)))
                    },
                ) {
                    Text(text = "Apri fonte", textDecoration = TextDecoration.Underline)
                }
            }
        }
    }
}
