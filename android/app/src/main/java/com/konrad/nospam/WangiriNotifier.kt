package com.konrad.nospam

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Avviso "possibile wangiri" per numeri che iniziano con un prefisso della
 * watchlist (WANGIRI_WATCHLIST_PREFIXES lato server). Solo un'etichetta: la
 * chiamata continua a squillare normalmente, non viene bloccata, perché
 * questi prefissi corrispondono a interi paesi con tantissime chiamate
 * legittime.
 */
object WangiriNotifier {
    private const val CHANNEL_ID = "wangiri_watchlist"
    private const val NOTIFICATION_ID = 4201

    fun notify(context: Context, label: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val manager = context.getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Possibile wangiri",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ),
            )
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Possibile chiamata wangiri")
            .setContentText(
                "Chiamata da $label: uno squillo e riattacco per farti richiamare a un numero a " +
                    "tariffazione speciale è una truffa comune. Non richiamare se non riconosci il numero.",
            )
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "Chiamata da $label: uno squillo e riattacco per farti richiamare a un numero a " +
                        "tariffazione speciale è una truffa comune. Non richiamare se non riconosci il numero.",
                ),
            )
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        manager.notify(NOTIFICATION_ID, notification)
    }
}
