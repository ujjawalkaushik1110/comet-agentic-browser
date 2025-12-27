package com.comet.browser.utils

import kotlinx.coroutines.delay
import timber.log.Timber
import kotlin.math.pow

object RetryPolicy {
    
    suspend fun <T> retryWithExponentialBackoff(
        maxRetries: Int = 3,
        initialDelayMs: Long = 1000,
        maxDelayMs: Long = 10000,
        factor: Double = 2.0,
        onRetry: ((attempt: Int, exception: Exception) -> Unit)? = null,
        block: suspend () -> T
    ): T {
        var currentDelay = initialDelayMs
        var attempt = 0
        
        while (true) {
            try {
                return block()
            } catch (e: Exception) {
                attempt++
                
                if (attempt >= maxRetries) {
                    Timber.e(e, "Max retries ($maxRetries) exceeded")
                    throw e
                }
                
                Timber.w(e, "Retry attempt $attempt/$maxRetries after ${currentDelay}ms")
                onRetry?.invoke(attempt, e)
                
                delay(currentDelay)
                currentDelay = (currentDelay * factor).toLong().coerceAtMost(maxDelayMs)
            }
        }
    }
    
    suspend fun <T> retryWithLinearBackoff(
        maxRetries: Int = 3,
        delayMs: Long = 1000,
        onRetry: ((attempt: Int, exception: Exception) -> Unit)? = null,
        block: suspend () -> T
    ): T {
        var attempt = 0
        
        while (true) {
            try {
                return block()
            } catch (e: Exception) {
                attempt++
                
                if (attempt >= maxRetries) {
                    Timber.e(e, "Max retries ($maxRetries) exceeded")
                    throw e
                }
                
                Timber.w(e, "Retry attempt $attempt/$maxRetries after ${delayMs * attempt}ms")
                onRetry?.invoke(attempt, e)
                
                delay(delayMs * attempt)
            }
        }
    }
    
    fun shouldRetry(exception: Exception): Boolean {
        return when (exception) {
            is java.net.SocketTimeoutException -> true
            is java.net.UnknownHostException -> true
            is java.io.IOException -> true
            is retrofit2.HttpException -> {
                // Retry on server errors (5xx) but not client errors (4xx)
                exception.code() >= 500
            }
            else -> false
        }
    }
}
