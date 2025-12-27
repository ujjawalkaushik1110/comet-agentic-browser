package com.comet.browser.data.repository

import com.comet.browser.data.model.AuthRequest
import com.comet.browser.data.model.AuthResponse
import com.comet.browser.data.remote.AuthApiService
import com.comet.browser.domain.model.Resource
import com.comet.browser.utils.SessionManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val authApiService: AuthApiService,
    private val sessionManager: SessionManager
) {
    
    suspend fun login(email: String, password: String): Resource<AuthResponse> {
        return withContext(Dispatchers.IO) {
            try {
                val request = AuthRequest(email, password)
                val response = authApiService.login(request)
                
                if (response.isSuccessful && response.body() != null) {
                    val authResponse = response.body()!!
                    sessionManager.saveAuthToken(authResponse.token)
                    sessionManager.saveUserId(authResponse.userId)
                    sessionManager.saveUserEmail(authResponse.email)
                    Resource.Success(authResponse)
                } else {
                    val errorMsg = response.errorBody()?.string() ?: "Login failed"
                    Timber.e("Login error: $errorMsg")
                    Resource.Error(errorMsg)
                }
            } catch (e: Exception) {
                Timber.e(e, "Login exception")
                Resource.Error(e.localizedMessage ?: "Network error")
            }
        }
    }
    
    suspend fun register(email: String, password: String): Resource<AuthResponse> {
        return withContext(Dispatchers.IO) {
            try {
                val request = AuthRequest(email, password)
                val response = authApiService.register(request)
                
                if (response.isSuccessful && response.body() != null) {
                    val authResponse = response.body()!!
                    sessionManager.saveAuthToken(authResponse.token)
                    sessionManager.saveUserId(authResponse.userId)
                    sessionManager.saveUserEmail(authResponse.email)
                    Resource.Success(authResponse)
                } else {
                    val errorMsg = response.errorBody()?.string() ?: "Registration failed"
                    Timber.e("Registration error: $errorMsg")
                    Resource.Error(errorMsg)
                }
            } catch (e: Exception) {
                Timber.e(e, "Registration exception")
                Resource.Error(e.localizedMessage ?: "Network error")
            }
        }
    }
    
    suspend fun refreshToken(): Resource<AuthResponse> {
        return withContext(Dispatchers.IO) {
            try {
                val response = authApiService.refreshToken()
                
                if (response.isSuccessful && response.body() != null) {
                    val authResponse = response.body()!!
                    sessionManager.saveAuthToken(authResponse.token)
                    Resource.Success(authResponse)
                } else {
                    Resource.Error("Token refresh failed")
                }
            } catch (e: Exception) {
                Timber.e(e, "Token refresh exception")
                Resource.Error(e.localizedMessage ?: "Network error")
            }
        }
    }
    
    suspend fun logout(): Resource<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                authApiService.logout()
                sessionManager.clearSession()
                Resource.Success(Unit)
            } catch (e: Exception) {
                Timber.e(e, "Logout exception")
                sessionManager.clearSession() // Clear anyway
                Resource.Success(Unit)
            }
        }
    }
    
    fun isLoggedIn(): Boolean {
        return sessionManager.getAuthToken() != null
    }
    
    fun getUserEmail(): String? {
        return sessionManager.getUserEmail()
    }
}
