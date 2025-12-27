package com.comet.browser

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.comet.browser.presentation.auth.AuthViewModel
import com.comet.browser.data.repository.AuthRepository
import com.comet.browser.data.model.AuthResponse
import com.comet.browser.domain.model.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.mockito.Mock
import org.mockito.Mockito.*
import org.mockito.MockitoAnnotations

@ExperimentalCoroutinesApi
class AuthViewModelTest {
    
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()
    
    private val testDispatcher = StandardTestDispatcher()
    
    @Mock
    private lateinit var authRepository: AuthRepository
    
    private lateinit var viewModel: AuthViewModel
    
    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        Dispatchers.setMain(testDispatcher)
        viewModel = AuthViewModel(authRepository)
    }
    
    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }
    
    @Test
    fun `login should emit loading then success`() = runTest {
        // Given
        val email = "test@example.com"
        val password = "password123"
        val authResponse = AuthResponse("token", "userId", email, 0)
        
        `when`(authRepository.login(email, password))
            .thenReturn(Resource.Success(authResponse))
        
        // When
        viewModel.login(email, password)
        testDispatcher.scheduler.advanceUntilIdle()
        
        // Then
        val state = viewModel.authState.value
        assertTrue(state is Resource.Success)
        assertEquals(authResponse, (state as Resource.Success).data)
    }
    
    @Test
    fun `validateEmail should return true for valid email`() {
        assertTrue(viewModel.validateEmail("test@example.com"))
        assertTrue(viewModel.validateEmail("user.name@domain.co.uk"))
    }
    
    @Test
    fun `validateEmail should return false for invalid email`() {
        assertFalse(viewModel.validateEmail("invalid"))
        assertFalse(viewModel.validateEmail("@example.com"))
        assertFalse(viewModel.validateEmail("test@"))
    }
    
    @Test
    fun `validatePassword should return true for valid password`() {
        assertTrue(viewModel.validatePassword("password123"))
        assertTrue(viewModel.validatePassword("12345678"))
    }
    
    @Test
    fun `validatePassword should return false for short password`() {
        assertFalse(viewModel.validatePassword("1234567"))
        assertFalse(viewModel.validatePassword("short"))
    }
}
