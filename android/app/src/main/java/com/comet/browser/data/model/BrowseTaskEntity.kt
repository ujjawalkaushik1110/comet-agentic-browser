package com.comet.browser.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.comet.browser.data.local.Converters
import java.util.Date

@Entity(tableName = "browse_tasks")
@TypeConverters(Converters::class)
data class BrowseTaskEntity(
    @PrimaryKey
    val id: String,
    val url: String,
    val title: String?,
    val status: TaskStatus,
    val createdAt: Date,
    val updatedAt: Date,
    val completedAt: Date?,
    val content: String?,
    val screenshot: String?, // Base64 or URL
    val actions: List<BrowserAction>?,
    val errorMessage: String?,
    val retryCount: Int = 0,
    val isSynced: Boolean = false
)

enum class TaskStatus {
    PENDING,
    IN_PROGRESS,
    COMPLETED,
    FAILED,
    CANCELLED
}

data class BrowserAction(
    val type: ActionType,
    val selector: String?,
    val text: String?,
    val timeout: Long = 30000
)

enum class ActionType {
    CLICK,
    TYPE,
    WAIT,
    SCREENSHOT,
    SCROLL,
    NAVIGATE
}
