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
            val match = if (digitsOnly.isNotEmpty()) {
                AppDatabase.getInstance(applicationContext).spamNumberDao().findByDigitsOnly(digitsOnly)
            } else {
                null
            }

            val response = if (match != null) {
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
        }
    }
}
