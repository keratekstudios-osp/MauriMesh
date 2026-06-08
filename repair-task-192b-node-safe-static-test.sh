#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#192B — NODE-SAFE STATIC TEST REPAIR"
echo "Fixes tsx test failure caused by importing react-native in Node"
echo "Keeps native bridge intact for Expo/Android"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-192b-node-safe-test-$STAMP"

mkdir -p "$BACKUP/src/maurimesh/live" "$BACKUP/tests/integration" "$ROOT/src/maurimesh/live" "$ROOT/tests/integration" "$ROOT/scripts" "$ROOT/docs"

echo ""
echo "1. Backup files"

for f in \
  src/maurimesh/live/nativeProofEventBridge.ts \
  tests/integration/task-192-native-proof-event-bridge-static.test.ts \
  android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt
do
  if [ -f "$ROOT/$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$ROOT/$f" "$BACKUP/$f"
    echo "Backed up: $f"
  fi
done

echo "Backup: $BACKUP"

echo ""
echo "2. Create Node-safe constants file"

cat > "$ROOT/src/maurimesh/live/nativeProofEventBridgeConstants.ts" <<'TS'
export const TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER =
  "TASK_192_NATIVE_PROOF_EVENT_BRIDGE_20260608_A";

export const MAURIMESH_RAW_PACKET_PROOF_EVENT_NAME =
  "MauriMeshRawPacketProofEvent";
TS

echo ""
echo "3. Patch nativeProofEventBridge.ts to import marker/constants"

cat > "$ROOT/src/maurimesh/live/nativeProofEventBridge.ts" <<'TS'
import { NativeEventEmitter, NativeModules, Platform } from "react-native";
import { recordProofMetricEvent } from "./proofMetricsSpine";
import {
  MAURIMESH_RAW_PACKET_PROOF_EVENT_NAME,
  TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
} from "./nativeProofEventBridgeConstants";

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
    MAURIMESH_RAW_PACKET_PROOF_EVENT_NAME,
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
echo "4. Replace static test so it does not import react-native"

cat > "$ROOT/tests/integration/task-192-native-proof-event-bridge-static.test.ts" <<'TS'
import {
  MAURIMESH_RAW_PACKET_PROOF_EVENT_NAME,
  TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
} from "../../src/maurimesh/live/nativeProofEventBridgeConstants";
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

if (MAURIMESH_RAW_PACKET_PROOF_EVENT_NAME !== "MauriMeshRawPacketProofEvent") {
  throw new Error("Wrong native proof event name");
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
echo "5. Add duplicate-emitter detector"

cat > "$ROOT/scripts/audit-task-192b-duplicate-native-events.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

FILE="android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"

echo "============================================================"
echo "#192B Duplicate Native Event Detector"
echo "============================================================"

if [ ! -f "$FILE" ]; then
  echo "WARN: $FILE not found"
  exit 0
fi

RX_COUNT=$(grep -n '"rx_packet"' "$FILE" | wc -l | tr -d ' ')
ACK_COUNT=$(grep -n '"ack_sent"' "$FILE" | wc -l | tr -d ' ')

echo "rx_packet marker count: $RX_COUNT"
echo "ack_sent marker count: $ACK_COUNT"

if [ "$RX_COUNT" -gt 1 ] || [ "$ACK_COUNT" -gt 1 ]; then
  echo "WARN: Duplicate native proof event blocks may exist from rerunning #192."
  echo "This will not break export, but it may double-count metrics until cleaned."
  grep -nE 'emitRawPacketProofEvent|\"rx_packet\"|\"ack_sent\"|MauriMeshRawPacketProofEvent' "$FILE" || true
else
  echo "✅ No duplicate rx_packet/ack_sent markers detected"
fi
SH

chmod +x "$ROOT/scripts/audit-task-192b-duplicate-native-events.sh"

echo ""
echo "6. Update audit script"

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
test -f src/maurimesh/live/nativeProofEventBridgeConstants.ts && echo "✅ Node-safe bridge constants exist"
test -f src/maurimesh/config/apiConfig.ts && echo "✅ API config helper exists"
test -f app/api-config.tsx && echo "✅ API config screen exists"
grep -q "startNativeProofEventBridge" app/raw-packet-proof.tsx && echo "✅ raw packet proof starts bridge"
grep -q "API Config" app/dashboard.tsx && echo "✅ dashboard API Config link"
SH

chmod +x "$ROOT/scripts/audit-task-192-native-proof-event-bridge.sh"

echo ""
echo "7. Docs"

cat > "$ROOT/docs/task-192b-node-safe-static-test-repair.md" <<'MD'
# Task #192B — Node-Safe Static Test Repair

Marker: `TASK_192_NATIVE_PROOF_EVENT_BRIDGE_20260608_A`

## Fixed

The previous static test imported `nativeProofEventBridge.ts`, which imports `react-native`.
Plain Node/tsx cannot transform React Native's package entry in this environment.

Repair:
- Added `nativeProofEventBridgeConstants.ts`
- Native bridge imports constants from that file
- Static test imports only the constants file and API config helper
- Expo/Android bridge remains intact

## Truth boundary

This fixes Replit/Node validation only.
Native proof events still require a new APK build and physical two-phone RX/ACK test.
MD

echo ""
echo "8. Run audit"
bash "$ROOT/scripts/audit-task-192-native-proof-event-bridge.sh"

echo ""
echo "9. Run duplicate detector"
bash "$ROOT/scripts/audit-task-192b-duplicate-native-events.sh"

echo ""
echo "10. Run static test again"
npx tsx "$ROOT/tests/integration/task-192-native-proof-event-bridge-static.test.ts"

echo ""
echo "11. TypeScript check"
npx tsc --noEmit

echo ""
echo "12. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "#192B NODE-SAFE STATIC TEST REPAIR COMPLETE"
echo "Backup: $BACKUP"
echo "If duplicate detector warns, send that section and we will clean duplicate Kotlin blocks."
echo "============================================================"
