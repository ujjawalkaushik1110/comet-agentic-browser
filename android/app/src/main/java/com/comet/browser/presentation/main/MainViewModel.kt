package com.comet.browser.presentation.main

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.comet.browser.data.model.BrowseRequest
import com.comet.browser.data.model.BrowseResponse
import com.comet.browser.data.model.BrowseTaskEntity
import com.comet.browser.data.model.TaskStatus
import com.comet.browser.data.repository.AuthRepository
import com.comet.browser.data.repository.BrowserRepository
import com.comet.browser.domain.model.Resource
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor(
    private val browserRepository: BrowserRepository,
    private val authRepository: AuthRepository
) : ViewModel() {
    
    val allTasks = browserRepository.getAllTasks()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())
    
    private val _browseState = MutableLiveData<Resource<BrowseResponse>>()
    val browseState: LiveData<Resource<BrowseResponse>> = _browseState
    
    private val _logoutState = MutableLiveData<Resource<Unit>>()
    val logoutState: LiveData<Resource<Unit>> = _logoutState
    
    fun browseSynchronous(url: String) {
        viewModelScope.launch {
            _browseState.value = Resource.Loading
            val request = BrowseRequest(
                url = url,
                screenshot = true
            )
            val result = browserRepository.browseSynchronous(request)
            _browseState.value = result
        }
    }
    
    fun browseAsynchronous(url: String) {
        viewModelScope.launch {
            val request = BrowseRequest(
                url = url,
                screenshot = true
            )
            browserRepository.browseAsynchronous(request)
        }
    }
    
    fun refreshTaskStatus(taskId: String) {
        viewModelScope.launch {
            browserRepository.getTaskStatus(taskId)
        }
    }
    
    fun cancelTask(taskId: String) {
        viewModelScope.launch {
            browserRepository.cancelTask(taskId)
        }
    }
    
    fun deleteTask(taskId: String) {
        viewModelScope.launch {
            browserRepository.deleteTask(taskId)
        }
    }
    
    fun syncTasks() {
        viewModelScope.launch {
            browserRepository.syncTasks()
        }
    }
    
    fun logout() {
        viewModelScope.launch {
            _logoutState.value = Resource.Loading
            val result = authRepository.logout()
            _logoutState.value = result
        }
    }
    
    fun getUserEmail(): String? {
        return authRepository.getUserEmail()
    }
}
