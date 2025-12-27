package com.comet.browser.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.comet.browser.data.model.BrowseTaskEntity

@Database(
    entities = [BrowseTaskEntity::class],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class CometDatabase : RoomDatabase() {
    abstract fun browseTaskDao(): BrowseTaskDao
    
    companion object {
        const val DATABASE_NAME = "comet_browser.db"
    }
}
