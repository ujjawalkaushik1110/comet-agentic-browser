package com.comet.browser.di

import android.content.Context
import androidx.room.Room
import com.comet.browser.data.local.BrowseTaskDao
import com.comet.browser.data.local.CometDatabase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {
    
    @Provides
    @Singleton
    fun provideDatabase(
        @ApplicationContext context: Context
    ): CometDatabase {
        return Room.databaseBuilder(
            context,
            CometDatabase::class.java,
            CometDatabase.DATABASE_NAME
        )
            .fallbackToDestructiveMigration()
            .build()
    }
    
    @Provides
    @Singleton
    fun provideBrowseTaskDao(database: CometDatabase): BrowseTaskDao {
        return database.browseTaskDao()
    }
}
