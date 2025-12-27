package com.comet.browser.utils

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "comet_prefs")

@Singleton
class SessionManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    private object PreferencesKeys {
        val AUTH_TOKEN = stringPreferencesKey("auth_token")
        val USER_ID = stringPreferencesKey("user_id")
        val USER_EMAIL = stringPreferencesKey("user_email")
        val API_BASE_URL = stringPreferencesKey("api_base_url")
    }
    
    suspend fun saveAuthToken(token: String) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.AUTH_TOKEN] = token
        }
    }
    
    fun getAuthToken(): String? {
        return runBlocking {
            context.dataStore.data.map { preferences ->
                preferences[PreferencesKeys.AUTH_TOKEN]
            }.first()
        }
    }
    
    suspend fun saveUserId(userId: String) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.USER_ID] = userId
        }
    }
    
    fun getUserId(): String? {
        return runBlocking {
            context.dataStore.data.map { preferences ->
                preferences[PreferencesKeys.USER_ID]
            }.first()
        }
    }
    
    suspend fun saveUserEmail(email: String) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.USER_EMAIL] = email
        }
    }
    
    fun getUserEmail(): String? {
        return runBlocking {
            context.dataStore.data.map { preferences ->
                preferences[PreferencesKeys.USER_EMAIL]
            }.first()
        }
    }
    
    suspend fun saveApiBaseUrl(url: String) {
        context.dataStore.edit { preferences ->
            preferences[PreferencesKeys.API_BASE_URL] = url
        }
    }
    
    fun getApiBaseUrl(): String? {
        return runBlocking {
            context.dataStore.data.map { preferences ->
                preferences[PreferencesKeys.API_BASE_URL]
            }.first()
        }
    }
    
    suspend fun clearSession() {
        context.dataStore.edit { preferences ->
            preferences.clear()
        }
    }
    
    fun isLoggedIn(): Boolean {
        return getAuthToken() != null
    }
}
