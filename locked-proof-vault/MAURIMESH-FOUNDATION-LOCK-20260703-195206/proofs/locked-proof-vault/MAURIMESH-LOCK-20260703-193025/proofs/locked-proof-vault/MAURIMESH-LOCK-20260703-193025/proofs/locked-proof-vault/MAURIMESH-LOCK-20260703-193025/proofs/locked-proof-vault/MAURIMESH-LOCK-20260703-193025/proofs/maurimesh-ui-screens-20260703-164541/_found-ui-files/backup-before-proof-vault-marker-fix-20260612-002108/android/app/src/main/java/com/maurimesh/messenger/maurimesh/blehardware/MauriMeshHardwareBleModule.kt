package com.maurimesh.messenger.maurimesh.blehardware

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import com.facebook.react.bridge.*

class MauriMeshHardwareBleModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String = "MauriMeshHardwareBle"

  private fun hasPermission(permission: String): Boolean {
    return ContextCompat.checkSelfPermission(
      reactContext,
      permission
    ) == PackageManager.PERMISSION_GRANTED
  }

  private fun bluetoothAdapter(): BluetoothAdapter? {
    val manager = reactContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    return manager?.adapter
  }

  @ReactMethod
  fun getStatus(promise: Promise) {
    try {
      val adapter = bluetoothAdapter()
      val map = Arguments.createMap()

      map.putString("module", "MauriMeshHardwareBle")
      map.putBoolean("nativeModule", true)
      map.putBoolean("bluetoothAdapterPresent", adapter != null)
      map.putBoolean("bluetoothEnabled", adapter?.isEnabled == true)
      map.putBoolean("scanPermission", if (Build.VERSION.SDK_INT >= 31) hasPermission(Manifest.permission.BLUETOOTH_SCAN) else true)
      map.putBoolean("connectPermission", if (Build.VERSION.SDK_INT >= 31) hasPermission(Manifest.permission.BLUETOOTH_CONNECT) else true)
      map.putBoolean("fineLocationPermission", hasPermission(Manifest.permission.ACCESS_FINE_LOCATION))
      map.putBoolean("postNotificationsPermission", if (Build.VERSION.SDK_INT >= 33) hasPermission(Manifest.permission.POST_NOTIFICATIONS) else true)
      map.putBoolean("serviceRunning", MauriMeshHardwareBleScanService.isRunning)
      map.putInt("discoveredCount", MauriMeshHardwareBleScanService.discoveredCount)
      map.putString("lastDeviceName", MauriMeshHardwareBleScanService.lastDeviceName ?: "")
      map.putString("lastDeviceAddress", MauriMeshHardwareBleScanService.lastDeviceAddress ?: "")
      map.putInt("lastRssi", MauriMeshHardwareBleScanService.lastRssi)
      map.putString("truth", "NATIVE_ANDROID_HARDWARE_BLE_STATUS")
      map.putString("proofMarker", "MAURIMESH_NATIVE_HARDWARE_BLE_STATUS_OK")

      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_STATUS_OK serviceRunning=${MauriMeshHardwareBleScanService.isRunning} discovered=${MauriMeshHardwareBleScanService.discoveredCount}")

      promise.resolve(map)
    } catch (e: Exception) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_STATUS_ERROR ${e.message}", e)
      promise.reject("MAURIMESH_NATIVE_HARDWARE_BLE_STATUS_ERROR", e)
    }
  }

  @ReactMethod
  fun startScan(promise: Promise) {
    try {
      val adapter = bluetoothAdapter()

      if (adapter == null) {
        promise.reject("NO_BLUETOOTH_ADAPTER", "Bluetooth adapter not found")
        return
      }

      if (!adapter.isEnabled) {
        promise.reject("BLUETOOTH_DISABLED", "Bluetooth is disabled")
        return
      }

      if (Build.VERSION.SDK_INT >= 31 && !hasPermission(Manifest.permission.BLUETOOTH_SCAN)) {
        promise.reject("MISSING_BLUETOOTH_SCAN_PERMISSION", "BLUETOOTH_SCAN permission missing")
        return
      }

      if (Build.VERSION.SDK_INT >= 31 && !hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
        promise.reject("MISSING_BLUETOOTH_CONNECT_PERMISSION", "BLUETOOTH_CONNECT permission missing")
        return
      }

      val intent = Intent(reactContext, MauriMeshHardwareBleScanService::class.java)
      intent.action = MauriMeshHardwareBleScanService.ACTION_START

      if (Build.VERSION.SDK_INT >= 26) {
        reactContext.startForegroundService(intent)
      } else {
        reactContext.startService(intent)
      }

      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_START_REQUESTED")

      val map = Arguments.createMap()
      map.putBoolean("started", true)
      map.putString("proofMarker", "MAURIMESH_NATIVE_HARDWARE_BLE_START_REQUESTED")
      map.putString("truth", "Foreground service requested. Android scan history should show MauriMesh after real screen-off scanning.")
      promise.resolve(map)
    } catch (e: Exception) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_START_ERROR ${e.message}", e)
      promise.reject("MAURIMESH_NATIVE_HARDWARE_BLE_START_ERROR", e)
    }
  }

  @ReactMethod
  fun stopScan(promise: Promise) {
    try {
      val intent = Intent(reactContext, MauriMeshHardwareBleScanService::class.java)
      intent.action = MauriMeshHardwareBleScanService.ACTION_STOP
      reactContext.startService(intent)

      Log.i("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_STOP_REQUESTED")

      val map = Arguments.createMap()
      map.putBoolean("stopped", true)
      map.putString("proofMarker", "MAURIMESH_NATIVE_HARDWARE_BLE_STOP_REQUESTED")
      promise.resolve(map)
    } catch (e: Exception) {
      Log.e("MauriMeshHardwareBle", "MAURIMESH_NATIVE_HARDWARE_BLE_STOP_ERROR ${e.message}", e)
      promise.reject("MAURIMESH_NATIVE_HARDWARE_BLE_STOP_ERROR", e)
    }
  }

  @ReactMethod
  fun openBluetoothSettings(promise: Promise) {
    try {
      val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      reactContext.startActivity(intent)
      promise.resolve(true)
    } catch (e: Exception) {
      promise.reject("OPEN_BLUETOOTH_SETTINGS_FAILED", e)
    }
  }
}
