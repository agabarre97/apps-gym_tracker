package com.example.gymtracker.data.datasource

import android.content.Context
import com.example.gymtracker.domain.ports.StoragePort
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Adapter implementing [StoragePort] using SharedPreferences.
 */
class LocalStorageDatasource(
    private val context: Context
) : StoragePort {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    override suspend fun get(key: String): String? = withContext(Dispatchers.IO) {
        prefs.getString(key, null)
    }

    override suspend fun set(key: String, value: String) = withContext(Dispatchers.IO) {
        prefs.edit().putString(key, value).apply()
    }

    override suspend fun remove(key: String) = withContext(Dispatchers.IO) {
        prefs.edit().remove(key).apply()
    }

    companion object {
        private const val PREFS_NAME = "gym_tracker_prefs"
    }
}
