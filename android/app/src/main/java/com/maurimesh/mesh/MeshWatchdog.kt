package com.maurimesh.mesh

import android.util.Log

class MeshWatchdog(
    private val engine: MeshEngine
) {
    fun check(): Boolean {
        val snapshot = engine.snapshot()

        Log.i(TAG, "watchdog snapshot=$snapshot")

        if (!snapshot.bootstrapped) {
            Log.w(TAG, "engine not bootstrapped; bootstrapping")
            engine.bootstrap()
            return false
        }

        if (!snapshot.running) {
            Log.w(TAG, "engine not running; starting mesh")
            engine.startMesh()
            return false
        }

        return true
    }

    fun forceRestart(reason: String = "manual") {
        Log.w(TAG, "force restart reason=$reason")
        engine.restartMesh()
    }

    companion object {
        private const val TAG = "MauriMeshWatchdog"
    }
}
