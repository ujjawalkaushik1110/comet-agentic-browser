package com.comet.browser.presentation.auth

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.comet.browser.data.model.AuthResponse
import com.comet.browser.data.repository.AuthRepository
import com.comet.browser.domain.model.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {
    
    private val _authState = MutableLiveData<Resource<AuthResponse>>()
    val authState: LiveData<Resource<AuthResponse>> = _authState
    
    fun login(email: String, password: String) {
        viewModelScope.launch {
            _authState.value = Resource.Loading
            val result = authRepository.login(email, password)
            _authState.value = result
        }
    }
    
    fun register(email: String, password: String) {
        viewModelScope.launch {
            _authState.value = Resource.Loading
            val result = authRepository.register(email, password)
            _authState.value = result
        }
    }
    
    fun validateEmail(email: String): Boolean {
        return android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()
    }
    
    fun validatePassword(password: String): Boolean {
        return password.length >= 8
    }
}
