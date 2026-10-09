package com.konrad.nospam

import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.core.os.LocaleListCompat

private enum class SupportedLanguage(val tag: String?, val labelRes: Int) {
    AUTOMATIC(null, R.string.settings_language_automatic),
    ITALIAN("it", R.string.settings_language_it),
    ENGLISH("en", R.string.settings_language_en),
    SPANISH("es", R.string.settings_language_es),
    FRENCH("fr", R.string.settings_language_fr),
    GERMAN("de", R.string.settings_language_de),
    PORTUGUESE("pt", R.string.settings_language_pt),
    PORTUGUESE_BRAZIL("pt-BR", R.string.settings_language_pt_br),
    ARABIC("ar", R.string.settings_language_ar),
    BENGALI("bn", R.string.settings_language_bn),
    CATALAN("ca", R.string.settings_language_ca),
    CHINESE_SIMPLIFIED("zh-Hans", R.string.settings_language_zh_hans),
    CHINESE_TRADITIONAL("zh-Hant", R.string.settings_language_zh_hant),
    CROATIAN("hr", R.string.settings_language_hr),
    CZECH("cs", R.string.settings_language_cs),
    DANISH("da", R.string.settings_language_da),
    DUTCH("nl", R.string.settings_language_nl),
    FINNISH("fi", R.string.settings_language_fi),
    GREEK("el", R.string.settings_language_el),
    GUJARATI("gu", R.string.settings_language_gu),
    HEBREW("he", R.string.settings_language_he),
    HINDI("hi", R.string.settings_language_hi),
    HUNGARIAN("hu", R.string.settings_language_hu),
    INDONESIAN("id", R.string.settings_language_id),
    JAPANESE("ja", R.string.settings_language_ja),
    KANNADA("kn", R.string.settings_language_kn),
    KOREAN("ko", R.string.settings_language_ko),
    MALAY("ms", R.string.settings_language_ms),
    MALAYALAM("ml", R.string.settings_language_ml),
    MARATHI("mr", R.string.settings_language_mr),
    NORWEGIAN("nb", R.string.settings_language_nb),
    ODIA("or", R.string.settings_language_or),
    POLISH("pl", R.string.settings_language_pl),
    PUNJABI("pa", R.string.settings_language_pa),
    ROMANIAN("ro", R.string.settings_language_ro),
    RUSSIAN("ru", R.string.settings_language_ru),
    SLOVAK("sk", R.string.settings_language_sk),
    SLOVENIAN("sl", R.string.settings_language_sl),
    SWEDISH("sv", R.string.settings_language_sv),
    TAMIL("ta", R.string.settings_language_ta),
    TELUGU("te", R.string.settings_language_te),
    THAI("th", R.string.settings_language_th),
    TURKISH("tr", R.string.settings_language_tr),
    UKRAINIAN("uk", R.string.settings_language_uk),
    URDU("ur", R.string.settings_language_ur),
    VIETNAMESE("vi", R.string.settings_language_vi),
}

@Composable
fun SettingsScreen(themeMode: MutableState<ThemeMode>, onOpenCredits: () -> Unit, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        Text(text = stringResource(R.string.settings_theme_title), style = MaterialTheme.typography.titleMedium)

        SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
            val options = listOf(
                ThemeMode.SYSTEM to stringResource(R.string.settings_theme_system),
                ThemeMode.LIGHT to stringResource(R.string.settings_theme_light),
                ThemeMode.DARK to stringResource(R.string.settings_theme_dark),
            )
            options.forEachIndexed { index, (mode, label) ->
                SegmentedButton(
                    selected = themeMode.value == mode,
                    onClick = { themeMode.value = mode },
                    shape = SegmentedButtonDefaults.itemShape(index = index, count = options.size),
                ) {
                    Text(label)
                }
            }
        }

        HorizontalDivider()

        Text(text = stringResource(R.string.settings_language_title), style = MaterialTheme.typography.titleMedium)
        Text(
            text = stringResource(R.string.settings_language_description),
            style = MaterialTheme.typography.bodyMedium,
        )

        var expanded by remember { mutableStateOf(false) }
        val currentTag = AppCompatDelegate.getApplicationLocales().takeIf { !it.isEmpty }?.get(0)?.toLanguageTag()
        val current = SupportedLanguage.entries.firstOrNull { it.tag == currentTag } ?: SupportedLanguage.AUTOMATIC

        OutlinedButton(onClick = { expanded = true }) {
            Text(stringResource(current.labelRes))
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            SupportedLanguage.entries.forEach { language ->
                DropdownMenuItem(
                    text = { Text(stringResource(language.labelRes)) },
                    onClick = {
                        expanded = false
                        val locales = if (language.tag == null) {
                            LocaleListCompat.getEmptyLocaleList()
                        } else {
                            LocaleListCompat.forLanguageTags(language.tag)
                        }
                        AppCompatDelegate.setApplicationLocales(locales)
                    },
                )
            }
        }

        HorizontalDivider()

        TextButton(onClick = onOpenCredits) {
            Text(stringResource(R.string.credits_title))
        }
    }
}
