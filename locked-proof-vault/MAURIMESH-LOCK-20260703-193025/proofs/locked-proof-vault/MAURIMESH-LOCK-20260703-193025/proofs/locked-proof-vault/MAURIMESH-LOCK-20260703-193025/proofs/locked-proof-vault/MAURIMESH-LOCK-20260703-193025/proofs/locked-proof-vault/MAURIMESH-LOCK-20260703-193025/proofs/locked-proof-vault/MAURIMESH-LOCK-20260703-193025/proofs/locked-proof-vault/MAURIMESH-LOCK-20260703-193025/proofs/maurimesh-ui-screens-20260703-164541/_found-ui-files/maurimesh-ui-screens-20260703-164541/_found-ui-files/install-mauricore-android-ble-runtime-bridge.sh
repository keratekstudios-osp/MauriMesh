#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURICORE ANDROID BLE RUNTIME BRIDGE"
echo "Connects native BLE proof events into MauriCore status layer"
echo "No deletion. No fake proof. Replit remains simulation/export only."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-mauricore-android-ble-bridge-$STAMP"

mkdir -p "$BACKUP" "$ROOT/src/mauricore/bridges" "$ROOT/src/mauricore/dashboard" "$ROOT/app"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: Run this from /home/runner/workspace"
  exit 1
fi

BLE_KT="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"

if [ ! -f "$BLE_KT" ]; then
  echo "ERROR: Android BLE module missing:"
  echo "$BLE_KT"
  exit 1
fi

cat > "$BACKUP/README.txt" <<TXT
Backup marker before MauriCore Android BLE Runtime Bridge.

This bridge creates:
- src/mauricore/bridges/androidBleRuntimeBridge.ts
- src/mauricore/bridges/bleProofEventStore.ts
- src/mauricore/dashboard/bleRuntimeBridgeDashboard.ts
- src/mauricore/dashboard/MauriCoreBleRuntimeScreen.tsx
- app/mauricore-ble-runtime.tsx

It does not delete existing BLE/router/ACK/store-forward/native files.
TXT

echo ""
echo "1. Create BLE proof event store"

cat > "$ROOT/src/mauricore/bridges/bleProofEventStore.ts" <<'TS'
export type BleProofEventKind =
  | "tx_packet"
  | "rx_packet"
  | "ack_sent"
  | "ack_received"
  | "scan_started"
  | "scan_result"
  | "advertise_started"
  | "native_status"
  | "unknown";

export type BleProofEvent = {
  id: string;
  timestamp: string;
  kind: BleProofEventKind;
  packetId?: string;
  peerId?: string;
  transport: "BLE" | "UNKNOWN";
  source: "android_native" | "typescript_bridge" | "simulation";
  raw?: Record<string, unknown>;
  proofReady: boolean;
};

const events: BleProofEvent[] = [];

function id(): string {
  return `ble_evt_${Date.now()}_${Math.random().toString(36).slice(2)}`;
}

export function normaliseBleProofEvent(raw: Record<string, unknown>): BleProofEvent {
  const stage = String(raw.stage ?? raw.type ?? raw.event ?? "unknown").toLowerCase();

  let kind: BleProofEventKind = "unknown";
  if (stage.includes("rx_packet") || stage.includes("rx")) kind = "rx_packet";
  if (stage.includes("tx_packet") || stage.includes("tx")) kind = "tx_packet";
  if (stage.includes("ack_sent")) kind = "ack_sent";
  if (stage.includes("ack_received") || stage.includes("ack_ok")) kind = "ack_received";
  if (stage.includes("scan_started")) kind = "scan_started";
  if (stage.includes("scan_result")) kind = "scan_result";
  if (stage.includes("advertise")) kind = "advertise_started";
  if (stage.includes("status")) kind = "native_status";

  const packetId =
    typeof raw.packetId === "string"
      ? raw.packetId
      : typeof raw.packet_id === "string"
        ? raw.packet_id
        : typeof raw.rxPacketId === "string"
          ? raw.rxPacketId
          : undefined;

  const peerId =
    typeof raw.peerId === "string"
      ? raw.peerId
      : typeof raw.deviceId === "string"
        ? raw.deviceId
        : typeof raw.from === "string"
          ? raw.from
          : undefined;

  return {
    id: id(),
    timestamp: new Date().toISOString(),
    kind,
    packetId,
    peerId,
    transport: "BLE",
    source: "android_native",
    raw,
    proofReady: Boolean(packetId || kind === "scan_started" || kind === "native_status"),
  };
}

export function ingestBleProofEvent(raw: Record<string, unknown>): BleProofEvent {
  const event = normaliseBleProofEvent(raw);
  events.unshift(event);
  if (events.length > 300) events.pop();
  return event;
}

export function getBleProofEvents(): BleProofEvent[] {
  return [...events];
}

export function getBleProofSummary() {
  const all = getBleProofEvents();

  return {
    total: all.length,
    rxPackets: all.filter((event) => event.kind === "rx_packet").length,
    txPackets: all.filter((event) => event.kind === "tx_packet").length,
    ackSent: all.filter((event) => event.kind === "ack_sent").length,
    ackReceived: all.filter((event) => event.kind === "ack_received").length,
    scanEvents: all.filter((event) => event.kind === "scan_started" || event.kind === "scan_result").length,
    proofReady: all.filter((event) => event.proofReady).length,
    lastEvent: all[0] ?? null,
  };
}

export function clearBleProofEvents(): void {
  events.length = 0;
}
TS

echo ""
echo "2. Create Android BLE runtime bridge"

cat > "$ROOT/src/mauricore/bridges/androidBleRuntimeBridge.ts" <<'TS'
import { NativeEventEmitter, NativeModules, Platform } from "react-native";
import {
  BleProofEvent,
  getBleProofEvents,
  getBleProofSummary,
  ingestBleProofEvent,
} from "./bleProofEventStore";

type BridgeState = {
  platform: string;
  nativeModulePresent: boolean;
  listening: boolean;
  eventName: string;
  lastError?: string;
};

const EVENT_NAME = "MauriMeshRawPacketProofEvent";

let subscription: { remove: () => void } | null = null;

function getNativeBleModule(): unknown {
  return (
    NativeModules.MauriMeshBleModule ??
    NativeModules.MauriMeshBLEModule ??
    NativeModules.MauriMeshNativeBleModule ??
    null
  );
}

const state: BridgeState = {
  platform: Platform.OS,
  nativeModulePresent: Boolean(getNativeBleModule()),
  listening: false,
  eventName: EVENT_NAME,
};

export function getAndroidBleRuntimeBridgeState(): BridgeState {
  state.nativeModulePresent = Boolean(getNativeBleModule());
  return { ...state };
}

export function startAndroidBleRuntimeBridge(): BridgeState {
  const nativeModule = getNativeBleModule();

  state.nativeModulePresent = Boolean(nativeModule);

  if (Platform.OS !== "android") {
    state.lastError = "Bridge is designed for Android native BLE runtime.";
    return getAndroidBleRuntimeBridgeState();
  }

  if (!nativeModule) {
    state.lastError = "MauriMeshBleModule is not available in NativeModules.";
    return getAndroidBleRuntimeBridgeState();
  }

  if (subscription) {
    state.listening = true;
    return getAndroidBleRuntimeBridgeState();
  }

  try {
    const emitter = new NativeEventEmitter(nativeModule as never);

    subscription = emitter.addListener(EVENT_NAME, (payload: Record<string, unknown>) => {
      ingestBleProofEvent(payload ?? {});
    });

    state.listening = true;
    state.lastError = undefined;
  } catch (error) {
    state.listening = false;
    state.lastError = error instanceof Error ? error.message : String(error);
  }

  return getAndroidBleRuntimeBridgeState();
}

export function stopAndroidBleRuntimeBridge(): BridgeState {
  if (subscription) {
    subscription.remove();
    subscription = null;
  }

  state.listening = false;
  return getAndroidBleRuntimeBridgeState();
}

export async function requestNativeBleStatus(): Promise<Record<string, unknown>> {
  const nativeModule = getNativeBleModule() as
    | {
        getStatus?: () => Promise<Record<string, unknown>>;
        getBleStatus?: () => Promise<Record<string, unknown>>;
        startScan?: () => Promise<Record<string, unknown>>;
      }
    | null;

  if (!nativeModule) {
    return {
      ok: false,
      reason: "MauriMeshBleModule not available.",
    };
  }

  try {
    if (typeof nativeModule.getStatus === "function") {
      return await nativeModule.getStatus();
    }

    if (typeof nativeModule.getBleStatus === "function") {
      return await nativeModule.getBleStatus();
    }

    return {
      ok: true,
      reason: "Native module present, but no status method exposed.",
    };
  } catch (error) {
    return {
      ok: false,
      reason: error instanceof Error ? error.message : String(error),
    };
  }
}

export function getAndroidBleRuntimeProofSnapshot(): {
  bridge: BridgeState;
  summary: ReturnType<typeof getBleProofSummary>;
  events: BleProofEvent[];
} {
  return {
    bridge: getAndroidBleRuntimeBridgeState(),
    summary: getBleProofSummary(),
    events: getBleProofEvents().slice(0, 50),
  };
}
TS

echo ""
echo "3. Create dashboard bridge data module"

cat > "$ROOT/src/mauricore/dashboard/bleRuntimeBridgeDashboard.ts" <<'TS'
import {
  getAndroidBleRuntimeBridgeState,
  getAndroidBleRuntimeProofSnapshot,
  startAndroidBleRuntimeBridge,
} from "../bridges/androidBleRuntimeBridge";

export function getBleRuntimeBridgeDashboardData() {
  const started = startAndroidBleRuntimeBridge();
  const snapshot = getAndroidBleRuntimeProofSnapshot();

  return {
    started,
    bridge: getAndroidBleRuntimeBridgeState(),
    summary: snapshot.summary,
    events: snapshot.events,
    acceptance: {
      nativeModulePresent: snapshot.bridge.nativeModulePresent,
      eventListenerActive: snapshot.bridge.listening,
      hasProofEvents: snapshot.summary.total > 0,
      readyForPhysicalProof:
        snapshot.bridge.nativeModulePresent && snapshot.bridge.listening,
    },
  };
}
TS

echo ""
echo "4. Create BLE runtime bridge screen"

cat > "$ROOT/src/mauricore/dashboard/MauriCoreBleRuntimeScreen.tsx" <<'TSX'
import React, { useMemo, useState } from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { getBleRuntimeBridgeDashboardData } from "./bleRuntimeBridgeDashboard";
import { requestNativeBleStatus } from "../bridges/androidBleRuntimeBridge";

function Pill({ label, ok }: { label: string; ok: boolean }) {
  return (
    <View style={[styles.pill, { borderColor: ok ? "#00D084" : "#F59E0B" }]}>
      <Text style={[styles.pillText, { color: ok ? "#00D084" : "#F59E0B" }]}>
        {label}
      </Text>
    </View>
  );
}

export default function MauriCoreBleRuntimeScreen() {
  const router = useRouter();
  const [refresh, setRefresh] = useState(0);
  const [nativeStatus, setNativeStatus] = useState<Record<string, unknown> | null>(null);

  const data = useMemo(() => getBleRuntimeBridgeDashboardData(), [refresh]);

  async function checkNativeStatus() {
    const result = await requestNativeBleStatus();
    setNativeStatus(result);
    setRefresh((value) => value + 1);
  }

  return (
    <ScrollView style={styles.safe} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>MauriCore Android BLE Runtime</Text>
      <Text style={styles.code}>NATIVE_BLE_RUNTIME_BRIDGE</Text>

      <View style={styles.row}>
        <Pill
          label={data.acceptance.nativeModulePresent ? "NATIVE_MODULE_PRESENT" : "NATIVE_MODULE_MISSING"}
          ok={data.acceptance.nativeModulePresent}
        />
        <Pill
          label={data.acceptance.eventListenerActive ? "EVENT_LISTENER_ACTIVE" : "EVENT_LISTENER_INACTIVE"}
          ok={data.acceptance.eventListenerActive}
        />
        <Pill
          label={data.acceptance.hasProofEvents ? "PROOF_EVENTS_SEEN" : "WAITING_FOR_PROOF_EVENTS"}
          ok={data.acceptance.hasProofEvents}
        />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Bridge State</Text>
        <Text style={styles.line}>Platform: {data.bridge.platform}</Text>
        <Text style={styles.line}>Event: {data.bridge.eventName}</Text>
        <Text style={styles.line}>Native module: {String(data.bridge.nativeModulePresent)}</Text>
        <Text style={styles.line}>Listening: {String(data.bridge.listening)}</Text>
        {data.bridge.lastError ? (
          <Text style={styles.warn}>Warning: {data.bridge.lastError}</Text>
        ) : null}
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Proof Event Summary</Text>
        <Text style={styles.line}>Total: {data.summary.total}</Text>
        <Text style={styles.line}>RX packets: {data.summary.rxPackets}</Text>
        <Text style={styles.line}>TX packets: {data.summary.txPackets}</Text>
        <Text style={styles.line}>ACK sent: {data.summary.ackSent}</Text>
        <Text style={styles.line}>ACK received: {data.summary.ackReceived}</Text>
        <Text style={styles.line}>Scan events: {data.summary.scanEvents}</Text>
        <Text style={styles.line}>Proof-ready events: {data.summary.proofReady}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Native Status</Text>
        <Pressable style={styles.button} onPress={checkNativeStatus}>
          <Text style={styles.buttonText}>Check Native BLE Status</Text>
        </Pressable>
        {nativeStatus ? (
          <Text style={styles.mono}>{JSON.stringify(nativeStatus, null, 2)}</Text>
        ) : (
          <Text style={styles.line}>No native status requested yet.</Text>
        )}
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Recent Native Proof Events</Text>
        {data.events.length === 0 ? (
          <Text style={styles.warn}>
            No native BLE proof events received yet. This is expected until the APK runs on a physical Android phone and BLE activity occurs.
          </Text>
        ) : (
          data.events.map((event) => (
            <View key={event.id} style={styles.event}>
              <Text style={styles.eventTitle}>{event.kind}</Text>
              <Text style={styles.line}>Packet: {event.packetId ?? "none"}</Text>
              <Text style={styles.line}>Peer: {event.peerId ?? "none"}</Text>
              <Text style={styles.line}>Time: {event.timestamp}</Text>
            </View>
          ))
        )}
      </View>

      <Pressable style={styles.backButton} onPress={() => router.back()}>
        <Text style={styles.backText}>Back</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: "#020617" },
  content: { padding: 20, paddingBottom: 44 },
  brand: {
    color: "#00D084",
    fontSize: 32,
    fontWeight: "900",
    marginTop: 18,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 25,
    fontWeight: "900",
    marginTop: 18,
  },
  code: {
    color: "#38BDF8",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1,
    marginTop: 8,
    marginBottom: 18,
  },
  row: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 12 },
  pill: {
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: "rgba(255,255,255,0.04)",
  },
  pillText: { fontSize: 11, fontWeight: "900" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.25)",
    backgroundColor: "rgba(0,40,34,0.72)",
    borderRadius: 18,
    padding: 16,
    marginTop: 12,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900", marginBottom: 10 },
  line: {
    color: "rgba(255,255,255,0.78)",
    fontSize: 14,
    lineHeight: 21,
    fontWeight: "600",
  },
  warn: {
    color: "#F59E0B",
    fontSize: 14,
    lineHeight: 21,
    fontWeight: "800",
  },
  mono: {
    color: "#CFFAFE",
    fontSize: 12,
    lineHeight: 18,
    fontWeight: "700",
    marginTop: 10,
  },
  event: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    marginTop: 10,
    paddingTop: 10,
  },
  eventTitle: { color: "#00D084", fontSize: 14, fontWeight: "900" },
  button: {
    minHeight: 48,
    borderRadius: 14,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 10,
  },
  buttonText: { color: "#020617", fontSize: 15, fontWeight: "900" },
  backButton: {
    marginTop: 18,
    minHeight: 52,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#00D084",
  },
  backText: { color: "#020617", fontWeight: "900", fontSize: 16 },
});
TSX

echo ""
echo "5. Create Expo route"

cat > "$ROOT/app/mauricore-ble-runtime.tsx" <<'TSX'
export { default } from "../src/mauricore/dashboard/MauriCoreBleRuntimeScreen";
TSX

echo ""
echo "6. Verify native Kotlin event markers"

RX_COUNT=$(grep -c '"rx_packet"' "$BLE_KT" || true)
ACK_COUNT=$(grep -c '"ack_sent"' "$BLE_KT" || true)
EVENT_COUNT=$(grep -c 'MauriMeshRawPacketProofEvent' "$BLE_KT" || true)

echo "rx_packet count: $RX_COUNT"
echo "ack_sent count: $ACK_COUNT"
echo "MauriMeshRawPacketProofEvent count: $EVENT_COUNT"

if [ "$RX_COUNT" -ne 1 ]; then
  echo "ERROR: Expected exactly one rx_packet marker."
  exit 1
fi

if [ "$ACK_COUNT" -ne 1 ]; then
  echo "ERROR: Expected exactly one ack_sent marker."
  exit 1
fi

if [ "$EVENT_COUNT" -lt 1 ]; then
  echo "ERROR: Missing MauriMeshRawPacketProofEvent emitter marker."
  exit 1
fi

echo ""
echo "7. Run TypeScript check"
npm run mauricore:check

echo ""
echo "8. Run MauriCore smoke test"
npm run mauricore:test

echo ""
echo "9. Run Expo Android export"
npx expo export --platform android --output-dir dist-mauricore-ble-runtime-bridge

echo ""
echo "============================================================"
echo "MAURICORE ANDROID BLE RUNTIME BRIDGE INSTALLED"
echo "New route:"
echo "  /mauricore-ble-runtime"
echo ""
echo "Reality boundary:"
echo "  Replit export proves JS/UI compilation only."
echo "  Real BLE proof requires APK on physical Android phones."
echo "============================================================"
