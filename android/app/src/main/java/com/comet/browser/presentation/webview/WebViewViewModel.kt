package com.comet.browser.presentation.webview

import androidx.lifecycle.LiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.asLiveData
import com.comet.browser.data.model.BrowseTaskEntity
import com.comet.browser.data.repository.BrowserRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class WebViewViewModel @Inject constructor(
    private val browserRepository: BrowserRepository
) : ViewModel() {
    
    fun getTask(taskId: String): LiveData<BrowseTaskEntity?> {
        return browserRepository.getTaskById(taskId).asLiveData()
    }
}
