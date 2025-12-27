package com.comet.browser.data.worker

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.comet.browser.data.repository.BrowserRepository
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import timber.log.Timber

@HiltWorker
class CleanupWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val browserRepository: BrowserRepository
) : CoroutineWorker(context, params) {
    
    override suspend fun doWork(): Result {
        return try {
            Timber.d("CleanupWorker: Cleaning old tasks")
            browserRepository.cleanOldTasks(daysOld = 30)
            Timber.d("CleanupWorker: Cleanup completed")
            Result.success()
        } catch (e: Exception) {
            Timber.e(e, "CleanupWorker: Cleanup failed")
            Result.failure()
        }
    }
}
