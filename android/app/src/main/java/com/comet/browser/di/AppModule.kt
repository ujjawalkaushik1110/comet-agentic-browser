package com.comet.browser.di

import android.content.Context
import com.comet.browser.utils.NetworkUtils
import com.comet.browser.utils.SessionManager
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    
    @Provides
    @Singleton
    fun provideSessionManager(
        @ApplicationContext context: Context
    ): SessionManager {
        return SessionManager(context)
    }
    
    @Provides
    @Singleton
    fun provideNetworkUtils(
        @ApplicationContext context: Context
    ): NetworkUtils {
        return NetworkUtils(context)
    }
}
