package com.konrad.nospam

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue

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

/** Stato osservabile del tema corrente, cosi' il cambio si riflette subito nella UI. */
@Composable
fun rememberThemeMode(context: Context): androidx.compose.runtime.MutableState<ThemeMode> {
    return remember { mutableStateOf(ThemePreference.get(context)) }
}
