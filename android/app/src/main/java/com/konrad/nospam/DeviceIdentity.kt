package com.konrad.nospam

import android.content.Context
import java.security.MessageDigest
import java.util.UUID

/**
 * Per-install random identifier, sent only as an irreversible hash — never
 * the Android ID or ad ID — so reports can be rate-limited without tracking users.
 */
object DeviceIdentity {
    private const val PREFS_NAME = "nospam_prefs"
    private const val KEY_DEVICE_ID = "device_identifier"

    fun hashedDeviceId(context: Context): String {
        val digest = MessageDigest.getInstance("SHA-256")
            .digest(rawDeviceId(context).toByteArray(Charsets.UTF_8))
        return digest.joinToString("") { "%02x".format(it) }
    }

    private fun rawDeviceId(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.getString(KEY_DEVICE_ID, null)?.let { return it }
        val newId = UUID.randomUUID().toString()
        prefs.edit().putString(KEY_DEVICE_ID, newId).apply()
        return newId
    }
}
