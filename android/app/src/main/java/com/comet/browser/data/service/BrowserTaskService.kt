package com.comet.browser.data.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.comet.browser.R
import com.comet.browser.data.repository.BrowserRepository
import com.comet.browser.presentation.main.MainActivity
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.*
import timber.log.Timber
import javax.inject.Inject

@AndroidEntryPoint
class BrowserTaskService : Service() {
    
    @Inject
    lateinit var browserRepository: BrowserRepository
    
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var syncJob: Job? = null
    
    companion object {
        const val CHANNEL_ID = "browser_task_channel"
        const val NOTIFICATION_ID = 1001
        const val SYNC_INTERVAL = 60000L // 1 minute
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Timber.d("BrowserTaskService created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())
        startSyncLoop()
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        syncJob?.cancel()
        serviceScope.cancel()
        Timber.d("BrowserTaskService destroyed")
    }
    
    private fun startSyncLoop() {
        syncJob?.cancel()
        syncJob = serviceScope.launch {
            while (isActive) {
                try {
                    Timber.d("Syncing tasks...")
                    browserRepository.syncTasks()
                } catch (e: Exception) {
                    Timber.e(e, "Error syncing tasks")
                }
                delay(SYNC_INTERVAL)
            }
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Browser Tasks",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background sync for browser tasks"
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Comet Browser")
            .setContentText("Syncing browser tasks...")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
}
