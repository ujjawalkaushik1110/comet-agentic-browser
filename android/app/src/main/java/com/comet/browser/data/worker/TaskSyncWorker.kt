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
class TaskSyncWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val browserRepository: BrowserRepository
) : CoroutineWorker(context, params) {
    
    override suspend fun doWork(): Result {
        return try {
            Timber.d("TaskSyncWorker: Starting sync")
            browserRepository.syncTasks()
            Timber.d("TaskSyncWorker: Sync completed")
            Result.success()
        } catch (e: Exception) {
            Timber.e(e, "TaskSyncWorker: Sync failed")
            if (runAttemptCount < 3) {
                Result.retry()
            } else {
                Result.failure()
            }
        }
    }
}
