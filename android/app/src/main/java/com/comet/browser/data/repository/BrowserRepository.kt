package com.comet.browser.data.repository

import com.comet.browser.data.local.BrowseTaskDao
import com.comet.browser.data.model.*
import com.comet.browser.data.remote.BrowserApiService
import com.comet.browser.domain.model.Resource
import com.comet.browser.utils.NetworkUtils
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.withContext
import timber.log.Timber
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class BrowserRepository @Inject constructor(
    private val apiService: BrowserApiService,
    private val taskDao: BrowseTaskDao,
    private val networkUtils: NetworkUtils
) {
    
    fun getAllTasks(): Flow<List<BrowseTaskEntity>> {
        return taskDao.getAllTasks()
    }
    
    fun getTasksByStatus(status: TaskStatus): Flow<List<BrowseTaskEntity>> {
        return taskDao.getTasksByStatus(status)
    }
    
    fun getTaskById(taskId: String): Flow<BrowseTaskEntity?> {
        return taskDao.getTaskByIdFlow(taskId)
    }
    
    suspend fun browseSynchronous(request: BrowseRequest): Resource<BrowseResponse> {
        return withContext(Dispatchers.IO) {
            try {
                // Create local task
                val taskId = UUID.randomUUID().toString()
                val task = BrowseTaskEntity(
                    id = taskId,
                    url = request.url,
                    title = null,
                    status = TaskStatus.IN_PROGRESS,
                    createdAt = Date(),
                    updatedAt = Date(),
                    completedAt = null,
                    content = null,
                    screenshot = null,
                    actions = request.actions,
                    errorMessage = null,
                    isSynced = false
                )
                taskDao.insertTask(task)
                
                // Make API call
                val response = apiService.browseSynchronous(request)
                
                if (response.isSuccessful && response.body() != null) {
                    val result = response.body()!!
                    
                    // Update local task
                    val updatedTask = task.copy(
                        title = result.title,
                        status = TaskStatus.COMPLETED,
                        updatedAt = Date(),
                        completedAt = Date(),
                        content = result.content,
                        screenshot = result.screenshot,
                        isSynced = true
                    )
                    taskDao.updateTask(updatedTask)
                    
                    Resource.Success(result)
                } else {
                    val errorMsg = response.errorBody()?.string() ?: "Unknown error"
                    Timber.e("API Error: $errorMsg")
                    
                    // Update task with error
                    val failedTask = task.copy(
                        status = TaskStatus.FAILED,
                        errorMessage = errorMsg,
                        updatedAt = Date()
                    )
                    taskDao.updateTask(failedTask)
                    
                    Resource.Error(errorMsg)
                }
            } catch (e: Exception) {
                Timber.e(e, "Exception in browseSynchronous")
                Resource.Error(e.localizedMessage ?: "Network error")
            }
        }
    }
    
    suspend fun browseAsynchronous(request: BrowseRequest): Resource<AsyncBrowseResponse> {
        return withContext(Dispatchers.IO) {
            try {
                val response = apiService.browseAsynchronous(request)
                
                if (response.isSuccessful && response.body() != null) {
                    val result = response.body()!!
                    
                    // Create local task
                    val task = BrowseTaskEntity(
                        id = result.taskId,
                        url = request.url,
                        title = null,
                        status = TaskStatus.PENDING,
                        createdAt = Date(),
                        updatedAt = Date(),
                        completedAt = null,
                        content = null,
                        screenshot = null,
                        actions = request.actions,
                        errorMessage = null,
                        isSynced = false
                    )
                    taskDao.insertTask(task)
                    
                    Resource.Success(result)
                } else {
                    Resource.Error(response.errorBody()?.string() ?: "Unknown error")
                }
            } catch (e: Exception) {
                Timber.e(e, "Exception in browseAsynchronous")
                Resource.Error(e.localizedMessage ?: "Network error")
            }
        }
    }
    
    suspend fun getTaskStatus(taskId: String): Resource<TaskStatusResponse> {
        return withContext(Dispatchers.IO) {
            try {
                val response = apiService.getTaskStatus(taskId)
                
                if (response.isSuccessful && response.body() != null) {
                    val result = response.body()!!
                    
                    // Update local task
                    val localTask = taskDao.getTaskById(taskId)
                    if (localTask != null) {
                        val status = when (result.status.uppercase()) {
                            "PENDING" -> TaskStatus.PENDING
                            "IN_PROGRESS", "PROCESSING" -> TaskStatus.IN_PROGRESS
                            "COMPLETED", "SUCCESS" -> TaskStatus.COMPLETED
                            "FAILED", "ERROR" -> TaskStatus.FAILED
                            else -> TaskStatus.PENDING
                        }
                        
                        val updatedTask = localTask.copy(
                            status = status,
                            updatedAt = Date(),
                            completedAt = if (status == TaskStatus.COMPLETED) Date() else null,
                            title = result.result?.title,
                            content = result.result?.content,
                            screenshot = result.result?.screenshot,
                            errorMessage = result.error,
                            isSynced = true
                        )
                        taskDao.updateTask(updatedTask)
                    }
                    
                    Resource.Success(result)
                } else {
                    Resource.Error(response.errorBody()?.string() ?: "Unknown error")
                }
            } catch (e: Exception) {
                Timber.e(e, "Exception in getTaskStatus")
                Resource.Error(e.localizedMessage ?: "Network error")
            }
        }
    }
    
    suspend fun cancelTask(taskId: String): Resource<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                val response = apiService.cancelTask(taskId)
                
                if (response.isSuccessful) {
                    // Update local task
                    val localTask = taskDao.getTaskById(taskId)
                    if (localTask != null) {
                        val cancelledTask = localTask.copy(
                            status = TaskStatus.CANCELLED,
                            updatedAt = Date()
                        )
                        taskDao.updateTask(cancelledTask)
                    }
                    
                    Resource.Success(Unit)
                } else {
                    Resource.Error(response.errorBody()?.string() ?: "Unknown error")
                }
            } catch (e: Exception) {
                Timber.e(e, "Exception in cancelTask")
                Resource.Error(e.localizedMessage ?: "Network error")
            }
        }
    }
    
    suspend fun deleteTask(taskId: String) {
        withContext(Dispatchers.IO) {
            taskDao.deleteTaskById(taskId)
        }
    }
    
    suspend fun syncTasks() {
        withContext(Dispatchers.IO) {
            if (!networkUtils.isConnected()) {
                Timber.w("No network connection, skipping sync")
                return@withContext
            }
            
            val unsyncedTasks = taskDao.getUnsyncedTasks()
            Timber.d("Syncing ${unsyncedTasks.size} tasks")
            
            unsyncedTasks.forEach { task ->
                try {
                    when (task.status) {
                        TaskStatus.PENDING, TaskStatus.IN_PROGRESS -> {
                            // Check status from server
                            getTaskStatus(task.id)
                        }
                        else -> {
                            // Mark as synced
                            taskDao.markAsSynced(task.id)
                        }
                    }
                } catch (e: Exception) {
                    Timber.e(e, "Failed to sync task ${task.id}")
                }
            }
        }
    }
    
    suspend fun cleanOldTasks(daysOld: Int = 30) {
        withContext(Dispatchers.IO) {
            val timestamp = System.currentTimeMillis() - (daysOld * 24 * 60 * 60 * 1000L)
            taskDao.deleteOldTasks(timestamp)
        }
    }
}
