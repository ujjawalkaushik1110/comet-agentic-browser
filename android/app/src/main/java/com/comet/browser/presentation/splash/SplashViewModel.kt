package com.comet.browser.presentation.splash

import androidx.lifecycle.ViewModel
import com.comet.browser.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class SplashViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {
    
    fun isLoggedIn(): Boolean {
        return authRepository.isLoggedIn()
    }
}
