#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#165 — ADAPTIVE MeshCentralClient RAW PACKET TRANSPORT"
echo "Adds sendRawPacket() + broadcastRawPacket() to the real file path"
echo "NO fake file creation if MeshCentralClient is missing"
echo "NO deletion"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-165-adaptive-$STAMP"
DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"

mkdir -p "$BACKUP" "$DOCS" "$SCRIPTS"

echo ""
echo "1. Locate MeshCentralClient.kt"

CLIENT="$(find . -type f -name "MeshCentralClient.kt" \
  -not -path "./node_modules/*" \
  -not -path "./dist/*" \
  -not -path "./.git/*" \
  | head -1 || true)"

if [ -z "$CLIENT" ]; then
  echo "ERROR: MeshCentralClient.kt was not found in this workspace."
  echo ""
  echo "Run this and send the output back:"
  echo "find . -type f \\( -name '*Central*.kt' -o -name '*Ble*.kt' -o -name '*Gatt*.kt' -o -name 'MauriMeshBleModule.kt' \\) -not -path './node_modules/*' | sort"
  exit 1
fi

BLE_DIR="$(dirname "$CLIENT")"
MODULE="$(find "$BLE_DIR" -maxdepth 1 -type f -name "MauriMeshBleModule.kt" | head -1 || true)"
EVENTS="$(find "$BLE_DIR" -maxdepth 1 -type f -name "MeshBleEventEmitter.kt" | head -1 || true)"
TYPES="$BLE_DIR/MeshRawPacketTypes.kt"

echo "Found client: $CLIENT"
echo "BLE dir: $BLE_DIR"
echo "Module: ${MODULE:-not found}"
echo "Emitter: ${EVENTS:-not found}"

echo ""
echo "2. Backup BLE directory"
cp -R "$BLE_DIR" "$BACKUP/ble-dir"
echo "Backup: $BACKUP"

echo ""
echo "3. Install raw packet UUID/types"

cat > "$TYPES" <<'KT'
package com.maurimesh.ble

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
echo "4. Patch MeshBleEventEmitter if present"

if [ -n "${EVENTS:-}" ] && [ -f "$EVENTS" ]; then
python3 <<PY
from pathlib import Path

path = Path("$EVENTS")
text = path.read_text()
original = text

if "fun rawPacketInfo(" not in text:
    insert = '''
  fun rawPacketInfo(message: String, data: Map<String, Any?> = emptyMap()) {
    try {
      emit("RAW_PACKET_INFO", message, data)
    } catch (_: Throwable) {
      android.util.Log.i("MauriMeshBle", "[RAW_PACKET_INFO] $message $data")
    }
  }

  fun rawPacketError(message: String, data: Map<String, Any?> = emptyMap()) {
    try {
      emit("RAW_PACKET_ERROR", message, data)
    } catch (_: Throwable) {
      android.util.Log.e("MauriMeshBle", "[RAW_PACKET_ERROR] $message $data")
    }
  }
'''
    idx = text.rfind("}")
    if idx == -1:
        raise SystemExit("ERROR: Could not patch MeshBleEventEmitter.kt")
    text = text[:idx] + insert + "\n" + text[idx:]

if text != original:
    path.write_text(text)
    print("Emitter patched")
else:
    print("Emitter already patched")
PY
else
  echo "WARN: MeshBleEventEmitter.kt not found. MeshCentralClient will use Log fallback."
fi

echo ""
echo "5. Patch MeshCentralClient.kt"

python3 <<PY
from pathlib import Path
import re

path = Path("$CLIENT")
text = path.read_text()
original = text

if "fun sendRawPacket(nodeId: String, bytes: ByteArray): Boolean" in text and "fun broadcastRawPacket(bytes: ByteArray)" in text:
    print("MeshCentralClient already has #165 methods")
    raise SystemExit(0)

# Package must remain the original one.
package_match = re.search(r"^package\\s+([^\\n]+)", text, re.M)
pkg = package_match.group(1).strip() if package_match else "com.maurimesh.ble"

required_imports = [
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

for imp in required_imports:
    if imp not in text:
        m = re.search(r"^(package\\s+[^\\n]+\\n)", text, re.M)
        if m:
            text = text[:m.end()] + imp + "\\n" + text[m.end():]
        else:
            text = imp + "\\n" + text

class_match = re.search(r"class\\s+MeshCentralClient\\s*\\((.*?)\\)\\s*[^\\{]*\\{", text, re.S)
if not class_match:
    raise SystemExit("ERROR: Could not find class MeshCentralClient constructor.")

constructor = class_match.group(1)
class_open_end = class_match.end()

context_candidates = re.findall(r"(?:private\\s+val|val|var)\\s+(\\w+)\\s*:\\s*(?:ReactApplicationContext|Context)", constructor)
if not context_candidates:
    context_candidates = re.findall(r"(\\w+)\\s*:\\s*(?:ReactApplicationContext|Context)", constructor)

if not context_candidates:
    raise SystemExit("ERROR: Could not infer Android Context parameter in MeshCentralClient constructor.")

context_name = context_candidates[0]

event_candidates = re.findall(r"(?:private\\s+val|val|var)\\s+(\\w+)\\s*:\\s*MeshBleEventEmitter", constructor)
event_name = event_candidates[0] if event_candidates else None

fields = f'''

  // TASK_165_MESHCENTRAL_RAW_PACKET_TRANSPORT_20260608_A
  private val rawPacketScanCache: ConcurrentHashMap<String, MeshPeerCacheEntry> = ConcurrentHashMap()
  private val rawPacketAddressToNodeId: ConcurrentHashMap<String, String> = ConcurrentHashMap()

  private fun task165RawInfo(message: String, data: Map<String, Any?> = emptyMap()) {{
    try {{
      {"%s.rawPacketInfo(message, data)" % event_name if event_name else 'Log.i("MauriMeshBle", "[RAW_PACKET_INFO] $message $data")'}
    }} catch (_: Throwable) {{
      Log.i("MauriMeshBle", "[RAW_PACKET_INFO] $message $data")
    }}
  }}

  private fun task165RawError(message: String, data: Map<String, Any?> = emptyMap()) {{
    try {{
      {"%s.rawPacketError(message, data)" % event_name if event_name else 'Log.e("MauriMeshBle", "[RAW_PACKET_ERROR] $message $data")'}
    }} catch (_: Throwable) {{
      Log.e("MauriMeshBle", "[RAW_PACKET_ERROR] $message $data")
    }}
  }}

  private fun task165CachePeerFromScan(device: BluetoothDevice?, rssi: Int?) {{
    try {{
      val address = device?.address ?: return
      val name = try {{ device.name }} catch (_: SecurityException) {{ null }}
      val nodeId = address
      val entry = MeshPeerCacheEntry(
        nodeId = nodeId,
        address = address,
        name = name,
        lastSeenAtMs = System.currentTimeMillis(),
        rssi = rssi
      )
      rawPacketScanCache[nodeId] = entry
      rawPacketAddressToNodeId[address] = nodeId
    }} catch (error: Throwable) {{
      task165RawError(
        "Failed to cache scanned BLE peer",
        mapOf("error" to (error.message ?: error.toString()))
      )
    }}
  }}

'''

if "TASK_165_MESHCENTRAL_RAW_PACKET_TRANSPORT_20260608_A" not in text:
    text = text[:class_open_end] + fields + text[class_open_end:]

# Patch onScanResult if ScanResult callback exists.
if "task165CachePeerFromScan(result.device" not in text:
    text = re.sub(
        r"(override\\s+fun\\s+onScanResult\\s*\\([^)]*result\\s*:\\s*ScanResult[^)]*\\)\\s*\\{)",
        r"\\1\\n          task165CachePeerFromScan(result.device, result.rssi)",
        text,
        count=1,
        flags=re.S,
    )

# Patch onBatchScanResults if present.
if "task165CachePeerFromScan(scanResult.device" not in text:
    text = re.sub(
        r"(override\\s+fun\\s+onBatchScanResults\\s*\\([^)]*results\\s*:\\s*MutableList<ScanResult>[^)]*\\)\\s*\\{)",
        r"\\1\\n          for (scanResult in results) { task165CachePeerFromScan(scanResult.device, scanResult.rssi) }",
        text,
        count=1,
        flags=re.S,
    )

methods = f'''

  /**
   * #165 — Send raw engine-built packet bytes to a scanned BLE peer.
   *
   * Truth boundary:
   * - This submits a BLE GATT write using WRITE_TYPE_NO_RESPONSE.
   * - It does not prove packet delivery or ACK by itself.
   */
  fun sendRawPacket(nodeId: String, bytes: ByteArray): Boolean {{
    if (nodeId.isBlank()) {{
      task165RawError("sendRawPacket refused blank nodeId", mapOf("bytes" to bytes.size))
      return false
    }}

    if (bytes.isEmpty()) {{
      task165RawError("sendRawPacket refused empty payload", mapOf("nodeId" to nodeId))
      return false
    }}

    val peer = rawPacketScanCache[nodeId]
      ?: rawPacketScanCache.values.firstOrNull {{ it.address == nodeId }}

    if (peer == null) {{
      task165RawError(
        "sendRawPacket peer not found in scan cache",
        mapOf(
          "nodeId" to nodeId,
          "bytes" to bytes.size,
          "knownPeers" to rawPacketScanCache.size
        )
      )
      return false
    }}

    return writeRawPacketToPeer(peer, bytes)
  }}

  /**
   * #165 — Broadcast raw bytes to every currently cached scanned peer.
   *
   * Returns number of successful write submissions.
   */
  fun broadcastRawPacket(bytes: ByteArray): Int {{
    if (bytes.isEmpty()) {{
      task165RawError("broadcastRawPacket refused empty payload")
      return 0
    }}

    val peers = rawPacketScanCache.values.toList()

    if (peers.isEmpty()) {{
      task165RawError(
        "broadcastRawPacket has no cached peers",
        mapOf("bytes" to bytes.size)
      )
      return 0
    }}

    var successCount = 0

    for (peer in peers) {{
      if (sendRawPacket(peer.nodeId, bytes)) {{
        successCount += 1
      }}
    }}

    task165RawInfo(
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

  private fun writeRawPacketToPeer(peer: MeshPeerCacheEntry, bytes: ByteArray): Boolean {{
    var gatt: BluetoothGatt? = null
    val connectedLatch = CountDownLatch(1)
    val servicesLatch = CountDownLatch(1)
    val writeLatch = CountDownLatch(1)

    var connected = false
    var servicesReady = false
    var writeCallbackSeen = false
    var writeCallbackOk = false
    var lastError: String? = null

    try {{
      val bluetoothManager =
        {context_name}.getSystemService(Context.BLUETOOTH_SERVICE) as? android.bluetooth.BluetoothManager

      val adapter: BluetoothAdapter? = bluetoothManager?.adapter

      if (adapter == null) {{
        task165RawError(
          "Bluetooth adapter unavailable",
          mapOf("nodeId" to peer.nodeId, "address" to peer.address)
        )
        return false
      }}

      val device = adapter.getRemoteDevice(peer.address)

      val callback = object : BluetoothGattCallback() {{
        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {{
          if (status != BluetoothGatt.GATT_SUCCESS) {{
            lastError = "GATT connection status failure: $status"
            connectedLatch.countDown()
            servicesLatch.countDown()
            writeLatch.countDown()
            return
          }}

          if (newState == BluetoothProfile.STATE_CONNECTED) {{
            connected = true
            connectedLatch.countDown()
            try {{
              g.discoverServices()
            }} catch (error: SecurityException) {{
              lastError = "Missing BLUETOOTH_CONNECT during discoverServices"
              servicesLatch.countDown()
            }}
          }}

          if (newState == BluetoothProfile.STATE_DISCONNECTED) {{
            connected = false
            connectedLatch.countDown()
            servicesLatch.countDown()
            writeLatch.countDown()
          }}
        }}

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {{
          servicesReady = status == BluetoothGatt.GATT_SUCCESS
          if (!servicesReady) {{
            lastError = "Service discovery failed: $status"
          }}
          servicesLatch.countDown()
        }}

        override fun onCharacteristicWrite(
          g: BluetoothGatt,
          characteristic: BluetoothGattCharacteristic,
          status: Int
        ) {{
          writeCallbackSeen = true
          writeCallbackOk = status == BluetoothGatt.GATT_SUCCESS
          if (!writeCallbackOk) {{
            lastError = "Characteristic write failed: $status"
          }}
          writeLatch.countDown()
        }}
      }}

      gatt =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {{
          device.connectGatt({context_name}, false, callback, BluetoothDevice.TRANSPORT_LE)
        }} else {{
          @Suppress("DEPRECATION")
          device.connectGatt({context_name}, false, callback)
        }}

      if (!connectedLatch.await(8000, TimeUnit.MILLISECONDS) || !connected) {{
        task165RawError(
          "sendRawPacket connect timeout/failure",
          mapOf(
            "nodeId" to peer.nodeId,
            "address" to peer.address,
            "error" to (lastError ?: "connect_timeout")
          )
        )
        return false
      }}

      if (!servicesLatch.await(8000, TimeUnit.MILLISECONDS) || !servicesReady) {{
        task165RawError(
          "sendRawPacket service discovery timeout/failure",
          mapOf(
            "nodeId" to peer.nodeId,
            "address" to peer.address,
            "error" to (lastError ?: "service_timeout")
          )
        )
        return false
      }}

      val service: BluetoothGattService? = gatt?.getService(MeshRawPacketUuids.SERVICE_UUID)

      if (service == null) {{
        task165RawError(
          "MauriMesh raw packet service not found",
          mapOf(
            "nodeId" to peer.nodeId,
            "address" to peer.address,
            "serviceUuid" to MeshRawPacketUuids.SERVICE_UUID.toString()
          )
        )
        return false
      }}

      val characteristic =
        service.getCharacteristic(MeshRawPacketUuids.RAW_PACKET_CHARACTERISTIC_UUID)

      if (characteristic == null) {{
        task165RawError(
          "MauriMesh raw packet characteristic not found",
          mapOf(
            "nodeId" to peer.nodeId,
            "address" to peer.address,
            "characteristicUuid" to MeshRawPacketUuids.RAW_PACKET_CHARACTERISTIC_UUID.toString()
          )
        )
        return false
      }}

      characteristic.writeType = BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE

      val writeSubmitted =
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

      if (!writeSubmitted) {{
        task165RawError(
          "sendRawPacket writeCharacteristic refused",
          mapOf("nodeId" to peer.nodeId, "address" to peer.address, "bytes" to bytes.size)
        )
        return false
      }}

      writeLatch.await(2500, TimeUnit.MILLISECONDS)

      if (writeCallbackSeen && !writeCallbackOk) {{
        task165RawError(
          "sendRawPacket write callback failed",
          mapOf(
            "nodeId" to peer.nodeId,
            "address" to peer.address,
            "bytes" to bytes.size,
            "error" to (lastError ?: "write_callback_failed")
          )
        )
        return false
      }}

      task165RawInfo(
        "sendRawPacket write submitted",
        mapOf(
          "nodeId" to peer.nodeId,
          "address" to peer.address,
          "bytes" to bytes.size,
          "writeType" to "WITHOUT_RESPONSE",
          "writeCallbackSeen" to writeCallbackSeen,
          "writeCallbackOk" to writeCallbackOk
        )
      )

      return true
    }} catch (security: SecurityException) {{
      task165RawError(
        "sendRawPacket security exception",
        mapOf(
          "nodeId" to peer.nodeId,
          "address" to peer.address,
          "error" to (security.message ?: security.toString())
        )
      )
      return false
    }} catch (error: Throwable) {{
      task165RawError(
        "sendRawPacket failed",
        mapOf(
          "nodeId" to peer.nodeId,
          "address" to peer.address,
          "error" to (error.message ?: error.toString())
        )
      )
      return false
    }} finally {{
      try {{ gatt?.disconnect() }} catch (_: Throwable) {{}}
      try {{ gatt?.close() }} catch (_: Throwable) {{}}
    }}
  }}

'''

idx = text.rfind("}")
if idx == -1:
    raise SystemExit("ERROR: Could not find class closing brace in MeshCentralClient.kt")

text = text[:idx] + methods + "\n" + text[idx:]

if text != original:
    path.write_text(text)
    print("Patched MeshCentralClient.kt")
    print("Context:", context_name)
    print("Emitter:", event_name or "Log fallback")
else:
    print("No changes written")
PY

echo ""
echo "6. Patch MauriMeshBleModule.kt bridge if present"

if [ -n "${MODULE:-}" ] && [ -f "$MODULE" ]; then
python3 <<PY
from pathlib import Path
import re

path = Path("$MODULE")
text = path.read_text()
original = text

if "fun sendRawPacket(nodeId: String" in text and "fun broadcastRawPacket(base64Payload" in text:
    print("MauriMeshBleModule already has raw packet bridge methods")
    raise SystemExit(0)

# Ensure imports.
imports = [
    "import com.facebook.react.bridge.Promise",
    "import com.facebook.react.bridge.ReactMethod",
]
for imp in imports:
    if imp not in text:
        m = re.search(r"^(package\\s+[^\\n]+\\n)", text, re.M)
        if m:
            text = text[:m.end()] + imp + "\\n" + text[m.end():]

candidates = re.findall(r"(?:private\\s+val|val|var)\\s+(\\w+)\\s*:\\s*MeshCentralClient", text)
central = candidates[0] if candidates else None

if not central:
    if "centralClient" in text:
        central = "centralClient"
    else:
        print("WARN: Could not infer MeshCentralClient property in MauriMeshBleModule. Skipping module bridge patch.")
        path.write_text(text)
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
      val successCount = {central}.broadcastRawPacket(bytes)
      promise.resolve(successCount)
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
    raise SystemExit("ERROR: Could not find MauriMeshBleModule class closing brace")

text = text[:idx] + methods + "\n" + text[idx:]

if text != original:
    path.write_text(text)
    print("Patched MauriMeshBleModule.kt using central client:", central)
else:
    print("MauriMeshBleModule unchanged")
PY
else
  echo "WARN: MauriMeshBleModule.kt not found beside MeshCentralClient. Client methods still installed."
fi

echo ""
echo "7. Create JS raw packet client"

mkdir -p "$ROOT/src/maurimesh/ble"

cat > "$ROOT/src/maurimesh/ble/rawPacketClient.ts" <<'TS'
import { NativeModules, Platform } from "react-native";

export const TASK_165_RAW_PACKET_CLIENT_MARKER =
  "TASK_165_RAW_PACKET_CLIENT_20260608_A";

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
echo "8. Create audit script"

cat > "$SCRIPTS/audit-task-165-raw-packet-transport.sh" <<SH
#!/usr/bin/env bash
set -euo pipefail

CLIENT="$CLIENT"
MODULE="${MODULE:-}"

echo "============================================================"
echo "#165 Raw Packet Transport Audit"
echo "============================================================"

echo ""
echo "Client: \$CLIENT"

test -f "\$CLIENT" && echo "MeshCentralClient exists"

echo ""
echo "1. Required client methods"
grep -nE "fun sendRawPacket\\(nodeId: String, bytes: ByteArray\\): Boolean|fun broadcastRawPacket\\(bytes: ByteArray\\): Int|getRawPacketPeerCount|writeRawPacketToPeer" "\$CLIENT"

echo ""
echo "2. Required GATT write path"
grep -nE "WRITE_TYPE_NO_RESPONSE|writeCharacteristic|connectGatt|discoverServices|MeshRawPacketUuids" "\$CLIENT"

echo ""
echo "3. Scan cache"
grep -nE "rawPacketScanCache|task165CachePeerFromScan|MeshPeerCacheEntry" "\$CLIENT"

echo ""
echo "4. Error logging"
grep -nE "task165RawError|task165RawInfo|RAW_PACKET_ERROR|RAW_PACKET_INFO" "\$CLIENT" "$EVENTS" 2>/dev/null || true

echo ""
echo "5. Module bridge"
if [ -n "\$MODULE" ] && [ -f "\$MODULE" ]; then
  grep -nE "sendRawPacket|broadcastRawPacket|getRawPacketPeerCount" "\$MODULE" || true
else
  echo "Module bridge file not found"
fi

echo ""
echo "6. JS client"
grep -RniE "sendRawPacketToNode|broadcastRawPacketToPeers|getRawPacketPeerCount|TASK_165_RAW_PACKET_CLIENT" src 2>/dev/null || true

echo ""
echo "============================================================"
echo "#165 audit complete"
echo "============================================================"
SH

chmod +x "$SCRIPTS/audit-task-165-raw-packet-transport.sh"

echo ""
echo "9. Documentation"

cat > "$DOCS/task-165-meshcentral-raw-packet-transport.md" <<'MD'
# Task #165 — MeshCentralClient Raw Packet Transport

Marker: `TASK_165_MESHCENTRAL_RAW_PACKET_TRANSPORT_20260608_A`

## Added

- `MeshCentralClient.sendRawPacket(nodeId: String, bytes: ByteArray): Boolean`
- `MeshCentralClient.broadcastRawPacket(bytes: ByteArray): Int`
- `MeshCentralClient.getRawPacketPeerCount(): Int`
- peer scan cache using BLE scan results
- GATT write path using `WRITE_TYPE_NO_RESPONSE`
- error/info logging through `MeshBleEventEmitter` where available, otherwise Android Log fallback
- JS client:
  - `sendRawPacketToNode(nodeId, bytes)`
  - `broadcastRawPacketToPeers(bytes)`
  - `getRawPacketPeerCount()`

## Truth boundary

This submits raw bytes over BLE central GATT write.

It does not prove:
- receiver GATT server exists
- raw characteristic is available on the peer
- packet is received by the peer
- ACK is returned
- relay succeeds

Physical proof still requires two phones:
1. Phone B advertises and serves raw packet GATT characteristic.
2. Phone A scans and caches Phone B.
3. Phone A calls `sendRawPacket`.
4. Phone B receives the characteristic write.
5. Phone B returns ACK.
MD

echo ""
echo "10. Validate markers"

grep -RniE "TASK_165|sendRawPacket|broadcastRawPacket|MeshRawPacketUuids|rawPacketScanCache" \
  "$BLE_DIR" src docs scripts 2>/dev/null || true

echo ""
echo "11. TypeScript check"
npx tsc --noEmit

echo ""
echo "12. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "13. Run audit"
bash "$SCRIPTS/audit-task-165-raw-packet-transport.sh"

echo ""
echo "============================================================"
echo "#165 ADAPTIVE RAW PACKET TRANSPORT INSTALLED"
echo "Backup: $BACKUP"
echo ""
echo "Next physical dependency:"
echo "Phase 2 advertise proof + GATT server characteristic"
echo "Then two-phone sendRawPacket proof"
echo "============================================================"
