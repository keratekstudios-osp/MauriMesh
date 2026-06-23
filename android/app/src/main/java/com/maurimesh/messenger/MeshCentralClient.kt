package com.maurimesh.messenger

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.os.Build
import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class MeshCentralClient(
  private val reactContext: ReactApplicationContext
) {
  companion object {
    const val MARKER = "TASK_165_MESHCENTRAL_RAW_PACKET_TRANSPORT_20260608_ACTIVE_ANDROID_A"
  }

  private val scanCache: ConcurrentHashMap<String, MeshPeerCacheEntry> = ConcurrentHashMap()

  fun cachePeer(device: BluetoothDevice?, rssi: Int?) {
    try {
      val address = device?.address ?: return
      val name = try { device.name } catch (_: SecurityException) { null }

      val entry = MeshPeerCacheEntry(
        nodeId = address,
        address = address,
        name = name,
        lastSeenAtMs = System.currentTimeMillis(),
        rssi = rssi
      )

      scanCache[address] = entry
      Log.i("MauriMeshBle", "[$MARKER] cached peer address=$address rssi=$rssi")
    } catch (error: Throwable) {
      logError("cachePeer failed", mapOf("error" to (error.message ?: error.toString())))
    }
  }


  fun cachePeerAddress(address: String, name: String? = null, rssi: Int? = null) {
    if (address.isBlank()) return

    val entry = MeshPeerCacheEntry(
      nodeId = address,
      address = address,
      name = name,
      lastSeenAtMs = System.currentTimeMillis(),
      rssi = rssi
    )

    scanCache[address] = entry
    Log.i("MauriMeshBle", "[$MARKER] cached direct peer address=$address")
  }

  fun sendRawPacket(nodeId: String, bytes: ByteArray): Boolean {
    if (nodeId.isBlank()) {
      logError("sendRawPacket refused blank nodeId", mapOf("bytes" to bytes.size))
      return false
    }

    if (bytes.isEmpty()) {
      logError("sendRawPacket refused empty payload", mapOf("nodeId" to nodeId))
      return false
    }

    val peer = scanCache[nodeId] ?: scanCache.values.firstOrNull { it.address == nodeId }

    if (peer == null) {
      logError(
        "sendRawPacket peer not found in scan cache",
        mapOf("nodeId" to nodeId, "knownPeers" to scanCache.size, "bytes" to bytes.size)
      )
      return false
    }

    return writeRawPacketToPeer(peer, bytes)
  }

  fun broadcastRawPacket(bytes: ByteArray): Int {
    if (bytes.isEmpty()) {
      logError("broadcastRawPacket refused empty payload")
      return 0
    }

    val peers = scanCache.values.toList()

    if (peers.isEmpty()) {
      logError("broadcastRawPacket has no cached peers", mapOf("bytes" to bytes.size))
      return 0
    }

    var success = 0
    for (peer in peers) {
      if (sendRawPacket(peer.nodeId, bytes)) {
        success += 1
      }
    }

    logInfo(
      "broadcastRawPacket complete",
      mapOf("peers" to peers.size, "success" to success, "bytes" to bytes.size)
    )

    return success
  }

  fun getRawPacketPeerCount(): Int = scanCache.size

  fun getRawPacketCachedPeerIds(): List<String> = scanCache.keys().toList()

  private fun writeRawPacketToPeer(peer: MeshPeerCacheEntry, bytes: ByteArray): Boolean {
    var gatt: BluetoothGatt? = null
    val connectedLatch = CountDownLatch(1)
    val servicesLatch = CountDownLatch(1)
    val writeLatch = CountDownLatch(1)

    var connected = false
    var servicesReady = false
    var writeCallbackSeen = false
    var writeCallbackOk = false
    var lastError: String? = null

    try {
      val bluetoothManager =
        reactContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager

      val adapter: BluetoothAdapter? = bluetoothManager?.adapter

      if (adapter == null) {
        logError("Bluetooth adapter unavailable", mapOf("nodeId" to peer.nodeId))
        return false
      }

      val device = adapter.getRemoteDevice(peer.address)

      val callback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
          if (status != BluetoothGatt.GATT_SUCCESS) {
            lastError = "GATT connection status failure: $status"
            connectedLatch.countDown()
            servicesLatch.countDown()
            writeLatch.countDown()
            return
          }

          if (newState == BluetoothProfile.STATE_CONNECTED) {
            connected = true
            connectedLatch.countDown()
            try {
              g.discoverServices()
            } catch (error: SecurityException) {
              lastError = "Missing BLUETOOTH_CONNECT during discoverServices"
              servicesLatch.countDown()
            }
          }

          if (newState == BluetoothProfile.STATE_DISCONNECTED) {
            connected = false
            connectedLatch.countDown()
            servicesLatch.countDown()
            writeLatch.countDown()
          }
        }

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
          servicesReady = status == BluetoothGatt.GATT_SUCCESS
          if (!servicesReady) {
            lastError = "Service discovery failed: $status"
          }
          servicesLatch.countDown()
        }

        override fun onCharacteristicWrite(
          g: BluetoothGatt,
          characteristic: BluetoothGattCharacteristic,
          status: Int
        ) {
          writeCallbackSeen = true
          writeCallbackOk = status == BluetoothGatt.GATT_SUCCESS
          if (!writeCallbackOk) {
            lastError = "Characteristic write failed: $status"
          }
          writeLatch.countDown()
        }
      }

      gatt =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
          device.connectGatt(reactContext, false, callback, BluetoothDevice.TRANSPORT_LE)
        } else {
          @Suppress("DEPRECATION")
          device.connectGatt(reactContext, false, callback)
        }

      if (!connectedLatch.await(8000, TimeUnit.MILLISECONDS) || !connected) {
        logError(
          "sendRawPacket connect timeout/failure",
          mapOf("nodeId" to peer.nodeId, "address" to peer.address, "error" to (lastError ?: "connect_timeout"))
        )
        return false
      }

      if (!servicesLatch.await(8000, TimeUnit.MILLISECONDS) || !servicesReady) {
        logError(
          "sendRawPacket service discovery timeout/failure",
          mapOf("nodeId" to peer.nodeId, "address" to peer.address, "error" to (lastError ?: "service_timeout"))
        )
        return false
      }

      val service: BluetoothGattService? = gatt?.getService(MeshRawPacketUuids.SERVICE_UUID)

      if (service == null) {
        logError(
          "MauriMesh raw packet service not found",
          mapOf("nodeId" to peer.nodeId, "address" to peer.address, "serviceUuid" to MeshRawPacketUuids.SERVICE_UUID.toString())
        )
        return false
      }

      val characteristic =
        service.getCharacteristic(MeshRawPacketUuids.RAW_PACKET_CHARACTERISTIC_UUID)

      if (characteristic == null) {
        logError(
          "MauriMesh raw packet characteristic not found",
          mapOf("nodeId" to peer.nodeId, "address" to peer.address, "characteristicUuid" to MeshRawPacketUuids.RAW_PACKET_CHARACTERISTIC_UUID.toString())
        )
        return false
      }

      characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE

      val writeSubmitted =
        if (Build.VERSION.SDK_INT >= 33) {
          val status = gatt?.writeCharacteristic(
            characteristic,
            bytes,
            BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
          )
          status == BluetoothGatt.GATT_SUCCESS
        } else {
          @Suppress("DEPRECATION")
          characteristic.value = bytes
          @Suppress("DEPRECATION")
          MauriMeshNativeBlePacketLogger.gattWrite(characteristic.value, "before writeCharacteristic MeshCentralClient.kt")
          MauriMeshGattPacketProof.logGattPayload("GATT_CLIENT_WRITE_ATTEMPT", characteristic.value, "MeshCentralClient.kt before writeCharacteristic")
          gatt?.writeCharacteristic(characteristic) == true
        }

      if (!writeSubmitted) {
        logError(
          "sendRawPacket writeCharacteristic refused",
          mapOf("nodeId" to peer.nodeId, "address" to peer.address, "bytes" to bytes.size)
        )
        return false
      }

      writeLatch.await(2500, TimeUnit.MILLISECONDS)

      if (writeCallbackSeen && !writeCallbackOk) {
        logError(
          "sendRawPacket write callback failed",
          mapOf("nodeId" to peer.nodeId, "address" to peer.address, "bytes" to bytes.size, "error" to (lastError ?: "write_callback_failed"))
        )
        return false
      }

      logInfo(
        "sendRawPacket write submitted",
        mapOf("nodeId" to peer.nodeId, "address" to peer.address, "bytes" to bytes.size, "writeType" to "WITHOUT_RESPONSE")
      )

      return true
    } catch (security: SecurityException) {
      logError(
        "sendRawPacket security exception",
        mapOf("nodeId" to peer.nodeId, "address" to peer.address, "error" to (security.message ?: security.toString()))
      )
      return false
    } catch (error: Throwable) {
      logError(
        "sendRawPacket failed",
        mapOf("nodeId" to peer.nodeId, "address" to peer.address, "error" to (error.message ?: error.toString()))
      )
      return false
    } finally {
      try { gatt?.disconnect() } catch (_: Throwable) {}
      try { gatt?.close() } catch (_: Throwable) {}
    }
  }

  private fun logInfo(message: String, data: Map<String, Any?> = emptyMap()) {
    Log.i("MauriMeshBle", "[$MARKER] $message $data")
  }

  private fun logError(message: String, data: Map<String, Any?> = emptyMap()) {
    Log.e("MauriMeshBle", "[$MARKER] $message $data")
  }
}
