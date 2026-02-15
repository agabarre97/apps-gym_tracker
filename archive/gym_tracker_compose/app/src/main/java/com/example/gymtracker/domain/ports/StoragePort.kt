package com.example.gymtracker.domain.ports

/**
 * Port (interface) for local storage - domain layer defines the contract.
 */
interface StoragePort {
    suspend fun get(key: String): String?
    suspend fun set(key: String, value: String)
    suspend fun remove(key: String)
}
