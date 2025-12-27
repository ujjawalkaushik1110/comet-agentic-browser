package com.comet.browser.presentation.task

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.comet.browser.R
import com.comet.browser.data.model.TaskStatus
import com.comet.browser.databinding.ActivityTaskDetailBinding
import com.comet.browser.presentation.webview.WebViewActivity
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.snackbar.Snackbar
import dagger.hilt.android.AndroidEntryPoint
import java.text.SimpleDateFormat
import java.util.*

@AndroidEntryPoint
class TaskDetailActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityTaskDetailBinding
    private val viewModel: TaskDetailViewModel by viewModels()
    private val dateFormat = SimpleDateFormat("MMM dd, yyyy HH:mm:ss", Locale.getDefault())
    private var currentTaskId: String? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityTaskDetailBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        
        currentTaskId = intent.getStringExtra("task_id")
        if (currentTaskId == null) {
            finish()
            return
        }
        
        setupUI()
        setupObservers()
    }
    
    private fun setupUI() {
        binding.btnRefresh.setOnClickListener {
            viewModel.refreshStatus()
        }
        
        binding.btnViewInBrowser.setOnClickListener {
            currentTaskId?.let { taskId ->
                val intent = Intent(this, WebViewActivity::class.java)
                intent.putExtra("task_id", taskId)
                startActivity(intent)
            }
        }
    }
    
    private fun setupObservers() {
        currentTaskId?.let { taskId ->
            viewModel.getTask(taskId).observe(this) { task ->
                if (task == null) {
                    finish()
                    return@observe
                }
                
                binding.apply {
                    tvUrl.text = task.url
                    tvTitle.text = task.title ?: "No title"
                    tvStatus.text = task.status.name
                    tvCreated.text = "Created: ${dateFormat.format(task.createdAt)}"
                    tvUpdated.text = "Updated: ${dateFormat.format(task.updatedAt)}"
                    
                    if (task.completedAt != null) {
                        tvCompleted.visibility = View.VISIBLE
                        tvCompleted.text = "Completed: ${dateFormat.format(task.completedAt)}"
                    } else {
                        tvCompleted.visibility = View.GONE
                    }
                    
                    // Set status color
                    val statusColor = when (task.status) {
                        TaskStatus.COMPLETED -> R.color.status_completed
                        TaskStatus.IN_PROGRESS -> R.color.status_in_progress
                        TaskStatus.FAILED -> R.color.status_failed
                        TaskStatus.CANCELLED -> R.color.status_cancelled
                        TaskStatus.PENDING -> R.color.status_pending
                    }
                    tvStatus.setTextColor(ContextCompat.getColor(this@TaskDetailActivity, statusColor))
                    
                    // Content
                    if (task.content != null) {
                        tvContent.visibility = View.VISIBLE
                        tvContent.text = task.content
                    } else {
                        tvContent.visibility = View.GONE
                    }
                    
                    // Error message
                    if (task.errorMessage != null) {
                        tvError.visibility = View.VISIBLE
                        tvError.text = "Error: ${task.errorMessage}"
                    } else {
                        tvError.visibility = View.GONE
                    }
                    
                    // Enable/disable buttons
                    btnRefresh.isEnabled = task.status == TaskStatus.PENDING || task.status == TaskStatus.IN_PROGRESS
                    btnViewInBrowser.isEnabled = task.status == TaskStatus.COMPLETED
                }
            }
        }
    }
    
    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_task_detail, menu)
        return true
    }
    
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                onBackPressedDispatcher.onBackPressed()
                true
            }
            R.id.action_cancel -> {
                showCancelDialog()
                true
            }
            R.id.action_delete -> {
                showDeleteDialog()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
    
    private fun showCancelDialog() {
        MaterialAlertDialogBuilder(this)
            .setTitle("Cancel Task")
            .setMessage("Are you sure you want to cancel this task?")
            .setPositiveButton("Cancel Task") { _, _ ->
                currentTaskId?.let { taskId ->
                    viewModel.cancelTask(taskId)
                    Snackbar.make(binding.root, "Task cancelled", Snackbar.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Back", null)
            .show()
    }
    
    private fun showDeleteDialog() {
        MaterialAlertDialogBuilder(this)
            .setTitle("Delete Task")
            .setMessage("Are you sure you want to delete this task?")
            .setPositiveButton("Delete") { _, _ ->
                currentTaskId?.let { taskId ->
                    viewModel.deleteTask(taskId)
                    Snackbar.make(binding.root, "Task deleted", Snackbar.LENGTH_SHORT).show()
                    finish()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }
}
