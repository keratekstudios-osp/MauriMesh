#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#165B — RAW PACKET RECEIVER + ACK PROOF"
echo "Adds native GATT server receiver, ACK return path, and JS proof client"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-165b-raw-receiver-$STAMP"

BASE="$ROOT/android/app/src/main/java/com/maurimesh/messenger"
MODULE="$BASE/MauriMeshBleModule.kt"
CLIENT="$BASE/MeshCentralClient.kt"
SERVER="$BASE/MeshRawPacketGattServer.kt"
TYPES="$BASE/MeshRawPacketTypes.kt"
MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"

DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"

mkdir -p "$BACKUP" "$BASE" "$DOCS" "$SCRIPTS"

echo ""
echo "1. Verify #165 base files"

if [ ! -f "$MODULE" ]; then
  echo "ERROR: Missing $MODULE"
  exit 1
fi

if [ ! -f "$CLIENT" ]; then
  echo "ERROR: Missing $CLIENT"
  echo "Run #165 active Android raw packet installer first."
  exit 1
fi

cp "$MODULE" "$BACKUP/MauriMeshBleModule.kt"
cp "$CLIENT" "$BACKUP/MeshCentralClient.kt"
cp "$TYPES" "$BACKUP/MeshRawPacketTypes.kt" 2>/dev/null || true
cp "$SERVER" "$BACKUP/MeshRawPacketGattServer.kt" 2>/dev/null || true
cp "$MANIFEST" "$BACKUP/AndroidManifest.xml" 2>/dev/null || true

echo "Backup: $BACKUP"

echo ""
echo "2. Ensure UUID/types file"

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
echo "3. Patch MeshCentralClient with direct address cache helper"

python3 <<'PY'
from pathlib import Path

path = Path("android/app/src/main/java/com/maurimesh/messenger/MeshCentralClient.kt")
text = path.read_text()

if "fun cachePeerAddress(address: String, name: String? = null, rssi: Int? = null)" not in text:
    marker = "  fun sendRawPacket(nodeId: String, bytes: ByteArray): Boolean {"
    if marker not in text:
        raise SystemExit("ERROR: Could not find sendRawPacket marker in MeshCentralClient.kt")
    helper = '''
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

'''
    text = text.replace(marker, helper + marker)

path.write_text(text)
print("MeshCentralClient cachePeerAddress ready")
PY

echo ""
echo "4. Create native GATT receiver server"

cat > "$SERVER" <<'KT'
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
KT

echo ""
echo "5. Patch MauriMeshBleModule with receiver + ACK methods"

python3 <<'PY'
from pathlib import Path
import re

path = Path("android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt")
text = path.read_text()

for imp in [
    "import com.facebook.react.bridge.Arguments",
    "import com.facebook.react.bridge.WritableMap",
    "import android.util.Base64",
]:
    if imp not in text:
        m = re.search(r"^(package\s+[^\n]+\n)", text, re.M)
        if m:
            text = text[:m.end()] + imp + "\n" + text[m.end():]

if "private var rawPacketGattServer: MeshRawPacketGattServer? = null" not in text:
    target = "private val centralClient = MeshCentralClient(reactContext)"
    if target not in text:
        class_match = re.search(r"class\s+MauriMeshBleModule\s*\([^)]*\)\s*:\s*[^{]+\{", text, re.S)
        if not class_match:
            raise SystemExit("ERROR: Could not find module class opening")
        text = text[:class_match.end()] + "\n  private val centralClient = MeshCentralClient(reactContext)\n" + text[class_match.end():]
    text = text.replace(
        "private val centralClient = MeshCentralClient(reactContext)",
        """private val centralClient = MeshCentralClient(reactContext)
  private var rawPacketGattServer: MeshRawPacketGattServer? = null
  private var rawPacketAckCount: Int = 0
  private var rawPacketLastAckTarget: String? = null
  private var rawPacketLastAckSentAtMs: Long = 0L"""
    )

if "fun startRawPacketReceiver(promise: Promise)" not in text:
    methods = '''

  // TASK_165B_RAW_PACKET_RECEIVER_BRIDGE_20260608_A
  @ReactMethod
  fun startRawPacketReceiver(promise: Promise) {
    try {
      if (rawPacketGattServer == null) {
        rawPacketGattServer = MeshRawPacketGattServer(reactContext) { event ->
          centralClient.cachePeerAddress(event.fromAddress, "ack-peer", null)

          val ackText =
            "MAURIMESH_ACK|from=${event.fromAddress}|bytes=${event.bytes.size}|at=${event.receivedAtMs}"
          val ackBytes = ackText.toByteArray(Charsets.UTF_8)

          val ackSent = centralClient.sendRawPacket(event.fromAddress, ackBytes)

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

'''
    idx = text.rfind("}")
    if idx == -1:
        raise SystemExit("ERROR: Could not find final module brace")
    text = text[:idx] + methods + "\n" + text[idx:]

path.write_text(text)
print("MauriMeshBleModule receiver bridge ready")
PY

echo ""
echo "6. Patch AndroidManifest permissions"

if [ -f "$MANIFEST" ]; then
python3 <<'PY'
from pathlib import Path

path = Path("android/app/src/main/AndroidManifest.xml")
text = path.read_text()

perms = [
    '<uses-permission android:name="android.permission.BLUETOOTH" />',
    '<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />',
    '<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />',
    '<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />',
    '<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />',
    '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
]

insert_at = text.find("<application")
if insert_at == -1:
    raise SystemExit("WARN: AndroidManifest has no <application> marker")

for perm in perms:
    name = perm.split('android:name="', 1)[1].split('"', 1)[0]
    if name not in text:
        text = text[:insert_at] + perm + "\n    " + text[insert_at:]
        insert_at = text.find("<application")

path.write_text(text)
print("AndroidManifest BLE permissions ready")
PY
else
  echo "WARN: AndroidManifest.xml not found"
fi

echo ""
echo "7. Add JS proof client"

mkdir -p "$ROOT/src/maurimesh/ble"

cat > "$ROOT/src/maurimesh/ble/rawPacketProofClient.ts" <<'TS'
import { NativeModules, Platform } from "react-native";
import { sendRawPacketToNode } from "./rawPacketClient";

export const TASK_165B_RAW_PACKET_PROOF_CLIENT_MARKER =
  "TASK_165B_RAW_PACKET_PROOF_CLIENT_20260608_A";

export type RawPacketReceiverStatus = {
  ok?: boolean;
  marker?: string;
  serverMarker?: string;
  running?: boolean;
  receivedCount?: number;
  lastFromAddress?: string | null;
  lastPacketSize?: number;
  lastReceivedAtMs?: number;
  lastError?: string | null;
  serviceUuid?: string | null;
  characteristicUuid?: string | null;
  ackCount?: number;
  lastAckTarget?: string | null;
  lastAckSentAtMs?: number;
  peerCount?: number;
};

type RawPacketReceiverNative = {
  startRawPacketReceiver?: () => Promise<RawPacketReceiverStatus>;
  stopRawPacketReceiver?: () => Promise<RawPacketReceiverStatus>;
  getRawPacketReceiverStatus?: () => Promise<RawPacketReceiverStatus>;
  sendRawPacketUtf8?: (nodeId: string, text: string) => Promise<boolean>;
};

function native(): RawPacketReceiverNative | null {
  return (NativeModules.MauriMeshBle as RawPacketReceiverNative | undefined) || null;
}

export async function startRawPacketReceiver(): Promise<RawPacketReceiverStatus> {
  if (Platform.OS !== "android") return { ok: false, lastError: "Android only" };
  const n = native();
  if (!n?.startRawPacketReceiver) {
    throw new Error("MauriMeshBle.startRawPacketReceiver unavailable");
  }
  return n.startRawPacketReceiver();
}

export async function stopRawPacketReceiver(): Promise<RawPacketReceiverStatus> {
  if (Platform.OS !== "android") return { ok: false, lastError: "Android only" };
  const n = native();
  if (!n?.stopRawPacketReceiver) {
    throw new Error("MauriMeshBle.stopRawPacketReceiver unavailable");
  }
  return n.stopRawPacketReceiver();
}

export async function getRawPacketReceiverStatus(): Promise<RawPacketReceiverStatus> {
  if (Platform.OS !== "android") return { ok: false, lastError: "Android only" };
  const n = native();
  if (!n?.getRawPacketReceiverStatus) {
    throw new Error("MauriMeshBle.getRawPacketReceiverStatus unavailable");
  }
  return n.getRawPacketReceiverStatus();
}

export async function sendRawPacketUtf8(nodeId: string, text: string): Promise<boolean> {
  if (Platform.OS !== "android") return false;
  const n = native();
  if (n?.sendRawPacketUtf8) {
    return Boolean(await n.sendRawPacketUtf8(nodeId, text));
  }

  const bytes = new TextEncoder().encode(text);
  return sendRawPacketToNode(nodeId, bytes);
}

export function makeProofPayload(label: string): string {
  return `MAURIMESH_RAW_PROOF|${label}|${Date.now()}`;
}
TS

echo ""
echo "8. Add Expo proof screen"

cat > "$ROOT/app/raw-packet-proof.tsx" <<'TSX'
import React, { useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from "react-native";
import {
  getRawPacketReceiverStatus,
  makeProofPayload,
  RawPacketReceiverStatus,
  sendRawPacketUtf8,
  startRawPacketReceiver,
  stopRawPacketReceiver,
} from "../src/maurimesh/ble/rawPacketProofClient";

const MARKER = "TASK_165B_RAW_PACKET_PROOF_SCREEN_20260608_A";

export default function RawPacketProofScreen() {
  const [target, setTarget] = useState("");
  const [status, setStatus] = useState<RawPacketReceiverStatus | null>(null);
  const [log, setLog] = useState<string[]>([]);

  const push = (line: string) => setLog((prev) => [`${new Date().toISOString()} ${line}`, ...prev].slice(0, 50));

  async function run(label: string, fn: () => Promise<any>) {
    try {
      push(`START ${label}`);
      const result = await fn();
      push(`${label}: ${JSON.stringify(result)}`);
      if (result && typeof result === "object") setStatus(result);
    } catch (error) {
      push(`${label} ERROR: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.kicker}>{MARKER}</Text>
      <Text style={styles.title}>Raw Packet Proof</Text>
      <Text style={styles.body}>
        Start receiver on both phones. Start BLE scan on both phones. Copy the target phone BLE address from scan status.
        Send proof packet. The receiver should show receivedCount increase and the sender should receive an ACK if both phones are running receiver server.
      </Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Receiver Status</Text>
        <Text style={styles.mono}>{JSON.stringify(status, null, 2)}</Text>
      </View>

      <Pressable style={styles.button} onPress={() => run("startRawPacketReceiver", startRawPacketReceiver)}>
        <Text style={styles.buttonText}>Start Raw Packet Receiver</Text>
      </Pressable>

      <Pressable style={styles.button} onPress={() => run("getRawPacketReceiverStatus", getRawPacketReceiverStatus)}>
        <Text style={styles.buttonText}>Refresh Receiver Status</Text>
      </Pressable>

      <TextInput
        value={target}
        onChangeText={setTarget}
        placeholder="Target BLE address / nodeId, e.g. AA:BB:CC:DD:EE:FF"
        placeholderTextColor="rgba(255,255,255,0.45)"
        autoCapitalize="characters"
        style={styles.input}
      />

      <Pressable
        style={styles.button}
        onPress={() =>
          run("sendRawPacketUtf8", async () => {
            const payload = makeProofPayload("PHONE_TO_PHONE");
            const ok = await sendRawPacketUtf8(target.trim(), payload);
            return { ok, target: target.trim(), payload };
          })
        }
      >
        <Text style={styles.buttonText}>Send Proof Packet</Text>
      </Pressable>

      <Pressable style={[styles.button, styles.danger]} onPress={() => run("stopRawPacketReceiver", stopRawPacketReceiver)}>
        <Text style={styles.buttonText}>Stop Receiver</Text>
      </Pressable>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Proof Log</Text>
        {log.map((line, index) => (
          <Text key={`${line}-${index}`} style={styles.logLine}>{line}</Text>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 18, gap: 14 },
  kicker: { color: "#00D084", fontWeight: "800", fontSize: 11 },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  body: { color: "rgba(255,255,255,0.75)", lineHeight: 21 },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.35)",
    backgroundColor: "rgba(255,255,255,0.06)",
    borderRadius: 18,
    padding: 14,
    gap: 8,
  },
  cardTitle: { color: "#FFFFFF", fontWeight: "900", fontSize: 16 },
  mono: { color: "#CFFFE8", fontFamily: "monospace", fontSize: 12 },
  button: {
    minHeight: 52,
    borderRadius: 16,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 14,
  },
  danger: { backgroundColor: "#EF4444" },
  buttonText: { color: "#FFFFFF", fontWeight: "900" },
  input: {
    minHeight: 52,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.35)",
    color: "#FFFFFF",
    paddingHorizontal: 14,
    backgroundColor: "rgba(255,255,255,0.06)",
  },
  logLine: { color: "rgba(255,255,255,0.72)", fontSize: 12, lineHeight: 18 },
});
TSX

echo ""
echo "9. Add logcat proof script"

cat > "$SCRIPTS/task-165b-two-phone-proof-logcat.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

PKG="${1:-com.maurimesh.messenger}"

echo "============================================================"
echo "#165B TWO-PHONE RAW PACKET PROOF LOGCAT"
echo "Package: $PKG"
echo "============================================================"

adb logcat -c || true

echo "Open Raw Packet Proof screen on both phones."
echo "Start receiver on both phones."
echo "Start BLE scan on both phones."
echo "Send proof packet from Phone A to Phone B."
echo "Watching logs for 120 seconds..."
echo ""

timeout 120 adb logcat | grep -E \
  "TASK_165B|TASK_165|RX_RAW_PACKET|RAW_PACKET_GATT_SERVER|sendRawPacket|broadcastRawPacket|ACK_SENT|MauriMeshBle" \
  || true

echo ""
echo "Done."
SH

chmod +x "$SCRIPTS/task-165b-two-phone-proof-logcat.sh"

echo ""
echo "10. Audit native + JS markers"

grep -RniE "TASK_165B|startRawPacketReceiver|stopRawPacketReceiver|getRawPacketReceiverStatus|sendRawPacketUtf8|RX_RAW_PACKET|ACK_SENT|PROPERTY_WRITE_NO_RESPONSE" \
  android/app/src/main/java/com/maurimesh/messenger src/maurimesh/ble app/raw-packet-proof.tsx scripts 2>/dev/null || true

echo ""
echo "11. TypeScript check"
npx tsc --noEmit

echo ""
echo "12. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

cat > "$DOCS/task-165b-raw-packet-receiver-proof.md" <<'MD'
# Task #165B — Raw Packet Receiver + ACK Proof

Markers:
- `TASK_165B_RAW_PACKET_GATT_SERVER_20260608_A`
- `TASK_165B_RAW_PACKET_RECEIVER_BRIDGE_20260608_A`
- `TASK_165B_RAW_PACKET_PROOF_CLIENT_20260608_A`
- `TASK_165B_RAW_PACKET_PROOF_SCREEN_20260608_A`

## Installed

- Native Android GATT server for MauriMesh raw packet service.
- Writable raw packet characteristic.
- Receiver bridge methods:
  - `startRawPacketReceiver()`
  - `stopRawPacketReceiver()`
  - `getRawPacketReceiverStatus()`
  - `sendRawPacketUtf8(nodeId, text)`
- ACK attempt: receiver sends ACK payload back to sender address through `MeshCentralClient.sendRawPacket`.
- Raw Packet Proof screen.
- Logcat proof helper.

## Two-phone proof rule

To mark real packet delivery complete, capture logs showing:

1. Phone B `RAW_PACKET_GATT_SERVER_STARTED`
2. Phone A `sendRawPacket write submitted`
3. Phone B `RX_RAW_PACKET`
4. Phone B `ACK_SENT=true`
5. Phone A `RX_RAW_PACKET` with ACK payload
6. UI receiver status shows receivedCount increased

## Truth boundary

This installs the most likely native receiver + ACK proof path.

It still requires:
- new APK build
- install on two physical phones
- Bluetooth permissions granted
- both phones running receiver server
- physical two-phone proof logs
MD

echo ""
echo "============================================================"
echo "#165B RAW PACKET RECEIVER + ACK PROOF INSTALLED"
echo "Backup: $BACKUP"
echo ""
echo "Next command for APK build:"
echo "npx --yes eas-cli@latest build --platform android --profile preview-apk --clear-cache"
echo "============================================================"
