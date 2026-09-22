package com.konrad.nospam

import android.telecom.Call
import android.telecom.CallScreeningService
import android.telecom.CallScreeningService.CallResponse
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class SpamCallScreeningService : CallScreeningService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onScreenCall(callDetails: Call.Details) {
        val incomingNumber = callDetails.handle?.schemeSpecificPart.orEmpty()
        val digitsOnly = incomingNumber.filter(Char::isDigit)

        scope.launch {
            val dao = AppDatabase.getInstance(applicationContext)
            val exactMatch = if (digitsOnly.isNotEmpty()) {
                dao.spamNumberDao().findByDigitsOnly(digitsOnly)
            } else {
                null
            }

            val prefixMatch = if (exactMatch == null && digitsOnly.isNotEmpty()) {
                dao.spamPrefixDao().findAll().firstOrNull { digitsOnly.startsWith(it.digitsOnlyPrefix) }
            } else {
                null
            }

            val shouldBlock = exactMatch != null || prefixMatch?.mode == PrefixMode.BLOCK

            val response = if (shouldBlock) {
                CallResponse.Builder()
                    .setDisallowCall(true)
                    .setRejectCall(true)
                    .setSkipCallLog(false)
                    .setSkipNotification(false)
                    .build()
            } else {
                CallResponse.Builder().build()
            }

            respondToCall(callDetails, response)

            if (prefixMatch?.mode == PrefixMode.IDENTIFY) {
                WangiriNotifier.notify(applicationContext, prefixMatch.label)
            }
        }
    }
}
