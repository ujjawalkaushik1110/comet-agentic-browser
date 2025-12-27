package com.comet.browser.data.local

import androidx.room.*
import com.comet.browser.data.model.BrowseTaskEntity
import com.comet.browser.data.model.TaskStatus
import kotlinx.coroutines.flow.Flow

@Dao
interface BrowseTaskDao {
    
    @Query("SELECT * FROM browse_tasks ORDER BY createdAt DESC")
    fun getAllTasks(): Flow<List<BrowseTaskEntity>>
    
    @Query("SELECT * FROM browse_tasks WHERE status = :status ORDER BY createdAt DESC")
    fun getTasksByStatus(status: TaskStatus): Flow<List<BrowseTaskEntity>>
    
    @Query("SELECT * FROM browse_tasks WHERE id = :taskId")
    suspend fun getTaskById(taskId: String): BrowseTaskEntity?
    
    @Query("SELECT * FROM browse_tasks WHERE id = :taskId")
    fun getTaskByIdFlow(taskId: String): Flow<BrowseTaskEntity?>
    
    @Query("SELECT * FROM browse_tasks WHERE isSynced = 0")
    suspend fun getUnsyncedTasks(): List<BrowseTaskEntity>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTask(task: BrowseTaskEntity)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTasks(tasks: List<BrowseTaskEntity>)
    
    @Update
    suspend fun updateTask(task: BrowseTaskEntity)
    
    @Delete
    suspend fun deleteTask(task: BrowseTaskEntity)
    
    @Query("DELETE FROM browse_tasks WHERE id = :taskId")
    suspend fun deleteTaskById(taskId: String)
    
    @Query("DELETE FROM browse_tasks WHERE status = :status")
    suspend fun deleteTasksByStatus(status: TaskStatus)
    
    @Query("UPDATE browse_tasks SET isSynced = 1 WHERE id = :taskId")
    suspend fun markAsSynced(taskId: String)
    
    @Query("SELECT COUNT(*) FROM browse_tasks WHERE status = :status")
    fun getTaskCountByStatus(status: TaskStatus): Flow<Int>
    
    @Query("DELETE FROM browse_tasks WHERE createdAt < :timestamp")
    suspend fun deleteOldTasks(timestamp: Long)
}
