package com.maurimesh.mesh

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log

class MeshForegroundService : Service() {
    private lateinit var engine: MeshEngine
    private lateinit var watchdog: MeshWatchdog

    override fun onCreate() {
        super.onCreate()

        engine = MeshEngine(this) { event ->
            Log.i(TAG, "event=${event.type} message=${event.message}")
        }

        watchdog = MeshWatchdog(engine)
        engine.bootstrap()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createChannel()

        startForeground(
            NOTIFICATION_ID,
            buildNotification("MauriMesh runtime active")
        )

        when (intent?.action) {
            ACTION_STOP -> {
                engine.stopMesh()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }

            ACTION_RESTART -> {
                engine.restartMesh()
                watchdog.check()
            }

            ACTION_SNAPSHOT -> {
                val snapshot = engine.snapshot()
                Log.i(TAG, "snapshot=$snapshot")
            }

            else -> {
                engine.startMesh()
                watchdog.check()
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        try {
            engine.stopMesh()
        } catch (t: Throwable) {
            Log.w(TAG, "stopMesh failed during destroy", t)
        }

        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            val channel = NotificationChannel(
                CHANNEL_ID,
                "MauriMesh Runtime",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps the MauriMesh mesh runtime alive"
            }

            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("MauriMesh")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val TAG = "MauriMeshForeground"
        private const val CHANNEL_ID = "maurimesh_runtime"
        private const val NOTIFICATION_ID = 7041

        const val ACTION_START = "com.maurimesh.mesh.START"
        const val ACTION_STOP = "com.maurimesh.mesh.STOP"
        const val ACTION_RESTART = "com.maurimesh.mesh.RESTART"
        const val ACTION_SNAPSHOT = "com.maurimesh.mesh.SNAPSHOT"
    }
}
