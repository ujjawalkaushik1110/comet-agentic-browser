package com.comet.browser.presentation.main

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.core.content.ContextCompat
import androidx.recyclerview.view.RecyclerView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import com.comet.browser.R
import com.comet.browser.data.model.BrowseTaskEntity
import com.comet.browser.data.model.TaskStatus
import com.comet.browser.databinding.ItemTaskBinding
import java.text.SimpleDateFormat
import java.util.*

class TaskListAdapter(
    private val onTaskClick: (BrowseTaskEntity) -> Unit,
    private val onCancelClick: (BrowseTaskEntity) -> Unit,
    private val onDeleteClick: (BrowseTaskEntity) -> Unit
) : ListAdapter<BrowseTaskEntity, TaskListAdapter.TaskViewHolder>(TaskDiffCallback()) {
    
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): TaskViewHolder {
        val binding = ItemTaskBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return TaskViewHolder(binding)
    }
    
    override fun onBindViewHolder(holder: TaskViewHolder, position: Int) {
        holder.bind(getItem(position))
    }
    
    inner class TaskViewHolder(
        private val binding: ItemTaskBinding
    ) : RecyclerView.ViewHolder(binding.root) {
        
        private val dateFormat = SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault())
        
        fun bind(task: BrowseTaskEntity) {
            binding.apply {
                tvUrl.text = task.url
                tvTitle.text = task.title ?: "No title"
                tvDate.text = dateFormat.format(task.createdAt)
                tvStatus.text = task.status.name
                
                // Set status color
                val statusColor = when (task.status) {
                    TaskStatus.COMPLETED -> R.color.status_completed
                    TaskStatus.IN_PROGRESS -> R.color.status_in_progress
                    TaskStatus.FAILED -> R.color.status_failed
                    TaskStatus.CANCELLED -> R.color.status_cancelled
                    TaskStatus.PENDING -> R.color.status_pending
                }
                tvStatus.setTextColor(ContextCompat.getColor(root.context, statusColor))
                
                // Click listeners
                root.setOnClickListener { onTaskClick(task) }
                
                btnCancel.setOnClickListener { onCancelClick(task) }
                btnCancel.isEnabled = task.status == TaskStatus.PENDING || task.status == TaskStatus.IN_PROGRESS
                
                btnDelete.setOnClickListener { onDeleteClick(task) }
            }
        }
    }
    
    class TaskDiffCallback : DiffUtil.ItemCallback<BrowseTaskEntity>() {
        override fun areItemsTheSame(oldItem: BrowseTaskEntity, newItem: BrowseTaskEntity): Boolean {
            return oldItem.id == newItem.id
        }
        
        override fun areContentsTheSame(oldItem: BrowseTaskEntity, newItem: BrowseTaskEntity): Boolean {
            return oldItem == newItem
        }
    }
}
