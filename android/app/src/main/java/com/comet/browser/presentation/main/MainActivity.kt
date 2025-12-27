package com.comet.browser.presentation.main

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.comet.browser.R
import com.comet.browser.databinding.ActivityMainBinding
import com.comet.browser.domain.model.Resource
import com.comet.browser.presentation.auth.AuthActivity
import com.comet.browser.presentation.task.TaskDetailActivity
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.snackbar.Snackbar
import com.google.android.material.textfield.TextInputEditText
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private val viewModel: MainViewModel by viewModels()
    private lateinit var taskAdapter: TaskListAdapter
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setSupportActionBar(binding.toolbar)
        
        setupRecyclerView()
        setupUI()
        setupObservers()
    }
    
    private fun setupRecyclerView() {
        taskAdapter = TaskListAdapter(
            onTaskClick = { task ->
                val intent = Intent(this, TaskDetailActivity::class.java)
                intent.putExtra("task_id", task.id)
                startActivity(intent)
            },
            onCancelClick = { task ->
                viewModel.cancelTask(task.id)
            },
            onDeleteClick = { task ->
                viewModel.deleteTask(task.id)
            }
        )
        
        binding.rvTasks.apply {
            layoutManager = LinearLayoutManager(this@MainActivity)
            adapter = taskAdapter
        }
    }
    
    private fun setupUI() {
        binding.fabNewTask.setOnClickListener {
            showBrowseDialog()
        }
        
        binding.swipeRefresh.setOnRefreshListener {
            viewModel.syncTasks()
            binding.swipeRefresh.isRefreshing = false
        }
    }
    
    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.allTasks.collect { tasks ->
                taskAdapter.submitList(tasks)
                
                if (tasks.isEmpty()) {
                    binding.tvEmptyState.visibility = View.VISIBLE
                    binding.rvTasks.visibility = View.GONE
                } else {
                    binding.tvEmptyState.visibility = View.GONE
                    binding.rvTasks.visibility = View.VISIBLE
                }
            }
        }
        
        viewModel.browseState.observe(this) { resource ->
            when (resource) {
                is Resource.Loading -> {
                    showLoading(true)
                }
                is Resource.Success -> {
                    showLoading(false)
                    Snackbar.make(binding.root, "Browse completed!", Snackbar.LENGTH_SHORT).show()
                }
                is Resource.Error -> {
                    showLoading(false)
                    showError(resource.message)
                }
            }
        }
        
        viewModel.logoutState.observe(this) { resource ->
            when (resource) {
                is Resource.Success -> {
                    navigateToAuth()
                }
                is Resource.Error -> {
                    showError(resource.message)
                }
                else -> {}
            }
        }
    }
    
    private fun showBrowseDialog() {
        val dialogView = layoutInflater.inflate(R.layout.dialog_browse, null)
        val etUrl = dialogView.findViewById<TextInputEditText>(R.id.et_url)
        
        MaterialAlertDialogBuilder(this)
            .setTitle("Browse URL")
            .setView(dialogView)
            .setPositiveButton("Browse") { _, _ ->
                val url = etUrl.text.toString().trim()
                if (url.isNotEmpty()) {
                    viewModel.browseSynchronous(url)
                }
            }
            .setNeutralButton("Background") { _, _ ->
                val url = etUrl.text.toString().trim()
                if (url.isNotEmpty()) {
                    viewModel.browseAsynchronous(url)
                    Snackbar.make(binding.root, "Task started in background", Snackbar.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }
    
    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.menu_main, menu)
        return true
    }
    
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_sync -> {
                viewModel.syncTasks()
                Snackbar.make(binding.root, "Syncing tasks...", Snackbar.LENGTH_SHORT).show()
                true
            }
            R.id.action_logout -> {
                showLogoutDialog()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
    
    private fun showLogoutDialog() {
        MaterialAlertDialogBuilder(this)
            .setTitle("Logout")
            .setMessage("Are you sure you want to logout?")
            .setPositiveButton("Logout") { _, _ ->
                viewModel.logout()
            }
            .setNegativeButton("Cancel", null)
            .show()
    }
    
    private fun showLoading(show: Boolean) {
        binding.progressBar.visibility = if (show) View.VISIBLE else View.GONE
    }
    
    private fun showError(message: String) {
        Snackbar.make(binding.root, message, Snackbar.LENGTH_LONG).show()
    }
    
    private fun navigateToAuth() {
        val intent = Intent(this, AuthActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}
