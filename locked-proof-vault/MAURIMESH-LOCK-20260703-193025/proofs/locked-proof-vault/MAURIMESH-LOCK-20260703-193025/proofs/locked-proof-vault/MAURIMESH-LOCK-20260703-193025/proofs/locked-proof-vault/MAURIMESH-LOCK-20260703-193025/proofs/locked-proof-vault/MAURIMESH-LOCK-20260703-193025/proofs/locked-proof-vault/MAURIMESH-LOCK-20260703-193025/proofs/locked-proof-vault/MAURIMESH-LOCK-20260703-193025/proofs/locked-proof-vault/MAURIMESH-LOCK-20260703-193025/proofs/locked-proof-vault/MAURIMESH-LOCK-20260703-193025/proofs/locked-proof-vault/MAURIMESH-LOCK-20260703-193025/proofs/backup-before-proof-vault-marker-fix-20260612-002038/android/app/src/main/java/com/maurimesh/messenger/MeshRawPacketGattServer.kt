package com.maurimesh.messenger

import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Build
import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import java.util.concurrent.atomic.AtomicInteger

data class MeshRawPacketReceiveEvent(
  val fromAddress: String,
  val bytes: ByteArray,
  val receivedAtMs: Long
)

class MeshRawPacketGattServer(
  private val reactContext: ReactApplicationContext,
  private val onPacketReceived: (MeshRawPacketReceiveEvent) -> Unit
) {
  companion object {
    const val MARKER = "TASK_165B_RAW_PACKET_GATT_SERVER_20260608_A"
  }

  private var gattServer: BluetoothGattServer? = null
  private var running: Boolean = false
  private var lastError: String? = null
  private var lastFromAddress: String? = null
  private var lastPacketSize: Int = 0
  private var lastReceivedAtMs: Long = 0L
  private val receivedCount = AtomicInteger(0)

  private val callback = object : BluetoothGattServerCallback() {
    override fun onCharacteristicWriteRequest(
      device: BluetoothDevice?,
      requestId: Int,
      characteristic: BluetoothGattCharacteristic?,
      preparedWrite: Boolean,
      responseNeeded: Boolean,
      offset: Int,
      value: ByteArray?
    ) {
      val address = device?.address ?: "unknown"
      val uuid = characteristic?.uuid
      val bytes = value ?: ByteArray(0)

      if (uuid != MeshRawPacketUuids.RAW_PACKET_CHARACTERISTIC_UUID) {
        lastError = "Write received for wrong characteristic: $uuid"
        try {
          if (responseNeeded) {
            gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
          }
        } catch (_: Throwable) {}
        return
      }

      if (bytes.isEmpty()) {
        lastError = "Empty raw packet received from $address"
        try {
          if (responseNeeded) {
            gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_FAILURE, offset, null)
          }
        } catch (_: Throwable) {}
        return
      }

      lastFromAddress = address
      lastPacketSize = bytes.size
      lastReceivedAtMs = System.currentTimeMillis()
      receivedCount.incrementAndGet()
      lastError = null

      Log.i(
        "MauriMeshBle",
        "[$MARKER] RX_RAW_PACKET from=$address bytes=${bytes.size} responseNeeded=$responseNeeded"
      )

      try {
        onPacketReceived(
          MeshRawPacketReceiveEvent(
            fromAddress = address,
            bytes = bytes,
            receivedAtMs = lastReceivedAtMs
          )
        )
      } catch (error: Throwable) {
        lastError = "onPacketReceived failed: ${error.message ?: error.toString()}"
        Log.e("MauriMeshBle", "[$MARKER] $lastError")
      }

      try {
        if (responseNeeded) {
          gattServer?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, offset, null)
        }
      } catch (error: Throwable) {
        lastError = "sendResponse failed: ${error.message ?: error.toString()}"
      }
    }
  }

  fun start(): Boolean {
    if (running) return true

    try {
      val manager =
        reactContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager

      if (manager == null) {
        lastError = "BluetoothManager unavailable"
        return false
      }

      val server = manager.openGattServer(reactContext, callback)

      if (server == null) {
        lastError = "openGattServer returned null"
        return false
      }

      val service = BluetoothGattService(
        MeshRawPacketUuids.SERVICE_UUID,
        BluetoothGattService.SERVICE_TYPE_PRIMARY
      )

      val properties =
        BluetoothGattCharacteristic.PROPERTY_WRITE or
          BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE

      val permissions = BluetoothGattCharacteristic.PERMISSION_WRITE

      val characteristic = BluetoothGattCharacteristic(
        MeshRawPacketUuids.RAW_PACKET_CHARACTERISTIC_UUID,
        properties,
        permissions
      )

      service.addCharacteristic(characteristic)

      val added = server.addService(service)

      if (!added) {
        lastError = "Failed to add MauriMesh raw packet GATT service"
        try { server.close() } catch (_: Throwable) {}
        return false
      }

      gattServer = server
      running = true
      lastError = null

      Log.i(
        "MauriMeshBle",
        "[$MARKER] RAW_PACKET_GATT_SERVER_STARTED service=${MeshRawPacketUuids.SERVICE_UUID}"
      )

      return true
    } catch (security: SecurityException) {
      lastError = "SecurityException: ${security.message ?: security.toString()}"
      Log.e("MauriMeshBle", "[$MARKER] $lastError")
      return false
    } catch (error: Throwable) {
      lastError = error.message ?: error.toString()
      Log.e("MauriMeshBle", "[$MARKER] start failed: $lastError")
      return false
    }
  }

  fun stop(): Boolean {
    try {
      gattServer?.clearServices()
      gattServer?.close()
    } catch (_: Throwable) {
    } finally {
      gattServer = null
      running = false
    }

    Log.i("MauriMeshBle", "[$MARKER] RAW_PACKET_GATT_SERVER_STOPPED")
    return true
  }

  fun getStatusMap(): Map<String, Any?> {
    return mapOf(
      "marker" to MARKER,
      "running" to running,
      "receivedCount" to receivedCount.get(),
      "lastFromAddress" to lastFromAddress,
      "lastPacketSize" to lastPacketSize,
      "lastReceivedAtMs" to lastReceivedAtMs,
      "lastError" to lastError,
      "serviceUuid" to MeshRawPacketUuids.SERVICE_UUID.toString(),
      "characteristicUuid" to MeshRawPacketUuids.RAW_PACKET_CHARACTERISTIC_UUID.toString()
    )
  }
}
