package com.comet.browser.data.local

import androidx.room.TypeConverter
import com.comet.browser.data.model.BrowserAction
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import java.util.Date

class Converters {
    private val gson = Gson()

    @TypeConverter
    fun fromTimestamp(value: Long?): Date? {
        return value?.let { Date(it) }
    }

    @TypeConverter
    fun dateToTimestamp(date: Date?): Long? {
        return date?.time
    }

    @TypeConverter
    fun fromActionList(actions: List<BrowserAction>?): String? {
        return actions?.let { gson.toJson(it) }
    }

    @TypeConverter
    fun toActionList(actionsString: String?): List<BrowserAction>? {
        if (actionsString == null) return null
        val type = object : TypeToken<List<BrowserAction>>() {}.type
        return gson.fromJson(actionsString, type)
    }
}
