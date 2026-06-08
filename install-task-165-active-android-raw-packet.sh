#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#165 — ACTIVE ANDROID RAW PACKET TRANSPORT"
echo "Creates MeshCentralClient in active Android native module package"
echo "Wires sendRawPacket + broadcastRawPacket into MauriMeshBleModule"
echo "Preserves proven scan proof"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-165-active-android-$STAMP"

BASE="$ROOT/android/app/src/main/java/com/maurimesh/messenger"
MODULE="$BASE/MauriMeshBleModule.kt"
CLIENT="$BASE/MeshCentralClient.kt"
TYPES="$BASE/MeshRawPacketTypes.kt"
DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"

mkdir -p "$BACKUP" "$BASE" "$DOCS" "$SCRIPTS"

echo ""
echo "1. Verify active native files"

if [ ! -f "$MODULE" ]; then
  echo "ERROR: Active MauriMeshBleModule.kt not found at $MODULE"
  exit 1
fi

cp "$MODULE" "$BACKUP/MauriMeshBleModule.kt" 2>/dev/null || true
cp "$CLIENT" "$BACKUP/MeshCentralClient.kt" 2>/dev/null || true
cp "$TYPES" "$BACKUP/MeshRawPacketTypes.kt" 2>/dev/null || true

echo "Backup: $BACKUP"

echo ""
echo "2. Create MeshRawPacketTypes.kt"

cat > "$TYPES" <<'KT'
package com.maurimesh.messenger

import java.util.UUID

object MeshRawPacketUuids {
  val SERVICE_UUID: UUID =
    UUID.fromString("7c7a0001-4d41-5552-494d-455348000001")

  val RAW_PACKET_CHARACTERISTIC_UUID: UUID =
    UUID.fromString("7c7a0002-4d41-5552-494d-455348000002")
}

data class MeshPeerCacheEntry(
  val nodeId: String,
  val address: String,
  val name: String?,
  val lastSeenAtMs: Long,
  val rssi: Int?
)
KT

echo ""
echo "3. Create MeshCentralClient.kt"

cat > "$CLIENT" <<'KT'
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
KT

echo ""
echo "4. Patch MauriMeshBleModule.kt safely"

python3 <<'PY'
from pathlib import Path
import re

path = Path("android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt")
text = path.read_text()
original = text

# Ensure imports.
for imp in [
    "import android.util.Base64",
    "import com.facebook.react.bridge.ReactMethod",
    "import com.facebook.react.bridge.Promise",
]:
    if imp not in text:
        m = re.search(r"^(package\s+[^\n]+\n)", text, re.M)
        if m:
            text = text[:m.end()] + imp + "\n" + text[m.end():]

# Add central client property after class opening.
if "private val centralClient = MeshCentralClient(reactContext)" not in text:
    class_match = re.search(r"class\s+MauriMeshBleModule\s*\([^)]*\)\s*:\s*[^{]+\{", text, re.S)
    if not class_match:
        raise SystemExit("ERROR: Could not find MauriMeshBleModule class opening")
    insert_at = class_match.end()
    text = text[:insert_at] + "\n  private val centralClient = MeshCentralClient(reactContext)\n" + text[insert_at:]

# Patch scan result caching.
if "centralClient.cachePeer(result.device, result.rssi)" not in text:
    text = re.sub(
        r"(override\s+fun\s+onScanResult\s*\([^)]*result\s*:\s*android\.bluetooth\.le\.ScanResult[^)]*\)\s*\{)",
        r"\1\n          centralClient.cachePeer(result.device, result.rssi)",
        text,
        count=1,
        flags=re.S,
    )
    text = re.sub(
        r"(override\s+fun\s+onScanResult\s*\([^)]*result\s*:\s*ScanResult[^)]*\)\s*\{)",
        r"\1\n          centralClient.cachePeer(result.device, result.rssi)",
        text,
        count=1,
        flags=re.S,
    )

# Add React methods before final brace.
if "TASK_165_NATIVE_MODULE_RAW_PACKET_BRIDGE_20260608_ACTIVE_ANDROID_A" not in text:
    methods = '''

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

'''
    idx = text.rfind("}")
    if idx == -1:
        raise SystemExit("ERROR: Could not find closing brace in MauriMeshBleModule.kt")
    text = text[:idx] + methods + "\n" + text[idx:]

path.write_text(text)

print("MauriMeshBleModule patched" if text != original else "MauriMeshBleModule unchanged")
PY

echo ""
echo "5. Add JS raw packet client"

mkdir -p "$ROOT/src/maurimesh/ble"

cat > "$ROOT/src/maurimesh/ble/rawPacketClient.ts" <<'TS'
import { NativeModules, Platform } from "react-native";

export const TASK_165_RAW_PACKET_CLIENT_MARKER =
  "TASK_165_RAW_PACKET_CLIENT_20260608_ACTIVE_ANDROID_A";

type MauriMeshBleRawPacketModule = {
  sendRawPacket?: (nodeId: string, base64Payload: string) => Promise<boolean>;
  broadcastRawPacket?: (base64Payload: string) => Promise<number>;
  getRawPacketPeerCount?: () => Promise<number>;
};

function toBase64(bytes: Uint8Array): string {
  const chars = Array.from(bytes, (byte) => String.fromCharCode(byte)).join("");

  if (typeof btoa === "function") {
    return btoa(chars);
  }

  const BufferCtor = (globalThis as any).Buffer;
  if (BufferCtor) {
    return BufferCtor.from(bytes).toString("base64");
  }

  throw new Error("Base64 encoder unavailable");
}

function getNative(): MauriMeshBleRawPacketModule | null {
  return (NativeModules.MauriMeshBle as MauriMeshBleRawPacketModule | undefined) || null;
}

export async function sendRawPacketToNode(
  nodeId: string,
  bytes: Uint8Array
): Promise<boolean> {
  if (Platform.OS !== "android") return false;

  const native = getNative();

  if (!native?.sendRawPacket) {
    throw new Error("MauriMeshBle.sendRawPacket is unavailable");
  }

  return Boolean(await native.sendRawPacket(nodeId, toBase64(bytes)));
}

export async function broadcastRawPacketToPeers(bytes: Uint8Array): Promise<number> {
  if (Platform.OS !== "android") return 0;

  const native = getNative();

  if (!native?.broadcastRawPacket) {
    throw new Error("MauriMeshBle.broadcastRawPacket is unavailable");
  }

  return Number(await native.broadcastRawPacket(toBase64(bytes)));
}

export async function getRawPacketPeerCount(): Promise<number> {
  if (Platform.OS !== "android") return 0;

  const native = getNative();

  if (!native?.getRawPacketPeerCount) {
    return 0;
  }

  return Number(await native.getRawPacketPeerCount());
}
TS

echo ""
echo "6. Audit"

grep -RniE "TASK_165|sendRawPacket|broadcastRawPacket|getRawPacketPeerCount|MeshCentralClient|cachePeer|WRITE_TYPE_NO_RESPONSE" \
  android/app/src/main/java/com/maurimesh/messenger src/maurimesh/ble 2>/dev/null || true

echo ""
echo "7. TypeScript check"
npx tsc --noEmit

echo ""
echo "8. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

cat > "$DOCS/task-165-active-android-raw-packet.md" <<'MD'
# Task #165 — Active Android Raw Packet Transport

Marker: `TASK_165_MESHCENTRAL_RAW_PACKET_TRANSPORT_20260608_ACTIVE_ANDROID_A`

## Installed

- `android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt`
- `android/app/src/main/java/com/maurimesh/messenger/MeshRawPacketTypes.kt`
- `MauriMeshBleModule.kt` bridge methods:
  - `sendRawPacket(nodeId, base64Payload)`
  - `broadcastRawPacket(base64Payload)`
  - `getRawPacketPeerCount()`
- JS client:
  - `src/maurimesh/ble/rawPacketClient.ts`

## Truth boundary

This installs central-side BLE GATT write submission.

It does not prove:
- receiver GATT server exists
- characteristic exists on receiver
- packet received
- ACK returned
- relay completed

Next proof requires receiver GATT server and two-phone ACK proof.
MD

echo ""
echo "============================================================"
echo "#165 ACTIVE ANDROID RAW PACKET TRANSPORT INSTALLED"
echo "Backup: $BACKUP"
echo "Next: build APK, then prove receiver GATT + ACK on two phones."
echo "============================================================"
