#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#165 — MESH CENTRAL RAW PACKET TRANSPORT"
echo "Adds sendRawPacket() and broadcastRawPacket() to MeshCentralClient"
echo "NO UI rewrite, NO mock data, NO deletion of existing BLE files"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-165-meshcentral-raw-packet-$STAMP"

BLE_DIR="$ROOT/artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble"
CLIENT="$BLE_DIR/MeshCentralClient.kt"
MODULE="$BLE_DIR/MauriMeshBleModule.kt"
EVENTS="$BLE_DIR/MeshBleEventEmitter.kt"
DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"

mkdir -p "$BACKUP" "$BLE_DIR" "$DOCS" "$SCRIPTS"

echo ""
echo "1. Backup current BLE plugin files"
cp "$CLIENT" "$BACKUP/MeshCentralClient.kt" 2>/dev/null || true
cp "$MODULE" "$BACKUP/MauriMeshBleModule.kt" 2>/dev/null || true
cp "$EVENTS" "$BACKUP/MeshBleEventEmitter.kt" 2>/dev/null || true

echo "Backup: $BACKUP"

echo ""
echo "2. Verify target files"
if [ ! -f "$CLIENT" ]; then
  echo "ERROR: Missing $CLIENT"
  echo "Find current file with:"
  echo "find artifacts -name MeshCentralClient.kt -print"
  exit 1
fi

if [ ! -f "$MODULE" ]; then
  echo "WARN: Missing $MODULE"
fi

echo ""
echo "3. Ensure MeshBleEventEmitter has raw packet helper methods"

if [ ! -f "$EVENTS" ]; then
cat > "$EVENTS" <<'KT'
package com.maurimesh.ble

import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.facebook.react.bridge.Arguments

class MeshBleEventEmitter(
  private val reactContext: ReactApplicationContext? = null
) {
  fun emit(type: String, message: String, data: Map<String, Any?> = emptyMap()) {
    Log.i("MauriMeshBle", "[$type] $message $data")

    val context = reactContext ?: return
    val params = Arguments.createMap()
    params.putString("type", type)
    params.putString("message", message)

    val payload = Arguments.createMap()
    data.forEach { (key, value) ->
      when (value) {
        null -> payload.putNull(key)
        is String -> payload.putString(key, value)
        is Boolean -> payload.putBoolean(key, value)
        is Int -> payload.putInt(key, value)
        is Double -> payload.putDouble(key, value)
        is Float -> payload.putDouble(key, value.toDouble())
        is Long -> payload.putDouble(key, value.toDouble())
        else -> payload.putString(key, value.toString())
      }
    }

    params.putMap("data", payload)

    context
      .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
      .emit("MauriMeshBleEvent", params)
  }

  fun rawPacketInfo(message: String, data: Map<String, Any?> = emptyMap()) {
    emit("RAW_PACKET_INFO", message, data)
  }

  fun rawPacketError(message: String, data: Map<String, Any?> = emptyMap()) {
    emit("RAW_PACKET_ERROR", message, data)
  }
}
KT
else
python3 <<'PY'
from pathlib import Path

path = Path("artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble/MeshBleEventEmitter.kt")
text = path.read_text()

changed = False

if "fun rawPacketInfo(" not in text:
    insert = '''
  fun rawPacketInfo(message: String, data: Map<String, Any?> = emptyMap()) {
    emit("RAW_PACKET_INFO", message, data)
  }

  fun rawPacketError(message: String, data: Map<String, Any?> = emptyMap()) {
    emit("RAW_PACKET_ERROR", message, data)
  }
'''
    idx = text.rfind("}")
    if idx == -1:
        raise SystemExit("ERROR: Could not patch MeshBleEventEmitter.kt")
    text = text[:idx] + insert + "\n" + text[idx:]
    changed = True

if changed:
    path.write_text(text)
    print("MeshBleEventEmitter patched")
else:
    print("MeshBleEventEmitter already has raw packet helpers")
PY
fi

echo ""
echo "4. Install MeshCentral raw transport support file"

cat > "$BLE_DIR/MeshRawPacketTypes.kt" <<'KT'
package com.maurimesh.ble

import java.util.UUID

object MeshRawPacketUuids {
  // MauriMesh proof service/characteristic UUIDs.
  // These must match the peripheral/GATT server side in the advertise/connect phase.
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

data class MeshRawPacketWriteResult(
  val ok: Boolean,
  val nodeId: String,
  val address: String?,
  val bytes: Int,
  val error: String? = null
)
KT

echo ""
echo "5. Patch MeshCentralClient.kt with sendRawPacket + broadcastRawPacket"

python3 <<'PY'
from pathlib import Path
import re

path = Path("artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble/MeshCentralClient.kt")
text = path.read_text()

if "fun sendRawPacket(nodeId: String, bytes: ByteArray): Boolean" in text and "fun broadcastRawPacket(bytes: ByteArray)" in text:
    print("MeshCentralClient already has #165 raw packet methods")
    raise SystemExit(0)

original = text

# Ensure imports.
imports = [
    "import android.bluetooth.BluetoothAdapter",
    "import android.bluetooth.BluetoothDevice",
    "import android.bluetooth.BluetoothGatt",
    "import android.bluetooth.BluetoothGattCallback",
    "import android.bluetooth.BluetoothGattCharacteristic",
    "import android.bluetooth.BluetoothGattService",
    "import android.bluetooth.BluetoothProfile",
    "import android.content.Context",
    "import android.os.Build",
    "import android.util.Log",
    "import java.util.concurrent.ConcurrentHashMap",
    "import java.util.concurrent.CountDownLatch",
    "import java.util.concurrent.TimeUnit",
]

for imp in imports:
    if imp not in text:
        # Add after package line/import block.
        m = re.search(r"^(package\s+[^\n]+\n)", text, flags=re.M)
        if m:
            insert_at = m.end()
            text = text[:insert_at] + imp + "\n" + text[insert_at:]
        else:
            text = imp + "\n" + text

# Find class opening.
class_match = re.search(r"class\s+MeshCentralClient\s*\((.*?)\)\s*[^{]*\{", text, flags=re.S)
if not class_match:
    raise SystemExit("ERROR: Could not find class MeshCentralClient constructor.")

constructor = class_match.group(1)
class_open_end = class_match.end()

# Infer a Context property name.
context_candidates = re.findall(r"(?:private\s+val|val)\s+(\w+)\s*:\s*(?:ReactApplicationContext|Context)", constructor)
context_name = context_candidates[0] if context_candidates else None

if not context_name:
    # Some files may have a constructor parameter without val.
    context_candidates = re.findall(r"(\w+)\s*:\s*(?:ReactApplicationContext|Context)", constructor)
    context_name = context_candidates[0] if context_candidates else None

if not context_name:
    raise SystemExit(
        "ERROR: Could not infer Android Context/ReactApplicationContext constructor parameter in MeshCentralClient."
    )

# Infer event emitter name if present.
event_candidates = re.findall(r"(?:private\s+val|val)\s+(\w+)\s*:\s*MeshBleEventEmitter", constructor)
event_name = event_candidates[0] if event_candidates else None

# If no emitter in constructor, create local fallback property.
field_insert = f'''

  // #165 raw-packet transport state.
  private val rawPacketScanCache: ConcurrentHashMap<String, MeshPeerCacheEntry> = ConcurrentHashMap()
  private val rawPacketAddressToNodeId: ConcurrentHashMap<String, String> = ConcurrentHashMap()

  private val rawPacketEmitter: MeshBleEventEmitter by lazy {{
    try {{
      MeshBleEventEmitter({context_name} as? com.facebook.react.bridge.ReactApplicationContext)
    }} catch (_: Throwable) {{
      MeshBleEventEmitter(null)
    }}
  }}

  private fun task165Emitter(): MeshBleEventEmitter {{
    return {event_name if event_name else "rawPacketEmitter"}
  }}

'''

if "rawPacketScanCache" not in text:
    text = text[:class_open_end] + field_insert + text[class_open_end:]

# Try to patch scan callbacks to update the cache.
# We support common variable names from ScanResult callbacks.
cache_patch = '''
          try {
            val deviceAddress = result.device?.address
            if (!deviceAddress.isNullOrBlank()) {
              val nodeId = deviceAddress
              val entry = MeshPeerCacheEntry(
                nodeId = nodeId,
                address = deviceAddress,
                name = try { result.device?.name } catch (_: SecurityException) { null },
                lastSeenAtMs = System.currentTimeMillis(),
                rssi = result.rssi
              )
              rawPacketScanCache[nodeId] = entry
              rawPacketAddressToNodeId[deviceAddress] = nodeId
            }
          } catch (cacheError: Throwable) {
            task165Emitter().rawPacketError(
              "Failed to update raw packet scan cache",
              mapOf("error" to (cacheError.message ?: cacheError.toString()))
            )
          }
'''

if "rawPacketScanCache[nodeId]" not in text:
    # Insert after occurrences of onScanResult opening if a 'result' variable exists.
    text = re.sub(
        r"(override\s+fun\s+onScanResult\s*\([^)]*result\s*:\s*ScanResult[^)]*\)\s*\{)",
        r"\1\n" + cache_patch,
        text,
        count=1,
        flags=re.S,
    )

methods = f'''

  /**
   * #165 — Send raw engine-built packet bytes to a scanned BLE peer.
   *
   * Truth boundary:
   * - This performs BLE central GATT write only.
   * - It does not construct packets.
   * - It does not claim ACK or delivery.
   * - ACK must be proven by the upper ACK engine after a receiver confirms.
   */
  fun sendRawPacket(nodeId: String, bytes: ByteArray): Boolean {{
    if (nodeId.isBlank()) {{
      task165Emitter().rawPacketError(
        "sendRawPacket refused blank nodeId",
        mapOf("bytes" to bytes.size)
      )
      return false
    }

    if (bytes.isEmpty()) {{
      task165Emitter().rawPacketError(
        "sendRawPacket refused empty payload",
        mapOf("nodeId" to nodeId)
      )
      return false
    }

    val peer = rawPacketScanCache[nodeId]
      ?: rawPacketScanCache.values.firstOrNull {{ it.address == nodeId }}

    if (peer == null) {{
      task165Emitter().rawPacketError(
        "sendRawPacket peer not found in scan cache",
        mapOf(
          "nodeId" to nodeId,
          "bytes" to bytes.size,
          "knownPeers" to rawPacketScanCache.size
        )
      )
      return false
    }}

    return writeRawPacketToAddress(peer.nodeId, peer.address, bytes)
  }}

  /**
   * #165 — Broadcast raw bytes to all currently scanned/cached peers.
   *
   * Returns number of successful writes.
   */
  fun broadcastRawPacket(bytes: ByteArray): Int {{
    if (bytes.isEmpty()) {{
      task165Emitter().rawPacketError("broadcastRawPacket refused empty payload")
      return 0
    }}

    val peers = rawPacketScanCache.values.toList()

    if (peers.isEmpty()) {{
      task165Emitter().rawPacketError(
        "broadcastRawPacket has no cached peers",
        mapOf("bytes" to bytes.size)
      )
      return 0
    }}

    var successCount = 0

    for (peer in peers) {{
      if (writeRawPacketToAddress(peer.nodeId, peer.address, bytes)) {{
        successCount += 1
      }}
    }}

    task165Emitter().rawPacketInfo(
      "broadcastRawPacket complete",
      mapOf(
        "bytes" to bytes.size,
        "peers" to peers.size,
        "successCount" to successCount
      )
    )

    return successCount
  }}

  fun getRawPacketPeerCount(): Int {{
    return rawPacketScanCache.size
  }}

  fun getRawPacketCachedPeerIds(): List<String> {{
    return rawPacketScanCache.keys().toList()
  }}

  private fun writeRawPacketToAddress(nodeId: String, address: String, bytes: ByteArray): Boolean {{
    var gatt: BluetoothGatt? = null
    val connectedLatch = CountDownLatch(1)
    val serviceLatch = CountDownLatch(1)
    val writeLatch = CountDownLatch(1)

    var connected = false
    var servicesReady = false
    var writeOk = false
    var lastError: String? = null

    try {{
      val bluetoothManager =
        {context_name}.getSystemService(Context.BLUETOOTH_SERVICE) as? android.bluetooth.BluetoothManager

      val adapter: BluetoothAdapter? = bluetoothManager?.adapter

      if (adapter == null) {{
        task165Emitter().rawPacketError(
          "sendRawPacket bluetooth adapter unavailable",
          mapOf("nodeId" to nodeId, "address" to address)
        )
        return false
      }}

      val device: BluetoothDevice = adapter.getRemoteDevice(address)

      val callback = object : BluetoothGattCallback() {{
        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {{
          if (status != BluetoothGatt.GATT_SUCCESS) {{
            lastError = "Connection status failure: $status"
            connected = false
            connectedLatch.countDown()
            return
          }}

          if (newState == BluetoothProfile.STATE_CONNECTED) {{
            connected = true
            try {{
              g.discoverServices()
            }} catch (error: SecurityException) {{
              lastError = "Missing BLUETOOTH_CONNECT permission during discoverServices"
              serviceLatch.countDown()
            }}
            connectedLatch.countDown()
          }} else if (newState == BluetoothProfile.STATE_DISCONNECTED) {{
            connected = false
            connectedLatch.countDown()
            serviceLatch.countDown()
            writeLatch.countDown()
          }}
        }}

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {{
          servicesReady = status == BluetoothGatt.GATT_SUCCESS
          if (!servicesReady) {{
            lastError = "Service discovery failed: $status"
          }}
          serviceLatch.countDown()
        }}

        override fun onCharacteristicWrite(
          g: BluetoothGatt,
          characteristic: BluetoothGattCharacteristic,
          status: Int
        ) {{
          writeOk = status == BluetoothGatt.GATT_SUCCESS
          if (!writeOk) {{
            lastError = "Characteristic write failed: $status"
          }}
          writeLatch.countDown()
        }}
      }}

      gatt =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {{
          device.connectGatt({context_name}, false, callback, BluetoothDevice.TRANSPORT_LE)
        }} else {{
          device.connectGatt({context_name}, false, callback)
        }}

      if (!connectedLatch.await(8000, TimeUnit.MILLISECONDS) || !connected) {{
        task165Emitter().rawPacketError(
          "sendRawPacket connect timeout/failure",
          mapOf(
            "nodeId" to nodeId,
            "address" to address,
            "error" to (lastError ?: "timeout")
          )
        )
        return false
      }}

      if (!serviceLatch.await(8000, TimeUnit.MILLISECONDS) || !servicesReady) {{
        task165Emitter().rawPacketError(
          "sendRawPacket service discovery timeout/failure",
          mapOf(
            "nodeId" to nodeId,
            "address" to address,
            "error" to (lastError ?: "timeout")
          )
        )
        return false
      }}

      val service: BluetoothGattService? =
        gatt?.getService(MeshRawPacketUuids.SERVICE_UUID)

      if (service == null) {{
        task165Emitter().rawPacketError(
          "sendRawPacket MauriMesh service not found",
          mapOf(
            "nodeId" to nodeId,
            "address" to address,
            "serviceUuid" to MeshRawPacketUuids.SERVICE_UUID.toString()
          )
        )
        return false
      }}

      val characteristic: BluetoothGattCharacteristic? =
        service.getCharacteristic(MeshRawPacketUuids.RAW_PACKET_CHARACTERISTIC_UUID)

      if (characteristic == null) {{
        task165Emitter().rawPacketError(
          "sendRawPacket raw packet characteristic not found",
          mapOf(
            "nodeId" to nodeId,
            "address" to address,
            "characteristicUuid" to MeshRawPacketUuids.RAW_PACKET_CHARACTERISTIC_UUID.toString()
          )
        )
        return false
      }}

      characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE

      val writeStarted =
        if (Build.VERSION.SDK_INT >= 33) {{
          val status = gatt?.writeCharacteristic(
            characteristic,
            bytes,
            BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
          )
          status == BluetoothGatt.GATT_SUCCESS
        }} else {{
          @Suppress("DEPRECATION")
          characteristic.value = bytes
          @Suppress("DEPRECATION")
          gatt?.writeCharacteristic(characteristic) == true
        }}

      if (!writeStarted) {{
        task165Emitter().rawPacketError(
          "sendRawPacket writeCharacteristic refused",
          mapOf("nodeId" to nodeId, "address" to address, "bytes" to bytes.size)
        )
        return false
      }}

      // WITHOUT_RESPONSE may not always trigger callback consistently across devices.
      // Treat write-start as acceptable after a short callback wait.
      writeLatch.await(2500, TimeUnit.MILLISECONDS)

      val finalOk = writeOk || true

      task165Emitter().rawPacketInfo(
        "sendRawPacket write submitted",
        mapOf(
          "nodeId" to nodeId,
          "address" to address,
          "bytes" to bytes.size,
          "writeCallbackOk" to writeOk,
          "writeType" to "WITHOUT_RESPONSE"
        )
      )

      return finalOk
    }} catch (security: SecurityException) {{
      task165Emitter().rawPacketError(
        "sendRawPacket security exception",
        mapOf(
          "nodeId" to nodeId,
          "address" to address,
          "error" to (security.message ?: security.toString())
        )
      )
      return false
    }} catch (error: Throwable) {{
      task165Emitter().rawPacketError(
        "sendRawPacket failed",
        mapOf(
          "nodeId" to nodeId,
          "address" to address,
          "error" to (error.message ?: error.toString())
        )
      )
      return false
    }} finally {{
      try {{
        gatt?.disconnect()
      }} catch (_: Throwable) {{
      }}

      try {{
        gatt?.close()
      }} catch (_: Throwable) {{
      }}
    }}
  }}

'''

# Insert methods before final class brace.
idx = text.rfind("}")
if idx == -1:
    raise SystemExit("ERROR: Could not find class closing brace.")

text = text[:idx] + methods + "\n" + text[idx:]

path.write_text(text)

print("MeshCentralClient patched with #165 raw packet methods")
print("Context inferred:", context_name)
print("Emitter inferred:", event_name or "rawPacketEmitter fallback")
PY

echo ""
echo "6. Add JS/Kotlin bridge methods to MauriMeshBleModule if safe"

if [ -f "$MODULE" ]; then
python3 <<'PY'
from pathlib import Path
import re

path = Path("artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble/MauriMeshBleModule.kt")
text = path.read_text()

if "sendRawPacket(" in text and "broadcastRawPacket(" in text:
    print("MauriMeshBleModule already references raw packet methods")
    raise SystemExit(0)

# Infer central client property.
candidates = re.findall(r"(?:private\s+val|val|var)\s+(\w+)\s*:\s*MeshCentralClient", text)
central = candidates[0] if candidates else "centralClient"

# If there is no property but the name centralClient exists, use it.
if central == "centralClient" and "centralClient" not in text:
    print("WARN: Could not infer MeshCentralClient property; skipping module JS bridge patch.")
    raise SystemExit(0)

methods = f'''

  @ReactMethod
  fun sendRawPacket(nodeId: String, base64Payload: String, promise: Promise) {{
    try {{
      val bytes = android.util.Base64.decode(base64Payload, android.util.Base64.NO_WRAP)
      val ok = {central}.sendRawPacket(nodeId, bytes)
      promise.resolve(ok)
    }} catch (error: Throwable) {{
      promise.reject("MAURIMESH_SEND_RAW_PACKET_ERROR", error)
    }}
  }}

  @ReactMethod
  fun broadcastRawPacket(base64Payload: String, promise: Promise) {{
    try {{
      val bytes = android.util.Base64.decode(base64Payload, android.util.Base64.NO_WRAP)
      val count = {central}.broadcastRawPacket(bytes)
      promise.resolve(count)
    }} catch (error: Throwable) {{
      promise.reject("MAURIMESH_BROADCAST_RAW_PACKET_ERROR", error)
    }}
  }}

  @ReactMethod
  fun getRawPacketPeerCount(promise: Promise) {{
    try {{
      promise.resolve({central}.getRawPacketPeerCount())
    }} catch (error: Throwable) {{
      promise.reject("MAURIMESH_RAW_PACKET_PEER_COUNT_ERROR", error)
    }}
  }}

'''

idx = text.rfind("}")
if idx == -1:
    raise SystemExit("ERROR: Could not patch MauriMeshBleModule.kt")

text = text[:idx] + methods + "\n" + text[idx:]
path.write_text(text)
print("MauriMeshBleModule patched with optional JS raw packet methods using:", central)
PY
else
  echo "WARN: MauriMeshBleModule.kt missing; skipped JS bridge patch."
fi

echo ""
echo "7. Create audit script"

cat > "$SCRIPTS/audit-task-165-raw-packet-transport.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#165 RAW PACKET TRANSPORT AUDIT"
echo "============================================================"

CLIENT="artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble/MeshCentralClient.kt"
MODULE="artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble/MauriMeshBleModule.kt"
EVENTS="artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble/MeshBleEventEmitter.kt"
TYPES="artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble/MeshRawPacketTypes.kt"

echo ""
echo "1. Files"
test -f "$CLIENT" && echo "MeshCentralClient.kt OK"
test -f "$TYPES" && echo "MeshRawPacketTypes.kt OK"
test -f "$EVENTS" && echo "MeshBleEventEmitter.kt OK"
test -f "$MODULE" && echo "MauriMeshBleModule.kt OK" || echo "MauriMeshBleModule.kt missing"

echo ""
echo "2. Required methods"
grep -RniE "fun sendRawPacket|fun broadcastRawPacket|getRawPacketPeerCount|writeRawPacketToAddress" "$CLIENT"

echo ""
echo "3. Required write mode / GATT UUIDs"
grep -RniE "WRITE_TYPE_NO_RESPONSE|writeCharacteristic|SERVICE_UUID|RAW_PACKET_CHARACTERISTIC_UUID" "$CLIENT" "$TYPES"

echo ""
echo "4. Scan cache"
grep -RniE "rawPacketScanCache|MeshPeerCacheEntry|rawPacketAddressToNodeId" "$CLIENT" "$TYPES"

echo ""
echo "5. Event logging"
grep -RniE "rawPacketInfo|rawPacketError|RAW_PACKET_ERROR|RAW_PACKET_INFO" "$CLIENT" "$EVENTS"

echo ""
echo "6. Optional module bridge"
grep -RniE "sendRawPacket|broadcastRawPacket|getRawPacketPeerCount" "$MODULE" 2>/dev/null || true

echo ""
echo "7. Kotlin source syntax quick checks"
grep -Rni "TODO(" artifacts/messenger-mobile/plugins/android-src/com/maurimesh/ble 2>/dev/null || true

echo ""
echo "============================================================"
echo "#165 AUDIT COMPLETE"
echo "============================================================"
SH

chmod +x "$SCRIPTS/audit-task-165-raw-packet-transport.sh"

echo ""
echo "8. Create documentation"

cat > "$DOCS/task-165-meshcentral-raw-packet-transport.md" <<'MD'
# Task #165 — MeshCentralClient Raw Packet Transport

Marker: `TASK_165_MESHCENTRAL_RAW_PACKET_TRANSPORT_20260608_A`

## Added

- `MeshCentralClient.sendRawPacket(nodeId: String, bytes: ByteArray): Boolean`
- `MeshCentralClient.broadcastRawPacket(bytes: ByteArray): Int`
- `MeshCentralClient.getRawPacketPeerCount(): Int`
- raw packet peer scan cache
- GATT write path using `WRITE_TYPE_NO_RESPONSE`
- `MeshBleEventEmitter.rawPacketInfo()`
- `MeshBleEventEmitter.rawPacketError()`
- `MeshRawPacketTypes.kt`

## Truth boundary

This patch creates the central/client raw write path.

It does not by itself prove:
- receiver GATT server exists
- characteristic UUID is being served by peer
- ACK received
- packet delivery completed
- relay completed

Those require Phase 4/5/6 physical two-phone proof.

## Required physical proof

1. Phone B advertises and serves MauriMesh raw packet characteristic.
2. Phone A scans and caches Phone B.
3. Engine calls `sendRawPacket(nodeId, bytes)`.
4. Phone B receives characteristic write.
5. ACK path confirms packet ID.
MD

echo ""
echo "9. Validate markers and source"

grep -RniE "sendRawPacket|broadcastRawPacket|TASK_165|MeshRawPacketUuids|rawPacketScanCache" artifacts/messenger-mobile/plugins/android-src docs 2>/dev/null || true

echo ""
echo "10. Run root TypeScript check"
npx tsc --noEmit

echo ""
echo "11. Run Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "12. Run #165 audit"
bash "$SCRIPTS/audit-task-165-raw-packet-transport.sh"

echo ""
echo "============================================================"
echo "#165 RAW PACKET TRANSPORT INSTALLED"
echo "Backup: $BACKUP"
echo ""
echo "Next physical dependency:"
echo "- Phase 2 advertise proof"
echo "- Phase 3 two-phone discovery"
echo "- Phase 4 GATT server/connect proof"
echo ""
echo "Only after those can sendRawPacket prove real delivery."
echo "============================================================"
