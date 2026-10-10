package com.konrad.nospam

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.CancellationException

class SpamSyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result =
        try {
            SpamDatabaseSync.sync(applicationContext)
            Result.success()
        } catch (e: CancellationException) {
            // WorkManager ha interrotto il worker lui stesso (vincoli non piu'
            // soddisfatti, nuovo lavoro che lo rimpiazza, ecc.): non e' un
            // errore da segnalare, e va rilanciata non intercettata perche'
            // la cancellazione di una coroutine si propaghi correttamente.
            throw e
        } catch (e: Exception) {
            ErrorReporter.report(applicationContext, e, "SpamSyncWorker.doWork")
            Result.retry()
        }
}
