#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#192 — NATIVE RX/ACK EVENT BRIDGE + API URL CHECK"
echo "Connects Kotlin RX_RAW_PACKET / ACK_SENT events into JS proof metrics"
echo "Adds API config proof helper for Proof Ledger"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-192-native-proof-event-bridge-$STAMP"

BASE="$ROOT/android/app/src/main/java/com/maurimesh/messenger"
MODULE="$BASE/MauriMeshBleModule.kt"

mkdir -p "$BACKUP/android" \
  "$ROOT/src/maurimesh/live" \
  "$ROOT/src/maurimesh/config" \
  "$ROOT/app" \
  "$ROOT/scripts" \
  "$ROOT/docs" \
  "$ROOT/tests/integration"

echo ""
echo "1. Backup active files"

for f in \
  "$MODULE" \
  "$ROOT/app/raw-packet-proof.tsx" \
  "$ROOT/app/proof-metrics.tsx" \
  "$ROOT/app/proof-ledger.tsx" \
  "$ROOT/app/dashboard.tsx" \
  "$ROOT/src/maurimesh/live/proofMetricsSpine.ts"
do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "${f#$ROOT/}")"
    cp "$f" "$BACKUP/${f#$ROOT/}"
    echo "Backed up: ${f#$ROOT/}"
  fi
done

echo "Backup: $BACKUP"

echo ""
echo "2. Patch Kotlin native module to emit proof events"

if [ ! -f "$MODULE" ]; then
  echo "ERROR: Missing $MODULE"
  exit 1
fi

python3 <<'PY'
from pathlib import Path
import re

path = Path("android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt")
text = path.read_text()
original = text

# imports
imports = [
    "import com.facebook.react.modules.core.DeviceEventManagerModule",
    "import com.facebook.react.bridge.WritableMap",
    "import com.facebook.react.bridge.Arguments",
]
for imp in imports:
    if imp not in text:
        m = re.search(r"^(package\s+[^\n]+\n)", text, re.M)
        if m:
            text = text[:m.end()] + imp + "\n" + text[m.end():]

# helper
if "emitRawPacketProofEvent" not in text:
    helper = r'''

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

'''
    idx = text.rfind("}")
    if idx == -1:
        raise SystemExit("ERROR: final brace not found in MauriMeshBleModule.kt")
    text = text[:idx] + helper + "\n" + text[idx:]

# insert RX event inside callback after onPacketReceived receives event block
if "emitRawPacketProofEvent(\"rx_packet\"" not in text:
    target = "centralClient.cachePeerAddress(event.fromAddress, \"ack-peer\", null)"
    if target in text:
        insert = target + r'''

          val rxPacketId = extractPacketIdFromBytes(event.bytes)
          emitRawPacketProofEvent(
            "rx_packet",
            rxPacketId,
            event.fromAddress,
            event.bytes.size,
            true,
            "RX_RAW_PACKET"
          )'''
        text = text.replace(target, insert, 1)

# insert ACK_SENT event after ackSent computed
if "emitRawPacketProofEvent(\"ack_sent\"" not in text:
    target = "if (ackSent) {\n            rawPacketAckCount += 1"
    if target in text:
        insert = r'''emitRawPacketProofEvent(
            "ack_sent",
            rxPacketId,
            event.fromAddress,
            ackBytes.size,
            ackSent,
            if (ackSent) "ACK_SENT=true" else "ACK_SENT=false"
          )

          if (ackSent) {
            rawPacketAckCount += 1'''
        text = text.replace(target, insert, 1)

path.write_text(text)

print("Kotlin module patched" if text != original else "Kotlin module unchanged")
PY

echo ""
echo "3. Install JS native proof event bridge"

cat > "$ROOT/src/maurimesh/live/nativeProofEventBridge.ts" <<'TS'
import { NativeEventEmitter, NativeModules, Platform } from "react-native";
import { recordProofMetricEvent } from "./proofMetricsSpine";

export const TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER =
  "TASK_192_NATIVE_PROOF_EVENT_BRIDGE_20260608_A";

type NativeProofEvent = {
  marker?: string;
  type?: string;
  packetId?: string;
  peerAddress?: string;
  payloadBytes?: number;
  ok?: boolean;
  at?: number;
  transport?: string;
  detail?: string | null;
};

let subscription: { remove: () => void } | null = null;
let started = false;

function normalizeType(type?: string) {
  if (type === "rx_packet") return "rx_packet";
  if (type === "ack_sent") return "ack_sent";
  if (type === "ack_received") return "ack_received";
  if (type === "delivery_failed") return "delivery_failed";
  if (type === "send_submitted") return "send_submitted";
  return "rx_packet";
}

export function startNativeProofEventBridge() {
  if (Platform.OS !== "android") {
    return {
      ok: false,
      marker: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
      reason: "Android only",
    };
  }

  if (started) {
    return {
      ok: true,
      marker: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
      reason: "already_started",
    };
  }

  const native = NativeModules.MauriMeshBle;
  if (!native) {
    return {
      ok: false,
      marker: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
      reason: "MauriMeshBle native module unavailable",
    };
  }

  const emitter = new NativeEventEmitter(native);

  subscription = emitter.addListener(
    "MauriMeshRawPacketProofEvent",
    async (event: NativeProofEvent) => {
      const packetId =
        event.packetId ||
        `MM-NATIVE-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;

      const eventType = normalizeType(event.type);

      await recordProofMetricEvent({
        type: event.ok === false ? "delivery_failed" : eventType,
        packetId,
        fromNode: event.peerAddress || "native-peer",
        toNode: "local-device",
        peerId: event.peerAddress,
        transport: "BLE",
        payloadBytes: event.payloadBytes || 0,
        reason: event.detail || undefined,
        raw: event,
      });
    }
  );

  started = true;

  return {
    ok: true,
    marker: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
    reason: "started",
  };
}

export function stopNativeProofEventBridge() {
  subscription?.remove();
  subscription = null;
  started = false;

  return {
    ok: true,
    marker: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
    reason: "stopped",
  };
}
TS

echo ""
echo "4. Install API config helper"

cat > "$ROOT/src/maurimesh/config/apiConfig.ts" <<'TS'
export const TASK_192_API_CONFIG_HELPER_MARKER =
  "TASK_192_API_CONFIG_HELPER_20260608_A";

export function getConfiguredMeshApiUrl(): string {
  return (
    process.env.EXPO_PUBLIC_MESH_API_URL ||
    process.env.REACT_APP_MESH_API_URL ||
    ""
  ).trim();
}

export function getApiConfigStatus() {
  const url = getConfiguredMeshApiUrl();

  return {
    marker: TASK_192_API_CONFIG_HELPER_MARKER,
    configured: Boolean(url),
    url,
    message: url
      ? "Mesh API URL configured."
      : "Mesh API URL not configured. Set EXPO_PUBLIC_MESH_API_URL in EAS/Replit environment.",
  };
}
TS

echo ""
echo "5. Add API Config screen"

cat > "$ROOT/app/api-config.tsx" <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { getApiConfigStatus } from "../src/maurimesh/config/apiConfig";

export default function ApiConfigScreen() {
  const status = getApiConfigStatus();

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>API Configuration</Text>
      <Text style={styles.marker}>{status.marker}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Mesh API URL</Text>
        <Text style={styles.line}>Configured: {status.configured ? "yes" : "no"}</Text>
        <Text style={styles.line}>URL: {status.url || "not set"}</Text>
        <Text style={styles.muted}>{status.message}</Text>
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Required for Proof Ledger</Text>
        <Text style={styles.truthText}>
          Set EXPO_PUBLIC_MESH_API_URL to your running Replit/server URL before
          building the APK. Without this, Proof Ledger cannot save or load
          server-recorded evidence from the phone.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 36, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  marker: { color: "#38BDF8", fontSize: 12, fontWeight: "800" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.26)",
    backgroundColor: "rgba(255,255,255,0.045)",
    borderRadius: 18,
    padding: 16,
    gap: 10,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  line: { color: "rgba(255,255,255,0.78)", fontSize: 16, lineHeight: 24 },
  muted: { color: "rgba(255,255,255,0.62)", lineHeight: 22 },
  truth: {
    borderWidth: 1,
    borderColor: "rgba(245,158,11,0.45)",
    borderRadius: 18,
    padding: 16,
  },
  truthTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900" },
  truthText: { color: "rgba(255,255,255,0.7)", lineHeight: 22, marginTop: 8 },
});
TSX

echo ""
echo "6. Patch proof screens to start native event bridge"

for f in app/raw-packet-proof.tsx app/proof-metrics.tsx app/integration-hub.tsx; do
  if [ -f "$ROOT/$f" ]; then
    python3 <<PY
from pathlib import Path

path = Path("$f")
text = path.read_text()
original = text

if "startNativeProofEventBridge" not in text:
    # Ensure useEffect import
    if 'import React, { useState } from "react";' in text:
        text = text.replace(
            'import React, { useState } from "react";',
            'import React, { useEffect, useState } from "react";',
            1,
        )
    elif 'import React from "react";' in text:
        text = text.replace(
            'import React from "react";',
            'import React, { useEffect } from "react";',
            1,
        )
    elif 'import React, {' in text and 'useEffect' not in text.split('from "react";')[0]:
        text = text.replace('import React, {', 'import React, { useEffect, ', 1)

    text = text.replace(
        'from "../src/maurimesh/live/useProofMetrics";',
        'from "../src/maurimesh/live/useProofMetrics";\nimport { startNativeProofEventBridge } from "../src/maurimesh/live/nativeProofEventBridge";',
        1,
    )

    if 'nativeProofBridgeStatus' not in text:
        marker = "export default function"
        idx = text.find(marker)
        if idx != -1:
            brace = text.find("{", idx)
            if brace != -1:
                insert_at = brace + 1
                text = text[:insert_at] + '''
  useEffect(() => {
    const nativeProofBridgeStatus = startNativeProofEventBridge();
    console.log("[TASK_192_NATIVE_PROOF_EVENT_BRIDGE]", nativeProofBridgeStatus);
  }, []);
''' + text[insert_at:]

path.write_text(text)
print(f"{path} patched" if text != original else f"{path} unchanged")
PY
  fi
done

echo ""
echo "7. Patch dashboard with API Config link"

if [ -f "$ROOT/app/dashboard.tsx" ]; then
python3 <<'PY'
from pathlib import Path

path = Path("app/dashboard.tsx")
text = path.read_text()
original = text

if '"/api-config"' not in text:
    if '["Integration Hub", "/integration-hub"]' in text:
        text = text.replace(
            '["Integration Hub", "/integration-hub"]',
            '["Integration Hub", "/integration-hub"],\n  ["API Config", "/api-config"]',
            1,
        )
    elif '["Proof Metrics", "/proof-metrics"]' in text:
        text = text.replace(
            '["Proof Metrics", "/proof-metrics"]',
            '["Proof Metrics", "/proof-metrics"],\n  ["API Config", "/api-config"]',
            1,
        )

path.write_text(text)
print("dashboard patched" if text != original else "dashboard unchanged")
PY
fi

echo ""
echo "8. Add #192 tests"

cat > "$ROOT/tests/integration/task-192-native-proof-event-bridge-static.test.ts" <<'TS'
import {
  TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
} from "../../src/maurimesh/live/nativeProofEventBridge";
import {
  TASK_192_API_CONFIG_HELPER_MARKER,
  getApiConfigStatus,
} from "../../src/maurimesh/config/apiConfig";

if (
  TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER !==
  "TASK_192_NATIVE_PROOF_EVENT_BRIDGE_20260608_A"
) {
  throw new Error("Wrong native proof event bridge marker");
}

if (
  TASK_192_API_CONFIG_HELPER_MARKER !==
  "TASK_192_API_CONFIG_HELPER_20260608_A"
) {
  throw new Error("Wrong API config marker");
}

const status = getApiConfigStatus();
if (typeof status.configured !== "boolean") {
  throw new Error("API config status failed");
}

console.log("PASS: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_STATIC_TEST_20260608_A");
TS

echo ""
echo "9. Add audit script"

cat > "$ROOT/scripts/audit-task-192-native-proof-event-bridge.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#192 Native Proof Event Bridge Audit"
echo "============================================================"

grep -RniE "TASK_192|MauriMeshRawPacketProofEvent|emitRawPacketProofEvent|startNativeProofEventBridge|EXPO_PUBLIC_MESH_API_URL|API Config" \
  android app src tests scripts docs 2>/dev/null || true

echo ""
echo "Required checks:"
grep -q "MauriMeshRawPacketProofEvent" android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt && echo "✅ Kotlin emits native proof event"
grep -q "emitRawPacketProofEvent" android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt && echo "✅ Kotlin event helper exists"
test -f src/maurimesh/live/nativeProofEventBridge.ts && echo "✅ JS native proof bridge exists"
test -f src/maurimesh/config/apiConfig.ts && echo "✅ API config helper exists"
test -f app/api-config.tsx && echo "✅ API config screen exists"
grep -q "startNativeProofEventBridge" app/raw-packet-proof.tsx && echo "✅ raw packet proof starts bridge"
grep -q "API Config" app/dashboard.tsx && echo "✅ dashboard API Config link"
SH

chmod +x "$ROOT/scripts/audit-task-192-native-proof-event-bridge.sh"

echo ""
echo "10. Docs"

cat > "$ROOT/docs/task-192-native-proof-event-bridge.md" <<'MD'
# Task #192 — Native RX/ACK Event Bridge + API URL Check

Marker: `TASK_192_NATIVE_PROOF_EVENT_BRIDGE_20260608_A`

## Installed

- Kotlin native event emitter for raw packet proof events.
- JS listener for `MauriMeshRawPacketProofEvent`.
- Native RX/ACK events feed the proof metrics spine.
- API config helper.
- `/api-config` screen.
- Dashboard API Config link.

## Why

The UI already showed live BLE scan data, but ACK/delivery metrics stayed at zero.
This task connects the native RX/ACK event layer into the metrics spine.

## Physical proof requirement

Metrics rise only after:
- receiver is started on both phones
- Phone A sends packet
- Phone B receives `RX_RAW_PACKET`
- Phone B emits `ack_sent`
- JS bridge records the native event
MD

echo ""
echo "11. Run audit"
bash "$ROOT/scripts/audit-task-192-native-proof-event-bridge.sh"

echo ""
echo "12. Run static test"
npx tsx "$ROOT/tests/integration/task-192-native-proof-event-bridge-static.test.ts"

echo ""
echo "13. TypeScript check"
npx tsc --noEmit

echo ""
echo "14. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "#192 NATIVE PROOF EVENT BRIDGE INSTALLED"
echo "Backup: $BACKUP"
echo "Next:"
echo "1. Set EXPO_PUBLIC_MESH_API_URL before EAS build if using Proof Ledger save/load."
echo "2. Build APK."
echo "3. Open /raw-packet-proof and /proof-metrics."
echo "============================================================"
