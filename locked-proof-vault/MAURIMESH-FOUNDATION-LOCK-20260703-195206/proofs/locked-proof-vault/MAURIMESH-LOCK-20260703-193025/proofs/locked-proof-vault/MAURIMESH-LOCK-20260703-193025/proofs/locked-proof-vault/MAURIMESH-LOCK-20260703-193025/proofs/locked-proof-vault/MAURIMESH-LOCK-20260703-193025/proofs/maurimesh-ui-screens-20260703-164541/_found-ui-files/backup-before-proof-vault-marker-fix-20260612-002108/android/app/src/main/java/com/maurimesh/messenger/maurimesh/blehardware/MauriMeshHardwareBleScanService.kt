package com.maurimesh.messenger.maurimesh.blehardware

import android.Manifest
import android.app.*
import android.bluetooth.BluetoothManager
import android.bluetooth.le.*
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class MauriMeshHardwareBleScanService : Service() {

  companion object {
    const val ACTION_START = "com.maurimesh.messenger.MAURIMESH_HARDWARE_BLE_START"
    const val ACTION_STOP = "com.maurimesh.messenger.MAURIMESH_HARDWARE_BLE_STOP"
    const val CHANNEL_ID = "maurimesh_ble_hardware_scan"
    const val NOTIFICATION_ID = 7001

    @Volatile var isRunning: Boolean = false
    @Volatile var discoveredCount: Int = 0
    @Volatile var lastDeviceName: String? = null
    @Volatile var lastDeviceAddress: String? = null
    @Volatile var lastRssi: Int = 0
  }

  private var scanner: BluetoothLeScanner? = null

  private val callback = object : ScanCallback() {
    override fun onScanResult(callbackType: Int, result: ScanResult) {
      discoveredCount += 1
      lastRssi = result.rssi

      try {
        if (Build.VERSION.SDK_INT < 31 || hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
          lastDeviceName = result.device?.name ?: "unknown"
          lastDeviceAddress = result.device?.address ?: "unknown"
        } else {
          lastDeviceName = "permission_required"
          lastDeviceAddress = "permission_required"
        }
      } catch (_: SecurityException) {
        lastDeviceName = "security_exception"
        lastDeviceAddress = "security_exception"
      }

      Log.i(
        "MauriMeshHardwareBle",
        "MAURIMESH_NATIVE_BLE_SCAN_RESULT count=$discoveredCount rssi=$lastRssi name=$lastDeviceName address=$lastDeviceAddress"
      )
    }

    override fun onBatchScanResults(results: MutableList<ScanResult>) {
      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_BATCH_RESULTS size=${results.size}")
      results.forEach { onScanResult(ScanSettings.CALLBACK_TYPE_ALL_MATCHES, it) }
    }

    override fun onScanFailed(errorCode: Int) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_FAILED errorCode=$errorCode")
    }
  }

  override fun onCreate() {
    super.onCreate()
    createNotificationChannel()
    Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SERVICE_CREATED")
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    when (intent?.action) {
      ACTION_STOP -> {
        stopBleScan()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        return START_NOT_STICKY
      }
      else -> {
        startForeground(NOTIFICATION_ID, buildNotification("MauriMesh BLE hardware scan running"))
        startBleScan()
        return START_STICKY
      }
    }
  }

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onDestroy() {
    stopBleScan()
    Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SERVICE_DESTROYED")
    super.onDestroy()
  }

  private fun startBleScan() {
    try {
      if (isRunning) {
        Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_ALREADY_RUNNING")
        return
      }

      if (Build.VERSION.SDK_INT >= 31 && !hasPermission(Manifest.permission.BLUETOOTH_SCAN)) {
        Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_BLOCKED_MISSING_BLUETOOTH_SCAN")
        return
      }

      val manager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
      val adapter = manager?.adapter

      if (adapter == null || !adapter.isEnabled) {
        Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_BLOCKED_ADAPTER_OFF_OR_MISSING")
        return
      }

      scanner = adapter.bluetoothLeScanner

      val settings = ScanSettings.Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .setReportDelay(0)
        .build()

      scanner?.startScan(null, settings, callback)
      isRunning = true

      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_STARTED")
    } catch (se: SecurityException) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_SECURITY_EXCEPTION ${se.message}", se)
    } catch (e: Exception) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_START_ERROR ${e.message}", e)
    }
  }

  private fun stopBleScan() {
    try {
      if (scanner != null) {
        if (Build.VERSION.SDK_INT < 31 || hasPermission(Manifest.permission.BLUETOOTH_SCAN)) {
          scanner?.stopScan(callback)
        }
      }
    } catch (e: Exception) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_STOP_ERROR ${e.message}", e)
    } finally {
      isRunning = false
      scanner = null
      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_BLE_SCAN_STOPPED")
    }
  }

  private fun hasPermission(permission: String): Boolean {
    return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
  }

  private fun createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= 26) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        "MauriMesh BLE Hardware Scan",
        NotificationManager.IMPORTANCE_LOW
      )
      channel.description = "MauriMesh foreground Bluetooth hardware scan proof"
      val manager = getSystemService(NotificationManager::class.java)
      manager.createNotificationChannel(channel)
    }
  }

  private fun buildNotification(text: String): Notification {
    val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
    val pendingIntent = PendingIntent.getActivity(
      this,
      0,
      launchIntent,
      PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    )

    return NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("MauriMesh hardware BLE proof")
      .setContentText(text)
      .setSmallIcon(android.R.drawable.stat_sys_data_bluetooth)
      .setOngoing(true)
      .setContentIntent(pendingIntent)
      .build()
  }
}
