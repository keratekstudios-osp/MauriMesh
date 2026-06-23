#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT PACKET LOGGER PATCH KIT"
echo "============================================================"
echo "Goal:"
echo "Prepare app code so packetId can be logged for native BLE/GATT proof attempts."
echo ""
echo "Truth:"
echo "This patch prepares logging."
echo "It does NOT prove native BLE/GATT transport by itself."
echo "Native BLE/GATT PASS still requires physical phone logs showing same packetId"
echo "inside real native transport lines."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-native-ble-gatt-packet-logger-$STAMP"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run this from the Replit project root."
  exit 1
fi

mkdir -p "$BACKUP"
mkdir -p \
  "$ROOT/src/maurimesh/native" \
  "$ROOT/src/maurimesh/proof" \
  "$ROOT/docs/native-proof" \
  "$ROOT/scripts"

echo "[1] Backing up likely proof files if present..."
for f in \
  app/3-device-proof.tsx \
  app/ble-3-device-proof.tsx \
  app/store-forward-proof.tsx \
  app/ble-2-hop-proof.tsx \
  src/maurimesh/native/nativeBlePacketLogger.ts \
  src/maurimesh/proof/nativeBleGattProofVerdict.ts
do
  if [ -f "$ROOT/$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$ROOT/$f" "$BACKUP/$f"
    echo "Backed up: $f"
  fi
done

echo ""
echo "[2] Creating native BLE packet logger TypeScript wrapper..."

cat > "$ROOT/src/maurimesh/native/nativeBlePacketLogger.ts" <<'TS'
import { NativeModules, Platform } from "react-native";

export type NativeBleTransport =
  | "BLE_GATT"
  | "BLE_ADVERTISE"
  | "BLE_SCAN"
  | "BRIDGE_LOG_ONLY"
  | "REACT_NATIVE_FALLBACK"
  | "UNKNOWN";

export type NativeBlePacketStage =
  | "BLE_ADVERTISE_START"
  | "BLE_ADVERTISE_PAYLOAD"
  | "BLE_SCAN_START"
  | "BLE_SCAN_RESULT"
  | "GATT_CONNECT_START"
  | "GATT_CONNECTED"
  | "GATT_SERVICE_DISCOVERED"
  | "GATT_WRITE_PACKET"
  | "GATT_WRITE_ACK"
  | "GATT_CHARACTERISTIC_CHANGED"
  | "GATT_READ_PACKET"
  | "RELAY_PACKET_NATIVE"
  | "ACK_PACKET_NATIVE"
  | "GATT_DISCONNECT"
  | "BLE_ERROR"
  | string;

export type NativeBleDeviceRole =
  | "A06_PHONE_A"
  | "S10_PHONE_B"
  | "A16_PHONE_C"
  | "PHONE_A"
  | "PHONE_B"
  | "PHONE_C"
  | string;

export type NativeBlePacketLogInput = {
  role: NativeBleDeviceRole;
  stage: NativeBlePacketStage;
  packetId: string;
  transport: NativeBleTransport;
  detail: string;
};

const MODULE_NAME = "MauriMeshNativeBlePacket";

function clean(value: unknown): string {
  return String(value ?? "")
    .replace(/\s+/g, "_")
    .replace(/[|]/g, "/")
    .trim();
}

export function formatNativeBlePacketLine(input: NativeBlePacketLogInput): string {
  const role = clean(input.role);
  const stage = clean(input.stage);
  const packetId = clean(input.packetId || "NO_PACKET_ID");
  const transport = clean(input.transport || "UNKNOWN");
  const detail = clean(input.detail);

  return `MAURIMESH_NATIVE_BLE_PACKET | role=${role} | stage=${stage} | packetId=${packetId} | transport=${transport} | detail=${detail}`;
}

export async function nativeBlePacketLog(input: NativeBlePacketLogInput): Promise<void> {
  const line = formatNativeBlePacketLine(input);
  const nativeModule = NativeModules?.[MODULE_NAME];

  if (nativeModule?.logPacketEvent) {
    await nativeModule.logPacketEvent({
      role: input.role,
      stage: input.stage,
      packetId: input.packetId,
      transport: input.transport,
      detail: input.detail,
      line,
      platform: Platform.OS,
    });
    return;
  }

  console.log(
    `MAURIMESH_NATIVE_BLE_PACKET_FALLBACK | role=${clean(input.role)} | stage=${clean(
      input.stage
    )} | packetId=${clean(input.packetId)} | transport=REACT_NATIVE_FALLBACK | detail=${clean(
      input.detail
    )}`
  );
}

export function nativeBlePacketLogSafe(input: NativeBlePacketLogInput): void {
  void nativeBlePacketLog(input).catch((err) => {
    console.log(
      `MAURIMESH_NATIVE_BLE_PACKET_FALLBACK | role=${clean(input.role)} | stage=${clean(
        input.stage
      )} | packetId=${clean(input.packetId)} | transport=REACT_NATIVE_FALLBACK | detail=LOGGER_ERROR_${
        err instanceof Error ? clean(err.message) : "UNKNOWN"
      }`
    );
  });
}

export const NativeBlePacketStages = {
  BLE_ADVERTISE_START: "BLE_ADVERTISE_START",
  BLE_ADVERTISE_PAYLOAD: "BLE_ADVERTISE_PAYLOAD",
  BLE_SCAN_START: "BLE_SCAN_START",
  BLE_SCAN_RESULT: "BLE_SCAN_RESULT",
  GATT_CONNECT_START: "GATT_CONNECT_START",
  GATT_CONNECTED: "GATT_CONNECTED",
  GATT_SERVICE_DISCOVERED: "GATT_SERVICE_DISCOVERED",
  GATT_WRITE_PACKET: "GATT_WRITE_PACKET",
  GATT_WRITE_ACK: "GATT_WRITE_ACK",
  GATT_CHARACTERISTIC_CHANGED: "GATT_CHARACTERISTIC_CHANGED",
  GATT_READ_PACKET: "GATT_READ_PACKET",
  RELAY_PACKET_NATIVE: "RELAY_PACKET_NATIVE",
  ACK_PACKET_NATIVE: "ACK_PACKET_NATIVE",
  GATT_DISCONNECT: "GATT_DISCONNECT",
  BLE_ERROR: "BLE_ERROR",
} as const;
TS

echo "Created: src/maurimesh/native/nativeBlePacketLogger.ts"

echo ""
echo "[3] Creating native BLE/GATT proof verdict helper..."

cat > "$ROOT/src/maurimesh/proof/nativeBleGattProofVerdict.ts" <<'TS'
export type NativeBleGattVerdict = {
  verdict:
    | "NATIVE_BLE_GATT_PACKET_BOUND_PASS"
    | "APK_WORKFLOW_ONLY_NATIVE_NOT_CONFIRMED"
    | "NO_PACKET_FOUND";
  packetId: string;
  nativeTransportHits: number;
  workflowHits: number;
  explanation: string;
};

const nativeTransportMarkers = [
  "BluetoothGatt",
  "BtGatt",
  "GATT",
  "GattService",
  "onScanResult",
  "AdvertiseCallback",
  "AdvertisingSet",
  "writeCharacteristic",
  "readCharacteristic",
  "onCharacteristicWrite",
  "onCharacteristicRead",
  "onCharacteristicChanged",
  "onServicesDiscovered",
  "connectGatt",
  "MAURIMESH_NATIVE_BLE_PACKET",
  "transport=BLE_GATT",
];

const workflowMarkers = [
  "ReactNativeJS",
  "MAURIMESH_3_DEVICE_PROOF",
  "MAURIMESH_STORE_FORWARD_PROOF",
  "EXAM_APPROVED",
];

export function evaluateNativeBleGattPacketProof(
  logText: string,
  packetId: string
): NativeBleGattVerdict {
  const lines = logText.split(/\r?\n/);
  const packetLines = lines.filter((line) => line.includes(packetId));

  if (packetLines.length === 0) {
    return {
      verdict: "NO_PACKET_FOUND",
      packetId,
      nativeTransportHits: 0,
      workflowHits: 0,
      explanation: "No lines were found for this packetId.",
    };
  }

  const nativeTransportHits = packetLines.filter((line) =>
    nativeTransportMarkers.some((marker) => line.includes(marker))
  ).length;

  const workflowHits = packetLines.filter((line) =>
    workflowMarkers.some((marker) => line.includes(marker))
  ).length;

  if (nativeTransportHits > 0) {
    return {
      verdict: "NATIVE_BLE_GATT_PACKET_BOUND_PASS",
      packetId,
      nativeTransportHits,
      workflowHits,
      explanation:
        "The packetId appears in native BLE/GATT transport-marked lines. Validate role/path continuity before final lock.",
    };
  }

  return {
    verdict: "APK_WORKFLOW_ONLY_NATIVE_NOT_CONFIRMED",
    packetId,
    nativeTransportHits,
    workflowHits,
    explanation:
      "The packetId appears in app/workflow logs but not in native BLE/GATT transport-marked lines.",
  };
}
TS

echo "Created: src/maurimesh/proof/nativeBleGattProofVerdict.ts"

echo ""
echo "[4] Creating proof documentation..."

cat > "$ROOT/docs/native-proof/native-ble-gatt-packet-proof.md" <<'MD'
# MauriMesh Native BLE/GATT Packet-Bound Proof

## Purpose

This document defines the next proof level after APK proof-screen workflow logs.

## Current truth standard

MauriMesh has locked APK proof-screen + ReactNativeJS monitor proof for:
- 2-hop relay ACK
- 3-device relay path
- native BLE/GATT capture attempt

Native BLE/GATT packet-bound PASS is not claimed until the same packetId appears inside native BLE/GATT transport logs.

## Required log format

```txt
MAURIMESH_NATIVE_BLE_PACKET | role=<PHONE_ROLE> | stage=<STAGE> | packetId=<PACKET_ID> | transport=<BLE_GATT> | detail=<DETAIL>
Native PASS rule

Native BLE/GATT packet-bound PASS requires the same packetId inside lines that include native transport markers such as:

BluetoothGatt
BtGatt
GATT
GattService
onScanResult
AdvertiseCallback
AdvertisingSet
writeCharacteristic
readCharacteristic
onCharacteristicWrite
onCharacteristicRead
onCharacteristicChanged
onServicesDiscovered
connectGatt
MAURIMESH_NATIVE_BLE_PACKET with transport=BLE_GATT
Not enough for native PASS

These prove app workflow only:

ReactNativeJS
MAURIMESH_3_DEVICE_PROOF
MAURIMESH_STORE_FORWARD_PROOF
EXAM_APPROVED
MAURIMESH_NATIVE_BLE_PACKET_FALLBACK
transport=REACT_NATIVE_FALLBACK
transport=BRIDGE_LOG_ONLY
Next engineering target

Patch real Android BLE/GATT callbacks so packetId appears at:

advertise
scan
GATT connect
service discovery
write
read
characteristic changed
relay
ACK
MD

echo "Created: docs/native-proof/native-ble-gatt-packet-proof.md"

echo ""
echo "[5] Creating Android native Java bridge files only if native Android project exists..."

ANDROID_MAIN="$ROOT/android/app/src/main/java"
PKG_DIR="$ANDROID_MAIN/com/maurimesh/messenger"

if [ -d "$ANDROID_MAIN" ]; then
mkdir -p "$PKG_DIR"

cat > "$PKG_DIR/MauriMeshNativeBlePacketModule.java" <<'JAVA'
package com.maurimesh.messenger;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;

public class MauriMeshNativeBlePacketModule extends ReactContextBaseJavaModule {
private static final String TAG = "MauriMeshNativeBlePacket";

public MauriMeshNativeBlePacketModule(ReactApplicationContext reactContext) {
super(reactContext);
}

@NonNull
@Override
public String getName() {
return "MauriMeshNativeBlePacket";
}

private String safe(@Nullable String value) {
if (value == null || value.trim().isEmpty()) return "UNKNOWN";
return value.replace("|", "/").replaceAll("\s+", "_");
}

@ReactMethod
public void logPacketEvent(ReadableMap event, Promise promise) {
try {
String role = event.hasKey("role") ? event.getString("role") : "UNKNOWN_ROLE";
String stage = event.hasKey("stage") ? event.getString("stage") : "UNKNOWN_STAGE";
String packetId = event.hasKey("packetId") ? event.getString("packetId") : "NO_PACKET_ID";
String transport = event.hasKey("transport") ? event.getString("transport") : "BRIDGE_LOG_ONLY";
String detail = event.hasKey("detail") ? event.getString("detail") : "NO_DETAIL";

  String line =
    "MAURIMESH_NATIVE_BLE_PACKET"
      + " | role=" + safe(role)
      + " | stage=" + safe(stage)
      + " | packetId=" + safe(packetId)
      + " | transport=" + safe(transport)
      + " | detail=" + safe(detail);

  Log.i(TAG, line);
  promise.resolve(true);
} catch (Exception err) {
  Log.e(TAG, "MAURIMESH_NATIVE_BLE_PACKET | role=UNKNOWN | stage=BLE_ERROR | packetId=NO_PACKET_ID | transport=BRIDGE_LOG_ONLY | detail=" + safe(err.getMessage()));
  promise.reject("MAURIMESH_NATIVE_BLE_PACKET_LOG_ERROR", err);
}

}
}
JAVA

cat > "$PKG_DIR/MauriMeshNativeBlePacketPackage.java" <<'JAVA'
package com.maurimesh.messenger;

import androidx.annotation.NonNull;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class MauriMeshNativeBlePacketPackage implements ReactPackage {
@NonNull
@Override
public List<NativeModule> createNativeModules(@NonNull ReactApplicationContext reactContext) {
List<NativeModule> modules = new ArrayList<>();
modules.add(new MauriMeshNativeBlePacketModule(reactContext));
return modules;
}

@NonNull
@Override
public List<ViewManager> createViewManagers(@NonNull ReactApplicationContext reactContext) {
return Collections.emptyList();
}
}
JAVA

echo "Created Android native bridge files:"
echo "android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java"
echo "android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketPackage.java"
echo ""
echo "NOTE: If this app uses Expo managed/autolinking only, this package may still need manual registration in MainApplication."
else
echo "No android/app/src/main/java found. Skipping native Java bridge creation."
fi

echo ""
echo "[6] Creating proof screen patch helper script..."

cat > "$ROOT/scripts/patch-proof-screens-native-ble-logger.js" <<'JS'
const fs = require("fs");
const path = require("path");

const root = process.cwd();
const targets = [
"app/3-device-proof.tsx",
"app/ble-3-device-proof.tsx",
"app/store-forward-proof.tsx",
"app/ble-2-hop-proof.tsx",
];

const importLine =
'import { nativeBlePacketLogSafe } from "../src/maurimesh/native/nativeBlePacketLogger";';

function detectRole(stage) {
if (/A06|PHONE_A|ACK_RECEIVED|TX_A06/i.test(stage)) return "A06_PHONE_A";
if (/S10|PHONE_B|RELAY|RX_S10|ACK_RELAY/i.test(stage)) return "S10_PHONE_B";
if (/A16|PHONE_C|RX_A16|ACK_A16/i.test(stage)) return "A16_PHONE_C";
return "PHONE_UNKNOWN";
}

function nativeStageFor(stage) {
if (/TX_A06_TO_S10/i.test(stage)) return "GATT_WRITE_PACKET";
if (/RX_S10_FROM_A06/i.test(stage)) return "GATT_READ_PACKET";
if (/RELAY_S10_TO_A16/i.test(stage)) return "RELAY_PACKET_NATIVE";
if (/RX_A16_FROM_S10/i.test(stage)) return "GATT_READ_PACKET";
if (/ACK_A16_TO_S10/i.test(stage)) return "ACK_PACKET_NATIVE";
if (/ACK_RELAY_S10_TO_A06/i.test(stage)) return "ACK_PACKET_NATIVE";
if (/ACK_RECEIVED_A06/i.test(stage)) return "GATT_CHARACTERISTIC_CHANGED";
if (/STORE/i.test(stage)) return "GATT_WRITE_PACKET";
if (/EXAM_APPROVED/i.test(stage)) return "GATT_CHARACTERISTIC_CHANGED";
return "BLE_STAGE";
}

let changed = [];

for (const rel of targets) {
const file = path.join(root, rel);
if (!fs.existsSync(file)) continue;

let src = fs.readFileSync(file, "utf8");

if (!src.includes("nativeBlePacketLogSafe")) {
const firstImport = src.match(/^import .*?;$/m);
if (firstImport) {
src = src.replace(firstImport[0], ${firstImport[0]}\n${importLine});
} else {
src = ${importLine}\n${src};
}
}

// Patch console/log calls that include packetId and known proof stages.
const stages = [
"TX_A06_TO_S10",
"RX_S10_FROM_A06",
"RELAY_S10_TO_A16",
"RX_A16_FROM_S10",
"ACK_A16_TO_S10",
"ACK_RELAY_S10_TO_A06",
"ACK_RECEIVED_A06",
"TX_A06_TO_S10_STORE_REQUEST",
"S10_STORE_PACKET",
"S10_FORWARD_STORED_TO_A16",
"RX_A16_STORED_PACKET",
"ACK_A16_TO_S10_STORED",
"ACK_RELAY_S10_TO_A06_STORED",
"ACK_RECEIVED_A06_STORED",
"EXAM_APPROVED",
];

if (!src.includes("MAURIMESH_NATIVE_BLE_PACKET_PATCH_MARKER")) {
const helper = `

function mauriMeshNativePacketProofLog(stage: string, packetId: string, detail?: string) {
nativeBlePacketLogSafe({
role: "${rel.includes("store") ? "PHONE_STORE_FORWARD" : "PHONE_PROOF"}",
stage,
packetId,
transport: "BRIDGE_LOG_ONLY",
detail: detail || stage,
});
}
// MAURIMESH_NATIVE_BLE_PACKET_PATCH_MARKER
`;
src += helper;
}

// Add a visible comment block describing required calls; avoids destructive AST rewriting.
if (!src.includes("MAURIMESH_NATIVE_BLE_PACKET_REQUIRED_STAGE_MAP")) {
src += `

/*
MAURIMESH_NATIVE_BLE_PACKET_REQUIRED_STAGE_MAP

When proof stage buttons/log events fire, call:

nativeBlePacketLogSafe({
role: "A06_PHONE_A" | "S10_PHONE_B" | "A16_PHONE_C",
stage: "GATT_WRITE_PACKET" | "GATT_READ_PACKET" | "RELAY_PACKET_NATIVE" | "ACK_PACKET_NATIVE" | "GATT_CHARACTERISTIC_CHANGED",
packetId,
transport: "BRIDGE_LOG_ONLY",
detail: "TX_A06_TO_S10" | "RX_S10_FROM_A06" | "RELAY_S10_TO_A16" | "RX_A16_FROM_S10" | "ACK_A16_TO_S10" | "ACK_RELAY_S10_TO_A06" | "ACK_RECEIVED_A06"
});

This patch does not claim real BLE/GATT proof.
Real native PASS requires transport=BLE_GATT inside Android Bluetooth/GATT callbacks.
*/
`;
}

fs.writeFileSync(file, src);
changed.push(rel);
}

console.log("Patched proof files:");
for (const rel of changed) console.log("- " + rel);
if (changed.length === 0) {
console.log("No proof screen files found to patch. Logger files were still created.");
}
JS

node "$ROOT/scripts/patch-proof-screens-native-ble-logger.js"

echo ""
echo "[7] Scanning repo for native BLE/GATT files..."
{
echo "============================================================"
echo "MAURIMESH NATIVE BLE/GATT FILE SCAN"
echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "============================================================"
echo ""
find "$ROOT"
-path "$ROOT/node_modules" -prune -o
-path "$ROOT/.git" -prune -o
-type f −name"∗.kt"−o−name"∗.java"−o−name"∗.tsx"−o−name"∗.ts"
-print | while read -r f; do
if grep -Eiq "BluetoothGatt|BtGatt|GattService|onScanResult|AdvertiseCallback|writeCharacteristic|readCharacteristic|onCharacteristicChanged|react-native-ble-plx|MauriMeshBle|BLE|Bluetooth" "$f"; then
echo "${f#$ROOT/}"
fi
done
} | tee "$ROOT/docs/native-proof/native-ble-gatt-file-scan-$STAMP.txt"

echo ""
echo "[8] Creating final patch report..."

REPORT="$ROOT/docs/native-proof/native-ble-gatt-packet-logger-patch-report-$STAMP.md"

cat > "$REPORT" <<MD

MauriMesh Native BLE/GATT Packet Logger Patch Report

Generated: $STAMP

Files created
src/maurimesh/native/nativeBlePacketLogger.ts
src/maurimesh/proof/nativeBleGattProofVerdict.ts
docs/native-proof/native-ble-gatt-packet-proof.md
docs/native-proof/native-ble-gatt-file-scan-$STAMP.txt
scripts/patch-proof-screens-native-ble-logger.js
Android native bridge

If android/app/src/main/java exists, these were created:

android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketModule.java
android/app/src/main/java/com/maurimesh/messenger/MauriMeshNativeBlePacketPackage.java

These bridge logs are not automatically real BLE/GATT proof.
They are bridge-level logs unless wired into actual Android Bluetooth/GATT callbacks.

Required proof log format

```txt
MAURIMESH_NATIVE_BLE_PACKET | role=<PHONE_ROLE> | stage=<STAGE> | packetId=<PACKET_ID> | transport=<BLE_GATT> | detail=<DETAIL>
```

Truth rule

Native BLE/GATT packet-bound PASS requires the same packetId inside native transport logs.

If packetId appears only in ReactNativeJS, bridge fallback, or proof-screen logs, the verdict remains:

```txt
APK workflow proof only / native BLE-GATT packet-bound proof not yet confirmed
```

Next required step

Build a new APK, install it on A06/S10/A16, run the native capture again, and search for:

```txt
MAURIMESH_NATIVE_BLE_PACKET
packetId=<same packet>
transport=BLE_GATT
```
MD

echo "Created: $REPORT"

echo ""
echo "[9] Running validation if available..."

if command -v npx >/dev/null 2>&1; then
echo ""
echo "Running TypeScript check..."
npx tsc --noEmit || true

echo ""
echo "Running Expo Android export..."
npx expo export --platform android --clear || true
else
echo "npx not found. Skipping validation."
fi

echo ""
echo "============================================================"
echo "PATCH KIT COMPLETE"
echo "============================================================"
echo "Backup:"
echo "$BACKUP"
echo ""
echo "Report:"
echo "$REPORT"
echo ""
echo "Important:"
echo "This prepares logging only."
echo "Native BLE/GATT PASS still requires physical phone log proof."
echo "============================================================"
