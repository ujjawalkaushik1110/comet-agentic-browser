package com.comet.browser.presentation.auth

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import com.comet.browser.R
import com.comet.browser.databinding.ActivityAuthBinding
import com.comet.browser.domain.model.Resource
import com.comet.browser.presentation.main.MainActivity
import com.google.android.material.snackbar.Snackbar
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class AuthActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityAuthBinding
    private val viewModel: AuthViewModel by viewModels()
    private var isLoginMode = true
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAuthBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupUI()
        setupObservers()
    }
    
    private fun setupUI() {
        binding.btnLogin.setOnClickListener {
            if (isLoginMode) {
                performLogin()
            } else {
                performRegister()
            }
        }
        
        binding.tvToggleMode.setOnClickListener {
            toggleMode()
        }
    }
    
    private fun setupObservers() {
        viewModel.authState.observe(this) { resource ->
            when (resource) {
                is Resource.Loading -> {
                    showLoading(true)
                }
                is Resource.Success -> {
                    showLoading(false)
                    navigateToMain()
                }
                is Resource.Error -> {
                    showLoading(false)
                    showError(resource.message)
                }
            }
        }
    }
    
    private fun performLogin() {
        val email = binding.etEmail.text.toString().trim()
        val password = binding.etPassword.text.toString()
        
        if (!validateInputs(email, password)) {
            return
        }
        
        viewModel.login(email, password)
    }
    
    private fun performRegister() {
        val email = binding.etEmail.text.toString().trim()
        val password = binding.etPassword.text.toString()
        
        if (!validateInputs(email, password)) {
            return
        }
        
        viewModel.register(email, password)
    }
    
    private fun validateInputs(email: String, password: String): Boolean {
        if (email.isEmpty()) {
            binding.tilEmail.error = "Email is required"
            return false
        }
        
        if (!viewModel.validateEmail(email)) {
            binding.tilEmail.error = "Invalid email format"
            return false
        }
        
        binding.tilEmail.error = null
        
        if (password.isEmpty()) {
            binding.tilPassword.error = "Password is required"
            return false
        }
        
        if (!viewModel.validatePassword(password)) {
            binding.tilPassword.error = "Password must be at least 8 characters"
            return false
        }
        
        binding.tilPassword.error = null
        
        return true
    }
    
    private fun toggleMode() {
        isLoginMode = !isLoginMode
        
        if (isLoginMode) {
            binding.btnLogin.text = "Login"
            binding.tvToggleMode.text = "Don't have an account? Register"
        } else {
            binding.btnLogin.text = "Register"
            binding.tvToggleMode.text = "Already have an account? Login"
        }
    }
    
    private fun showLoading(show: Boolean) {
        binding.progressBar.visibility = if (show) View.VISIBLE else View.GONE
        binding.btnLogin.isEnabled = !show
        binding.etEmail.isEnabled = !show
        binding.etPassword.isEnabled = !show
    }
    
    private fun showError(message: String) {
        Snackbar.make(binding.root, message, Snackbar.LENGTH_LONG).show()
    }
    
    private fun navigateToMain() {
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        startActivity(intent)
        finish()
    }
}
