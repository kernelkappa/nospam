package com.konrad.nospam

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember

enum class ThemeMode(val prefValue: String) {
    SYSTEM("system"),
    LIGHT("light"),
    DARK("dark"),
    ;

    companion object {
        fun fromPrefValue(value: String?): ThemeMode = entries.firstOrNull { it.prefValue == value } ?: SYSTEM
    }
}

private const val PREFS_NAME = "nospam_prefs"
private const val KEY_THEME_MODE = "theme_mode"

object ThemePreference {
    fun get(context: Context): ThemeMode {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return ThemeMode.fromPrefValue(prefs.getString(KEY_THEME_MODE, null))
    }

    fun set(context: Context, mode: ThemeMode) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_THEME_MODE, mode.prefValue)
            .apply()
    }
}

/** Stato osservabile del tema corrente: scrivere su `.value` aggiorna anche
 * subito la UI (via AppCompatDelegate, che puo' ricreare l'Activity) E
 * persiste la scelta, cosi' la nuova istanza dell'Activity la ritrova. */
@Composable
fun rememberThemeMode(context: Context): MutableState<ThemeMode> {
    val backing = remember { mutableStateOf(ThemePreference.get(context)) }
    return remember {
        object : MutableState<ThemeMode> by backing {
            override var value: ThemeMode
                get() = backing.value
                set(mode) {
                    backing.value = mode
                    ThemePreference.set(context, mode)
                }
        }
    }
}
