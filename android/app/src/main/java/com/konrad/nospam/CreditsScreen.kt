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
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp

private data class DataSource(
    /** Letterale per i nomi propri di progetti/nickname esterni (citazione,
     * non si traducono); [nameRes] per le nostre etichette, tradotte. */
    val name: String,
    val nameRes: Int? = null,
    val descriptionRes: Int,
    val license: String?,
    val url: String,
    /** Vero solo per licenze equivalenti al pubblico dominio, per aggiungere
     * la nota tradotta "(dominio pubblico)" dopo il nome della licenza. */
    val isPublicDomain: Boolean = false,
)

private val dataSources = listOf(
    DataSource(
        name = "Segnalazioni utenti NoSpam",
        nameRes = R.string.credits_source_community_name,
        descriptionRes = R.string.credits_source_community_desc,
        license = null,
        url = "https://github.com/kernelkappa/nospam",
    ),
    DataSource(
        name = "ShopSicuro",
        descriptionRes = R.string.credits_source_shopsicuro_desc,
        license = null,
        url = "https://www.shopsicuro.it/numeri-spam",
    ),
    DataSource(
        name = "blocklist-telefonica-italia",
        descriptionRes = R.string.credits_source_blocklist_it_desc,
        license = "CC BY-SA 4.0",
        url = "https://github.com/thesqual87/blocklist-telefonica-italia",
    ),
    DataSource(
        name = "lista-telefonos-spam",
        descriptionRes = R.string.credits_source_lista_es_desc,
        license = "Unlicense",
        url = "https://github.com/mv12star/lista-telefonos-spam",
        isPublicDomain = true,
    ),
    DataSource(
        name = "callavert-spam-list",
        descriptionRes = R.string.credits_source_callavert_desc,
        license = "CC0 1.0",
        url = "https://github.com/Call-Avert/callavert-spam-list",
    ),
    DataSource(
        name = "nophonespam-fr",
        descriptionRes = R.string.credits_source_nophonespam_fr_desc,
        license = null,
        url = "https://github.com/jeromerobert/nophonespam-fr",
    ),
    DataSource(
        name = "Prefissi telemarketing regolamentati",
        descriptionRes = R.string.credits_source_regulatory_prefixes_desc,
        license = null,
        url = "https://www.trai.gov.in/",
    ),
    DataSource(
        name = "Watchlist wangiri",
        descriptionRes = R.string.credits_source_wangiri_desc,
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
        Text(text = stringResource(R.string.credits_data_sources_title), style = MaterialTheme.typography.titleMedium)

        dataSources.forEach { source ->
            Column {
                val displayName = source.nameRes?.let { stringResource(it) } ?: source.name
                Text(text = displayName, style = MaterialTheme.typography.titleSmall)
                Text(text = stringResource(source.descriptionRes), style = MaterialTheme.typography.bodyMedium)
                source.license?.let {
                    val licenseText = if (source.isPublicDomain) {
                        "$it ${stringResource(R.string.credits_public_domain_note)}"
                    } else {
                        it
                    }
                    Text(text = stringResource(R.string.license_label, licenseText), style = MaterialTheme.typography.bodySmall)
                }
                TextButton(
                    onClick = {
                        context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(source.url)))
                    },
                ) {
                    Text(text = stringResource(R.string.open_source_button), textDecoration = TextDecoration.Underline)
                }
            }
        }
    }
}
