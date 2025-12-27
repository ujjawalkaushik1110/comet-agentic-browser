package com.comet.browser

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.comet.browser.data.model.AuthRequest
import com.comet.browser.data.model.AuthResponse
import com.comet.browser.data.remote.AuthApiService
import com.comet.browser.data.repository.AuthRepository
import com.comet.browser.domain.model.Resource
import com.comet.browser.utils.SessionManager
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.MockitoAnnotations
import retrofit2.Response

@ExperimentalCoroutinesApi
class AuthRepositoryTest {
    
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()
    
    @Mock
    private lateinit var authApiService: AuthApiService
    
    @Mock
    private lateinit var sessionManager: SessionManager
    
    private lateinit var authRepository: AuthRepository
    
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        authRepository = AuthRepository(authApiService, sessionManager)
    }
    
    @Test
    fun `login success should return success resource and save token`() = runTest {
        // Given
        val email = "test@example.com"
        val password = "password123"
        val authResponse = AuthResponse(
            token = "test-token",
            userId = "user-123",
            email = email,
            expiresAt = System.currentTimeMillis() + 3600000
        )
        
        `when`(authApiService.login(AuthRequest(email, password)))
            .thenReturn(Response.success(authResponse))
        
        // When
        val result = authRepository.login(email, password)
        
        // Then
        assertTrue(result is Resource.Success)
        assertEquals(authResponse, (result as Resource.Success).data)
        verify(sessionManager).saveAuthToken("test-token")
        verify(sessionManager).saveUserId("user-123")
        verify(sessionManager).saveUserEmail(email)
    }
    
    @Test
    fun `login failure should return error resource`() = runTest {
        // Given
        val email = "test@example.com"
        val password = "wrongpassword"
        
        `when`(authApiService.login(AuthRequest(email, password)))
            .thenReturn(Response.error(401, okhttp3.ResponseBody.create(null, "")))
        
        // When
        val result = authRepository.login(email, password)
        
        // Then
        assertTrue(result is Resource.Error)
        verify(sessionManager, never()).saveAuthToken(anyString())
    }
    
    @Test
    fun `isLoggedIn should return true when token exists`() {
        // Given
        `when`(sessionManager.getAuthToken()).thenReturn("test-token")
        
        // When
        val result = authRepository.isLoggedIn()
        
        // Then
        assertTrue(result)
    }
    
    @Test
    fun `isLoggedIn should return false when no token`() {
        // Given
        `when`(sessionManager.getAuthToken()).thenReturn(null)
        
        // When
        val result = authRepository.isLoggedIn()
        
        // Then
        assertFalse(result)
    }
}
