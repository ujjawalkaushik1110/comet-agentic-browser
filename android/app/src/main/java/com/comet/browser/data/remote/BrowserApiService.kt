package com.comet.browser.data.remote

import com.comet.browser.data.model.*
import retrofit2.Response
import retrofit2.http.*

interface BrowserApiService {
    
    @POST("browse/sync")
    suspend fun browseSynchronous(
        @Body request: BrowseRequest
    ): Response<BrowseResponse>
    
    @POST("browse/async")
    suspend fun browseAsynchronous(
        @Body request: BrowseRequest
    ): Response<AsyncBrowseResponse>
    
    @GET("browse/status/{taskId}")
    suspend fun getTaskStatus(
        @Path("taskId") taskId: String
    ): Response<TaskStatusResponse>
    
    @GET("browse/history")
    suspend fun getBrowseHistory(
        @Query("limit") limit: Int = 50,
        @Query("offset") offset: Int = 0
    ): Response<List<BrowseResponse>>
    
    @DELETE("browse/task/{taskId}")
    suspend fun cancelTask(
        @Path("taskId") taskId: String
    ): Response<Unit>
    
    @GET("health")
    suspend fun healthCheck(): Response<Map<String, Any>>
    
    @GET("metrics")
    suspend fun getMetrics(): Response<String>
}
