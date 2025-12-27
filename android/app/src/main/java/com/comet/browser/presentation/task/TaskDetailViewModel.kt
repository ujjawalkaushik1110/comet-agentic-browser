package com.comet.browser.presentation.task

import androidx.lifecycle.LiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.asLiveData
import androidx.lifecycle.viewModelScope
import com.comet.browser.data.model.BrowseTaskEntity
import com.comet.browser.data.repository.BrowserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class TaskDetailViewModel @Inject constructor(
    private val browserRepository: BrowserRepository
) : ViewModel() {
    
    private var currentTaskId: String? = null
    
    fun getTask(taskId: String): LiveData<BrowseTaskEntity?> {
        currentTaskId = taskId
        return browserRepository.getTaskById(taskId).asLiveData()
    }
    
    fun refreshStatus() {
        currentTaskId?.let { taskId ->
            viewModelScope.launch {
                browserRepository.getTaskStatus(taskId)
            }
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
}
