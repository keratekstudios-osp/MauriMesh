package com.maurimesh.messenger
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.bridge.WritableMap
import android.util.Base64

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
  private val centralClient = MeshCentralClient(reactContext)
  private var rawPacketGattServer: MeshRawPacketGattServer? = null
  private var rawPacketAckCount: Int = 0
  private var rawPacketLastAckTarget: String? = null
  private var rawPacketLastAckSentAtMs: Long = 0L


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
          centralClient.cachePeer(result.device, result.rssi)
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


  // TASK_165_NATIVE_MODULE_RAW_PACKET_BRIDGE_20260608_ACTIVE_ANDROID_A
  @ReactMethod
  fun sendRawPacket(nodeId: String, base64Payload: String, promise: Promise) {
    try {
      val bytes = Base64.decode(base64Payload, Base64.NO_WRAP)
      val ok = centralClient.sendRawPacket(nodeId, bytes)
      promise.resolve(ok)
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_SEND_RAW_PACKET_ERROR", error)
    }
  }

  @ReactMethod
  fun broadcastRawPacket(base64Payload: String, promise: Promise) {
    try {
      val bytes = Base64.decode(base64Payload, Base64.NO_WRAP)
      val successCount = centralClient.broadcastRawPacket(bytes)
      promise.resolve(successCount)
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_BROADCAST_RAW_PACKET_ERROR", error)
    }
  }

  @ReactMethod
  fun getRawPacketPeerCount(promise: Promise) {
    try {
      promise.resolve(centralClient.getRawPacketPeerCount())
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_RAW_PACKET_PEER_COUNT_ERROR", error)
    }
  }




  // TASK_165B_RAW_PACKET_RECEIVER_BRIDGE_20260608_A
  @ReactMethod
  fun startRawPacketReceiver(promise: Promise) {
    try {
      if (rawPacketGattServer == null) {
        rawPacketGattServer = MeshRawPacketGattServer(reactContext) { event ->
          centralClient.cachePeerAddress(event.fromAddress, "ack-peer", null)

          val rxPacketId = extractPacketIdFromBytes(event.bytes)
          emitRawPacketProofEvent(
            "rx_packet",
            rxPacketId,
            event.fromAddress,
            event.bytes.size,
            true,
            "RX_RAW_PACKET"
          )

          val rxPacketId = extractPacketIdFromBytes(event.bytes)
                    val ackText =
            "MAURIMESH_ACK|from=${event.fromAddress}|bytes=${event.bytes.size}|at=${event.receivedAtMs}"
          val ackBytes = ackText.toByteArray(Charsets.UTF_8)

          val ackSent = centralClient.sendRawPacket(event.fromAddress, ackBytes)

          emitRawPacketProofEvent(
            "ack_sent",
            rxPacketId,
            event.fromAddress,
            ackBytes.size,
            ackSent,
            if (ackSent) "ACK_SENT=true" else "ACK_SENT=false"
          )

                    if (ackSent) {
            rawPacketAckCount += 1
            rawPacketLastAckTarget = event.fromAddress
            rawPacketLastAckSentAtMs = System.currentTimeMillis()
          }

          android.util.Log.i(
            "MauriMeshBle",
            "[TASK_165B_RAW_PACKET_RECEIVER_BRIDGE_20260608_A] RX=${event.bytes.size} ACK_SENT=$ackSent target=${event.fromAddress}"
          )
        }
      }

      val ok = rawPacketGattServer?.start() == true
      promise.resolve(rawPacketReceiverStatusMap(ok))
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_START_RAW_PACKET_RECEIVER_ERROR", error)
    }
  }

  @ReactMethod
  fun stopRawPacketReceiver(promise: Promise) {
    try {
      val ok = rawPacketGattServer?.stop() ?: true
      promise.resolve(rawPacketReceiverStatusMap(ok))
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_STOP_RAW_PACKET_RECEIVER_ERROR", error)
    }
  }

  @ReactMethod
  fun getRawPacketReceiverStatus(promise: Promise) {
    try {
      promise.resolve(rawPacketReceiverStatusMap(true))
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_RAW_PACKET_RECEIVER_STATUS_ERROR", error)
    }
  }

  @ReactMethod
  fun sendRawPacketUtf8(nodeId: String, text: String, promise: Promise) {
    try {
      val ok = centralClient.sendRawPacket(nodeId, text.toByteArray(Charsets.UTF_8))
      promise.resolve(ok)
    } catch (error: Throwable) {
      promise.reject("MAURIMESH_SEND_RAW_PACKET_UTF8_ERROR", error)
    }
  }

  private fun rawPacketReceiverStatusMap(ok: Boolean): WritableMap {
    val map = Arguments.createMap()
    val status = rawPacketGattServer?.getStatusMap() ?: emptyMap<String, Any?>()

    map.putBoolean("ok", ok)
    map.putString("marker", "TASK_165B_RAW_PACKET_RECEIVER_BRIDGE_20260608_A")
    map.putString("serverMarker", status["marker"] as? String ?: "not_started")
    map.putBoolean("running", status["running"] as? Boolean ?: false)
    map.putInt("receivedCount", status["receivedCount"] as? Int ?: 0)
    map.putString("lastFromAddress", status["lastFromAddress"] as? String)
    map.putInt("lastPacketSize", status["lastPacketSize"] as? Int ?: 0)
    map.putDouble("lastReceivedAtMs", ((status["lastReceivedAtMs"] as? Long) ?: 0L).toDouble())
    map.putString("lastError", status["lastError"] as? String)
    map.putString("serviceUuid", status["serviceUuid"] as? String)
    map.putString("characteristicUuid", status["characteristicUuid"] as? String)
    map.putInt("ackCount", rawPacketAckCount)
    map.putString("lastAckTarget", rawPacketLastAckTarget)
    map.putDouble("lastAckSentAtMs", rawPacketLastAckSentAtMs.toDouble())
    map.putInt("peerCount", centralClient.getRawPacketPeerCount())

    return map
  }




  // TASK_192_NATIVE_PROOF_EVENT_EMITTER_20260608_A
  private fun emitRawPacketProofEvent(
    eventType: String,
    packetId: String,
    peerAddress: String,
    payloadBytes: Int,
    ok: Boolean,
    detail: String?
  ) {
    try {
      val map = Arguments.createMap()
      map.putString("marker", "TASK_192_NATIVE_PROOF_EVENT_EMITTER_20260608_A")
      map.putString("type", eventType)
      map.putString("packetId", packetId)
      map.putString("peerAddress", peerAddress)
      map.putInt("payloadBytes", payloadBytes)
      map.putBoolean("ok", ok)
      map.putDouble("at", System.currentTimeMillis().toDouble())
      map.putString("transport", "BLE")
      map.putString("detail", detail)

      reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
        .emit("MauriMeshRawPacketProofEvent", map)

      android.util.Log.i(
        "MauriMeshBle",
        "[TASK_192_NATIVE_PROOF_EVENT_EMITTER_20260608_A] event=$eventType packetId=$packetId peer=$peerAddress ok=$ok bytes=$payloadBytes"
      )
    } catch (error: Throwable) {
      android.util.Log.e(
        "MauriMeshBle",
        "[TASK_192_NATIVE_PROOF_EVENT_EMITTER_20260608_A] emit failed: ${error.message ?: error.toString()}"
      )
    }
  }

  private fun extractPacketIdFromBytes(bytes: ByteArray): String {
    return try {
      val text = bytes.toString(Charsets.UTF_8)
      val first = text.split("|").firstOrNull()?.trim()
      if (!first.isNullOrBlank() && first.length <= 128) first
      else "MM-RX-${System.currentTimeMillis()}"
    } catch (_: Throwable) {
      "MM-RX-${System.currentTimeMillis()}"
    }
  }


}
