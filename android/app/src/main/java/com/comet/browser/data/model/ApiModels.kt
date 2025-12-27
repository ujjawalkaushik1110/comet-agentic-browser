package com.comet.browser.data.model

data class BrowseRequest(
    val url: String,
    val actions: List<BrowserAction>? = null,
    val screenshot: Boolean = false,
    val timeout: Long = 30000
)

data class BrowseResponse(
    val url: String,
    val title: String,
    val content: String,
    val screenshot: String?,
    val timestamp: String,
    val taskId: String? = null
)

data class AsyncBrowseResponse(
    val taskId: String,
    val status: String,
    val estimatedTime: Int? = null
)

data class TaskStatusResponse(
    val taskId: String,
    val status: String,
    val progress: Int,
    val result: BrowseResponse?,
    val error: String?
)

data class AuthRequest(
    val email: String,
    val password: String
)

data class AuthResponse(
    val token: String,
    val userId: String,
    val email: String,
    val expiresAt: Long
)

data class ApiError(
    val code: String,
    val message: String,
    val details: Map<String, Any>? = null
)
