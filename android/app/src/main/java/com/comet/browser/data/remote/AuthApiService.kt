package com.comet.browser.data.remote

import com.comet.browser.data.model.AuthRequest
import com.comet.browser.data.model.AuthResponse
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface AuthApiService {
    
    @POST("auth/login")
    suspend fun login(
        @Body request: AuthRequest
    ): Response<AuthResponse>
    
    @POST("auth/register")
    suspend fun register(
        @Body request: AuthRequest
    ): Response<AuthResponse>
    
    @POST("auth/refresh")
    suspend fun refreshToken(): Response<AuthResponse>
    
    @POST("auth/logout")
    suspend fun logout(): Response<Unit>
}
