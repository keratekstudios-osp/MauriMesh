package com.maurimesh.messenger

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class MauriMeshBleModule(
  private val reactContext: ReactApplicationContext
) : ReactContextBaseJavaModule(reactContext) {

  private var scanner: BluetoothLeScanner? = null
  private var scanCallback: ScanCallback? = null
  private var scanActive: Boolean = false
  private var discoveredCount: Int = 0
  private var scanStartTimeMs: Double = 0.0
  private var lastError: String = ""
  private var lastDeviceName: String = ""
  private var lastDeviceAddress: String = ""

  override fun getName(): String {
    return "MauriMeshBle"
  }

  private fun hasPermission(permission: String): Boolean {
    return reactContext.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
  }

  private fun hasBleRuntimePermissions(): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      hasPermission(Manifest.permission.BLUETOOTH_SCAN) &&
        hasPermission(Manifest.permission.BLUETOOTH_CONNECT)
    } else {
      hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)
    }
  }

  private fun baseStatusMap() = Arguments.createMap().apply {
    putString("module", "MauriMeshBle")
    putBoolean("modulePresent", true)
    putBoolean("liveBleActive", scanActive)
    putBoolean("scanActive", scanActive)
    putInt("discoveredCount", discoveredCount)
    putDouble("scanStartTimeMs", scanStartTimeMs)
    putString("lastError", lastError)
    putString("lastDeviceName", lastDeviceName)
    putString("lastDeviceAddress", lastDeviceAddress)
    putString("truth", "Native module is registered. Scan proof methods only scan and stop scan. They do not advertise, connect, send, receive, ACK, or relay.")
  }

  @ReactMethod
  fun getStatus(promise: Promise) {
    try {
      val status = baseStatusMap()
      status.putString("mode", "read_only")
      status.putBoolean("blePermissions", hasBleRuntimePermissions())
      promise.resolve(status)
    } catch (error: Exception) {
      promise.reject("MAURIMESH_BLE_STATUS_ERROR", error)
    }
  }

  @ReactMethod
  fun getScanProofStatus(promise: Promise) {
    try {
      val status = baseStatusMap()
      status.putString("mode", "scan_proof_status")
      status.putBoolean("blePermissions", hasBleRuntimePermissions())
      promise.resolve(status)
    } catch (error: Exception) {
      promise.reject("MAURIMESH_BLE_SCAN_STATUS_ERROR", error)
    }
  }

  @ReactMethod
  fun startScanProof(promise: Promise) {
    try {
      lastError = ""

      if (!hasBleRuntimePermissions()) {
        lastError = "Missing Android BLE runtime permissions."
        val status = baseStatusMap()
        status.putString("mode", "scan_proof_permission_denied")
        status.putBoolean("started", false)
        promise.resolve(status)
        return
      }

      if (scanActive) {
        val status = baseStatusMap()
        status.putString("mode", "scan_proof_already_active")
        status.putBoolean("started", true)
        promise.resolve(status)
        return
      }

      val bluetoothManager =
        reactContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager

      val adapter = bluetoothManager?.adapter

      if (adapter == null) {
        lastError = "Bluetooth adapter unavailable."
        val status = baseStatusMap()
        status.putString("mode", "scan_proof_no_adapter")
        status.putBoolean("started", false)
        promise.resolve(status)
        return
      }

      if (!adapter.isEnabled) {
        lastError = "Bluetooth adapter disabled."
        val status = baseStatusMap()
        status.putString("mode", "scan_proof_adapter_disabled")
        status.putBoolean("started", false)
        promise.resolve(status)
        return
      }

      scanner = adapter.bluetoothLeScanner

      if (scanner == null) {
        lastError = "BluetoothLeScanner unavailable."
        val status = baseStatusMap()
        status.putString("mode", "scan_proof_no_scanner")
        status.putBoolean("started", false)
        promise.resolve(status)
        return
      }

      discoveredCount = 0
      lastDeviceName = ""
      lastDeviceAddress = ""
      scanStartTimeMs = System.currentTimeMillis().toDouble()

      scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
          discoveredCount += 1
          lastDeviceName = result.device?.name ?: "unknown"
          lastDeviceAddress = result.device?.address ?: "unknown"
        }

        override fun onBatchScanResults(results: MutableList<ScanResult>) {
          discoveredCount += results.size
          val last = results.lastOrNull()
          if (last != null) {
            lastDeviceName = last.device?.name ?: "unknown"
            lastDeviceAddress = last.device?.address ?: "unknown"
          }
        }

        override fun onScanFailed(errorCode: Int) {
          lastError = "Scan failed with errorCode=$errorCode"
          scanActive = false
        }
      }

      val settings = ScanSettings.Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .build()

      scanner?.startScan(null, settings, scanCallback)
      scanActive = true

      val status = baseStatusMap()
      status.putString("mode", "scan_proof_started")
      status.putBoolean("started", true)
      promise.resolve(status)
    } catch (error: Exception) {
      lastError = error.message ?: error.toString()
      scanActive = false
      promise.reject("MAURIMESH_BLE_SCAN_START_ERROR", error)
    }
  }

  @ReactMethod
  fun stopScanProof(promise: Promise) {
    try {
      val cb = scanCallback
      if (cb != null) {
        try {
          scanner?.stopScan(cb)
        } catch (error: Exception) {
          lastError = error.message ?: error.toString()
        }
      }

      scanCallback = null
      scanActive = false

      val status = baseStatusMap()
      status.putString("mode", "scan_proof_stopped")
      status.putBoolean("stopped", true)
      promise.resolve(status)
    } catch (error: Exception) {
      lastError = error.message ?: error.toString()
      scanActive = false
      promise.reject("MAURIMESH_BLE_SCAN_STOP_ERROR", error)
    }
  }
}
