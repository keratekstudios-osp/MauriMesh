package com.maurimesh.messenger

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MauriMeshForegroundService : Service() {
  companion object {
    const val CHANNEL_ID = "maurimesh_mesh_active"
    const val NOTIFICATION_ID = 182
    const val ACTION_START = "com.maurimesh.messenger.START_MESH_FOREGROUND"
    const val ACTION_STOP = "com.maurimesh.messenger.STOP_MESH_FOREGROUND"
    const val MARKER = "TASK_182_MAURIMESH_FOREGROUND_SERVICE_20260608_A"
  }

  private val handler = Handler(Looper.getMainLooper())
  private var startedAtMs: Long = 0L

  private val heartbeatRunnable = object : Runnable {
    override fun run() {
      writeHeartbeat()
      handler.postDelayed(this, 120_000L)
    }
  }

  override fun onCreate() {
    super.onCreate()
    startedAtMs = System.currentTimeMillis()
    createNotificationChannel()
    Log.i("MauriMeshForeground", "onCreate marker=$MARKER")
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    if (intent?.action == ACTION_STOP) {
      stopForegroundService()
      return START_NOT_STICKY
    }

    startForeground(NOTIFICATION_ID, buildNotification())
    writeHeartbeat()
    handler.removeCallbacks(heartbeatRunnable)
    handler.postDelayed(heartbeatRunnable, 120_000L)

    Log.i("MauriMeshForeground", "START_STICKY active marker=$MARKER")
    return START_STICKY
  }

  override fun onDestroy() {
    handler.removeCallbacks(heartbeatRunnable)
    writeHeartbeat("destroyed")
    Log.w("MauriMeshForeground", "onDestroy marker=$MARKER")
    super.onDestroy()
  }

  override fun onBind(intent: Intent?): IBinder? = null

  private fun stopForegroundService() {
    handler.removeCallbacks(heartbeatRunnable)
    writeHeartbeat("stopped")
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      stopForeground(STOP_FOREGROUND_REMOVE)
    } else {
      @Suppress("DEPRECATION")
      stopForeground(true)
    }
    stopSelf()
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        "MauriMesh Mesh Runtime",
        NotificationManager.IMPORTANCE_LOW
      )
      channel.description = "Keeps MauriMesh peer discovery and mesh runtime alive."
      val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
      manager.createNotificationChannel(channel)
    }
  }

  private fun buildNotification(): Notification {
    return NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("MauriMesh Mesh Active")
      .setContentText("Offline mesh runtime is protected while the screen is locked.")
      .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
      .setOngoing(true)
      .setOnlyAlertOnce(true)
      .setPriority(NotificationCompat.PRIORITY_LOW)
      .setCategory(NotificationCompat.CATEGORY_SERVICE)
      .build()
  }

  private fun writeHeartbeat(state: String = "active") {
    try {
      val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(Date())
      val uptimeMs = System.currentTimeMillis() - startedAtMs

      val json = """{
        "marker":"$MARKER",
        "subsystem":"background-runtime",
        "severity":"info",
        "code":"FOREGROUND_SERVICE_HEARTBEAT",
        "message":"MauriMesh foreground service heartbeat",
        "state":"$state",
        "createdAt":"$timestamp",
        "uptimeMs":$uptimeMs
      }""".trimIndent()

      val dir = File(filesDir, "maurimesh-runtime-ledger")
      if (!dir.exists()) dir.mkdirs()

      File(dir, "foreground-service-heartbeat.json").writeText(json)
      File(dir, "foreground-service-heartbeat.log").appendText(json + "\n")

      Log.i("MauriMeshForeground", json)
    } catch (error: Throwable) {
      Log.e("MauriMeshForeground", "heartbeat write failed", error)
    }
  }
}
