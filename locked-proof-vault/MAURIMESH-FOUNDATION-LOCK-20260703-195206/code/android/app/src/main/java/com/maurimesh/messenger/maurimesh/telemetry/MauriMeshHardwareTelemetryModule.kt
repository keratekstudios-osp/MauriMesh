package com.maurimesh.messenger.maurimesh.telemetry

import android.app.ActivityManager
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.os.StatFs
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.WritableMap
import com.facebook.react.bridge.Arguments

class MauriMeshHardwareTelemetryModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String {
    return "MauriMeshHardwareTelemetry"
  }

  @ReactMethod
  fun getHardwareTelemetry(promise: Promise) {
    try {
      val map = Arguments.createMap()

      val battery = readBattery()
      val memory = readMemory()
      val storage = readStorage()
      val thermalRisk = readThermalRisk()
      val ble = readBleState()

      map.putString("source", "NATIVE_ANDROID")
      map.putString("platform", "android")

      map.putDouble("batteryPercent", battery.percent.toDouble())
      map.putBoolean("isCharging", battery.isCharging)

      map.putDouble("memoryUsedMb", memory.usedMb.toDouble())
      map.putDouble("memoryTotalMb", memory.totalMb.toDouble())
      map.putString("memoryPressure", pressureFromMemory(memory.usedMb, memory.totalMb))

      map.putDouble("storageFreeMb", storage.freeMb.toDouble())
      map.putDouble("storageTotalMb", storage.totalMb.toDouble())
      map.putString("storagePressure", pressureFromStorage(storage.freeMb, storage.totalMb))

      map.putString("thermalRisk", thermalRisk)

      map.putBoolean("bleAvailable", ble.available)
      map.putBoolean("bleEnabled", ble.enabled)
      map.putString("blePressure", if (ble.available && ble.enabled) "low" else "medium")

      map.putString("appCrashRisk", "low")
      map.putBoolean("foreground", true)
      map.putDouble("timestamp", System.currentTimeMillis().toDouble())

      promise.resolve(map)
    } catch (error: Exception) {
      promise.reject("MAURIMESH_TELEMETRY_ERROR", error.message, error)
    }
  }

  private data class BatteryState(
    val percent: Int,
    val isCharging: Boolean
  )

  private data class MemoryState(
    val usedMb: Long,
    val totalMb: Long
  )

  private data class StorageState(
    val freeMb: Long,
    val totalMb: Long
  )

  private data class BleState(
    val available: Boolean,
    val enabled: Boolean
  )

  private fun readBattery(): BatteryState {
    val intent = reactContext.registerReceiver(
      null,
      IntentFilter(Intent.ACTION_BATTERY_CHANGED)
    )

    val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
    val scale = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1

    val percent =
      if (level >= 0 && scale > 0) ((level.toFloat() / scale.toFloat()) * 100).toInt()
      else 50

    val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1

    val charging =
      status == BatteryManager.BATTERY_STATUS_CHARGING ||
        status == BatteryManager.BATTERY_STATUS_FULL

    return BatteryState(percent.coerceIn(0, 100), charging)
  }

  private fun readMemory(): MemoryState {
    val activityManager =
      reactContext.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager

    val info = ActivityManager.MemoryInfo()
    activityManager.getMemoryInfo(info)

    val totalMb = bytesToMb(info.totalMem)
    val availMb = bytesToMb(info.availMem)
    val usedMb = (totalMb - availMb).coerceAtLeast(0)

    return MemoryState(usedMb, totalMb.coerceAtLeast(1))
  }

  private fun readStorage(): StorageState {
    val path = Environment.getDataDirectory()
    val stat = StatFs(path.path)

    val blockSize = stat.blockSizeLong
    val totalBlocks = stat.blockCountLong
    val freeBlocks = stat.availableBlocksLong

    val totalMb = bytesToMb(totalBlocks * blockSize).coerceAtLeast(1)
    val freeMb = bytesToMb(freeBlocks * blockSize).coerceAtLeast(0)

    return StorageState(freeMb, totalMb)
  }

  private fun readThermalRisk(): String {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
      return "medium"
    }

    return try {
      val powerManager =
        reactContext.getSystemService(Context.POWER_SERVICE) as PowerManager

      when (powerManager.currentThermalStatus) {
        PowerManager.THERMAL_STATUS_NONE -> "low"
        PowerManager.THERMAL_STATUS_LIGHT -> "low"
        PowerManager.THERMAL_STATUS_MODERATE -> "medium"
        PowerManager.THERMAL_STATUS_SEVERE -> "high"
        PowerManager.THERMAL_STATUS_CRITICAL -> "critical"
        PowerManager.THERMAL_STATUS_EMERGENCY -> "critical"
        PowerManager.THERMAL_STATUS_SHUTDOWN -> "critical"
        else -> "medium"
      }
    } catch (_: Exception) {
      "medium"
    }
  }

  private fun readBleState(): BleState {
    return try {
      val manager =
        reactContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

      val adapter: BluetoothAdapter? = manager.adapter

      BleState(
        available = adapter != null,
        enabled = adapter?.isEnabled == true
      )
    } catch (_: Exception) {
      BleState(available = false, enabled = false)
    }
  }

  private fun pressureFromMemory(usedMb: Long, totalMb: Long): String {
    if (totalMb <= 0) return "medium"

    val ratio = usedMb.toDouble() / totalMb.toDouble()

    return when {
      ratio >= 0.94 -> "critical"
      ratio >= 0.84 -> "high"
      ratio >= 0.68 -> "medium"
      else -> "low"
    }
  }

  private fun pressureFromStorage(freeMb: Long, totalMb: Long): String {
    if (totalMb <= 0) return "medium"

    val ratio = freeMb.toDouble() / totalMb.toDouble()

    return when {
      ratio <= 0.04 -> "critical"
      ratio <= 0.10 -> "high"
      ratio <= 0.22 -> "medium"
      else -> "low"
    }
  }

  private fun bytesToMb(value: Long): Long {
    return value / 1024L / 1024L
  }
}
