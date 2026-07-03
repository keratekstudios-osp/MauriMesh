#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#190 — HARDWARE PROOF EVENTS TO LIVE METRICS SPINE"
echo "Feeds raw packet proof attempts/RX/ACK/failure into shared UI metrics"
echo "Targets: delivery, ACK, latency, store-forward, route health proof screens"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-190-proof-metrics-$STAMP"

mkdir -p "$BACKUP" \
  "$ROOT/src/maurimesh/live" \
  "$ROOT/src/maurimesh/proof" \
  "$ROOT/app" \
  "$ROOT/scripts" \
  "$ROOT/docs" \
  "$ROOT/tests/proof"

echo ""
echo "1. Backup likely active files"

for f in \
  app/raw-packet-proof.tsx \
  app/ble-proof.tsx \
  app/delivery-analytics.tsx \
  app/ack-tracking.tsx \
  app/store-forward-queue.tsx \
  app/latency-monitoring.tsx \
  app/route-health.tsx \
  app/proof-ledger.tsx \
  src/maurimesh/ble/rawPacketProofClient.ts \
  src/maurimesh/live/proofMetricsSpine.ts \
  src/maurimesh/live/useProofMetrics.ts
do
  if [ -f "$ROOT/$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$ROOT/$f" "$BACKUP/$f"
    echo "Backed up: $f"
  fi
done

echo "Backup: $BACKUP"

echo ""
echo "2. Install shared proof metrics spine"

cat > "$ROOT/src/maurimesh/live/proofMetricsSpine.ts" <<'TS'
import AsyncStorage from "@react-native-async-storage/async-storage";

export const TASK_190_PROOF_METRICS_SPINE_MARKER =
  "TASK_190_PROOF_METRICS_SPINE_20260608_A";

const STORAGE_KEY = "maurimesh.proof.metrics.spine.v1";

export type ProofMetricEventType =
  | "send_attempt"
  | "send_submitted"
  | "rx_packet"
  | "ack_sent"
  | "ack_received"
  | "delivery_failed"
  | "relay_hop"
  | "store_forward_enqueued"
  | "store_forward_released";

export type ProofMetricEvent = {
  id: string;
  type: ProofMetricEventType;
  packetId: string;
  at: number;
  fromNode?: string;
  toNode?: string;
  transport?: "BLE" | "WIFI_DIRECT" | "LOCAL_WIFI" | "INTERNET" | "UNKNOWN";
  latencyMs?: number;
  relayHopCount?: number;
  peerId?: string;
  reason?: string;
  payloadBytes?: number;
  raw?: unknown;
};

export type ProofMetricsSnapshot = {
  marker: string;
  truthLevel: "physical_proof";
  updatedAt: number;

  attempted: number;
  delivered: number;
  acknowledged: number;
  failed: number;
  inTransit: number;

  ackRate: number;
  successRate: number;
  relayHops: number;
  avgLatencyMs: number;

  storeForwardTotal: number;
  storeForwardPending: number;
  storeForwardFailed: number;

  packetLossPercent: number;
  reachablePeers: number;
  knownPeers: number;

  events: ProofMetricEvent[];
};

const emptySnapshot = (): ProofMetricsSnapshot => ({
  marker: TASK_190_PROOF_METRICS_SPINE_MARKER,
  truthLevel: "physical_proof",
  updatedAt: Date.now(),

  attempted: 0,
  delivered: 0,
  acknowledged: 0,
  failed: 0,
  inTransit: 0,

  ackRate: 0,
  successRate: 0,
  relayHops: 0,
  avgLatencyMs: 0,

  storeForwardTotal: 0,
  storeForwardPending: 0,
  storeForwardFailed: 0,

  packetLossPercent: 0,
  reachablePeers: 0,
  knownPeers: 0,

  events: [],
});

function uniquePacketCount(events: ProofMetricEvent[], type: ProofMetricEventType): number {
  return new Set(events.filter((e) => e.type === type).map((e) => e.packetId)).size;
}

function count(events: ProofMetricEvent[], type: ProofMetricEventType): number {
  return events.filter((e) => e.type === type).length;
}

function calculate(events: ProofMetricEvent[]): ProofMetricsSnapshot {
  const latest = events.slice(-500);

  const attempted = uniquePacketCount(latest, "send_attempt");
  const submitted = uniquePacketCount(latest, "send_submitted");
  const rx = uniquePacketCount(latest, "rx_packet");
  const ackSent = uniquePacketCount(latest, "ack_sent");
  const ackReceived = uniquePacketCount(latest, "ack_received");
  const failed = uniquePacketCount(latest, "delivery_failed");

  const delivered = Math.max(rx, ackReceived);
  const acknowledged = Math.max(ackSent, ackReceived);
  const inTransit = Math.max(0, submitted - delivered - failed);

  const latencies = latest
    .map((e) => e.latencyMs)
    .filter((n): n is number => typeof n === "number" && Number.isFinite(n) && n >= 0);

  const avgLatencyMs =
    latencies.length > 0
      ? Math.round(latencies.reduce((sum, n) => sum + n, 0) / latencies.length)
      : 0;

  const relayHops = latest.reduce((sum, e) => sum + (e.relayHopCount || 0), 0);

  const storeForwardTotal = count(latest, "store_forward_enqueued");
  const storeForwardReleased = count(latest, "store_forward_released");
  const storeForwardFailed = count(latest, "delivery_failed");
  const storeForwardPending = Math.max(0, storeForwardTotal - storeForwardReleased - storeForwardFailed);

  const ackRate = attempted > 0 ? Math.round((acknowledged / attempted) * 100) : 0;
  const successRate = attempted > 0 ? Math.round((delivered / attempted) * 100) : 0;
  const packetLossPercent = attempted > 0 ? Math.round((failed / attempted) * 100) : 0;

  const peerSet = new Set<string>();
  latest.forEach((e) => {
    if (e.peerId) peerSet.add(e.peerId);
    if (e.fromNode) peerSet.add(e.fromNode);
    if (e.toNode) peerSet.add(e.toNode);
  });

  return {
    ...emptySnapshot(),
    updatedAt: Date.now(),
    attempted,
    delivered,
    acknowledged,
    failed,
    inTransit,
    ackRate,
    successRate,
    relayHops,
    avgLatencyMs,
    storeForwardTotal,
    storeForwardPending,
    storeForwardFailed,
    packetLossPercent,
    reachablePeers: peerSet.size,
    knownPeers: peerSet.size,
    events: latest,
  };
}

async function readEvents(): Promise<ProofMetricEvent[]> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

async function writeEvents(events: ProofMetricEvent[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(events.slice(-500)));
}

export async function getProofMetricsSnapshot(): Promise<ProofMetricsSnapshot> {
  const events = await readEvents();
  return calculate(events);
}

export async function recordProofMetricEvent(
  event: Omit<ProofMetricEvent, "id" | "at">
): Promise<ProofMetricsSnapshot> {
  const events = await readEvents();

  const next: ProofMetricEvent = {
    ...event,
    id: `pm_${Date.now()}_${Math.random().toString(16).slice(2)}`,
    at: Date.now(),
    transport: event.transport || "BLE",
  };

  const updated = [...events, next].slice(-500);
  await writeEvents(updated);

  return calculate(updated);
}

export async function clearProofMetrics(): Promise<ProofMetricsSnapshot> {
  await writeEvents([]);
  return emptySnapshot();
}

export function makeProofPacketId(prefix = "MM-PROOF"): string {
  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;
}
TS

echo ""
echo "3. Install React hook for live proof metrics"

cat > "$ROOT/src/maurimesh/live/useProofMetrics.ts" <<'TS'
import { useCallback, useEffect, useState } from "react";
import {
  clearProofMetrics,
  getProofMetricsSnapshot,
  ProofMetricsSnapshot,
  recordProofMetricEvent,
  ProofMetricEvent,
} from "./proofMetricsSpine";

export const TASK_190_USE_PROOF_METRICS_MARKER =
  "TASK_190_USE_PROOF_METRICS_20260608_A";

export function useProofMetrics(pollMs = 1500) {
  const [snapshot, setSnapshot] = useState<ProofMetricsSnapshot | null>(null);

  const refresh = useCallback(async () => {
    const next = await getProofMetricsSnapshot();
    setSnapshot(next);
    return next;
  }, []);

  const record = useCallback(
    async (event: Omit<ProofMetricEvent, "id" | "at">) => {
      const next = await recordProofMetricEvent(event);
      setSnapshot(next);
      return next;
    },
    []
  );

  const clear = useCallback(async () => {
    const next = await clearProofMetrics();
    setSnapshot(next);
    return next;
  }, []);

  useEffect(() => {
    let alive = true;

    getProofMetricsSnapshot().then((next) => {
      if (alive) setSnapshot(next);
    });

    const timer = setInterval(() => {
      getProofMetricsSnapshot().then((next) => {
        if (alive) setSnapshot(next);
      });
    }, pollMs);

    return () => {
      alive = false;
      clearInterval(timer);
    };
  }, [pollMs]);

  return {
    marker: TASK_190_USE_PROOF_METRICS_MARKER,
    snapshot,
    refresh,
    record,
    clear,
  };
}
TS

echo ""
echo "4. Install proof metrics screen"

cat > "$ROOT/app/proof-metrics.tsx" <<'TSX'
import React from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { clearProofMetrics } from "../src/maurimesh/live/proofMetricsSpine";
import { useProofMetrics } from "../src/maurimesh/live/useProofMetrics";

const MARKER = "TASK_190_PROOF_METRICS_SCREEN_20260608_A";

function Stat({ label, value }: { label: string; value: string | number }) {
  return (
    <View style={styles.stat}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

export default function ProofMetricsScreen() {
  const { snapshot, refresh } = useProofMetrics(1000);

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Proof Metrics Spine</Text>
      <Text style={styles.subtitle}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Delivery / ACK</Text>
        <View style={styles.grid}>
          <Stat label="Attempted" value={snapshot?.attempted ?? 0} />
          <Stat label="Delivered" value={snapshot?.delivered ?? 0} />
          <Stat label="ACKed" value={snapshot?.acknowledged ?? 0} />
          <Stat label="Failed" value={snapshot?.failed ?? 0} />
          <Stat label="Success %" value={`${snapshot?.successRate ?? 0}%`} />
          <Stat label="ACK %" value={`${snapshot?.ackRate ?? 0}%`} />
        </View>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Transport</Text>
        <Text style={styles.line}>Reachable peers: {snapshot?.reachablePeers ?? 0}</Text>
        <Text style={styles.line}>Known peers: {snapshot?.knownPeers ?? 0}</Text>
        <Text style={styles.line}>Relay hops: {snapshot?.relayHops ?? 0}</Text>
        <Text style={styles.line}>Avg latency: {snapshot?.avgLatencyMs ?? 0} ms</Text>
        <Text style={styles.line}>Packet loss: {snapshot?.packetLossPercent ?? 0}%</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Store-Forward</Text>
        <Text style={styles.line}>Total: {snapshot?.storeForwardTotal ?? 0}</Text>
        <Text style={styles.line}>Pending: {snapshot?.storeForwardPending ?? 0}</Text>
        <Text style={styles.line}>Failed: {snapshot?.storeForwardFailed ?? 0}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Recent Events</Text>
        {(snapshot?.events || []).slice(-20).reverse().map((event) => (
          <Text key={event.id} style={styles.event}>
            {event.type} · {event.packetId} · {event.transport || "BLE"}
          </Text>
        ))}
        {(snapshot?.events || []).length === 0 ? (
          <Text style={styles.muted}>No proof metric events recorded yet.</Text>
        ) : null}
      </View>

      <Pressable
        style={styles.button}
        onPress={async () => {
          await refresh();
        }}
      >
        <Text style={styles.buttonText}>Refresh</Text>
      </Pressable>

      <Pressable
        style={[styles.button, styles.danger]}
        onPress={async () => {
          await clearProofMetrics();
          await refresh();
        }}
      >
        <Text style={styles.buttonText}>Clear Local Proof Metrics</Text>
      </Pressable>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          These metrics only change when proof events are recorded by real send/RX/ACK
          actions or local proof instrumentation. Physical delivery still requires
          two Android phones and log proof.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 36, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 28, fontWeight: "900" },
  subtitle: { color: "#38BDF8", fontSize: 12, fontWeight: "800" },
  card: {
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.26)",
    backgroundColor: "rgba(255,255,255,0.045)",
    borderRadius: 18,
    padding: 16,
    gap: 10,
  },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  grid: { flexDirection: "row", flexWrap: "wrap", gap: 10 },
  stat: {
    minWidth: "30%",
    flexGrow: 1,
    borderRadius: 14,
    backgroundColor: "rgba(255,255,255,0.05)",
    padding: 12,
  },
  statValue: { color: "#00D084", fontSize: 24, fontWeight: "900", textAlign: "center" },
  statLabel: { color: "rgba(255,255,255,0.65)", fontSize: 12, fontWeight: "700", textAlign: "center" },
  line: { color: "rgba(255,255,255,0.78)", fontSize: 15, lineHeight: 22 },
  event: { color: "#D1FAE5", fontSize: 12, lineHeight: 18 },
  muted: { color: "rgba(255,255,255,0.55)", lineHeight: 20 },
  button: {
    minHeight: 52,
    borderRadius: 16,
    backgroundColor: "#00D084",
    alignItems: "center",
    justifyContent: "center",
  },
  danger: { backgroundColor: "#EF4444" },
  buttonText: { color: "#FFFFFF", fontWeight: "900" },
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
echo "5. Patch raw-packet-proof screen to record send/fail/delivery proof events"

if [ -f "$ROOT/app/raw-packet-proof.tsx" ]; then
python3 <<'PY'
from pathlib import Path

path = Path("app/raw-packet-proof.tsx")
text = path.read_text()
original = text

if "recordProofMetricEvent" not in text:
    text = text.replace(
        'import React, { useState } from "react";',
        'import React, { useState } from "react";\nimport { makeProofPacketId, recordProofMetricEvent } from "../src/maurimesh/live/proofMetricsSpine";',
        1,
    )

if "TASK_190_RAW_PACKET_PROOF_METRICS_WIRE" not in text:
    text = text.replace(
        'const MARKER = "TASK_165B_RAW_PACKET_PROOF_SCREEN_20260608_A";',
        'const MARKER = "TASK_165B_RAW_PACKET_PROOF_SCREEN_20260608_A";\nconst TASK_190_RAW_PACKET_PROOF_METRICS_WIRE = "TASK_190_RAW_PACKET_PROOF_METRICS_WIRE_20260608_A";',
        1,
    )

old = '''const payload = makeProofPayload("PHONE_TO_PHONE");
            const ok = await sendRawPacketUtf8(target.trim(), payload);
            return { ok, target: target.trim(), payload };'''

new = '''const packetId = makeProofPacketId("MM-RAW");
            const payload = `${packetId}|${makeProofPayload("PHONE_TO_PHONE")}`;
            await recordProofMetricEvent({
              type: "send_attempt",
              packetId,
              toNode: target.trim(),
              transport: "BLE",
              payloadBytes: payload.length,
            });
            const ok = await sendRawPacketUtf8(target.trim(), payload);
            await recordProofMetricEvent({
              type: ok ? "send_submitted" : "delivery_failed",
              packetId,
              toNode: target.trim(),
              transport: "BLE",
              payloadBytes: payload.length,
              reason: ok ? undefined : "sendRawPacketUtf8 returned false",
            });
            return { ok, target: target.trim(), packetId, payload };'''

if old in text and "sendRawPacketUtf8 returned false" not in text:
    text = text.replace(old, new)

path.write_text(text)

print("raw-packet-proof patched" if text != original else "raw-packet-proof unchanged")
PY
else
  echo "WARN: app/raw-packet-proof.tsx not found"
fi

echo ""
echo "6. Patch ble-proof Save screen to record ledger save as ACK/delivery evidence"

if [ -f "$ROOT/app/ble-proof.tsx" ]; then
python3 <<'PY'
from pathlib import Path

path = Path("app/ble-proof.tsx")
text = path.read_text()
original = text

if "recordProofMetricEvent" not in text:
    text = text.replace(
        'import React',
        'import { makeProofPacketId, recordProofMetricEvent } from "../src/maurimesh/live/proofMetricsSpine";\nimport React',
        1,
    )

if "TASK_190_BLE_PROOF_LEDGER_METRICS_WIRE" not in text:
    text = text.replace(
        'const TASK_189B_BLE_PROOF_SAVE_TO_LEDGER',
        'const TASK_190_BLE_PROOF_LEDGER_METRICS_WIRE = "TASK_190_BLE_PROOF_LEDGER_METRICS_WIRE_20260608_A";\nconst TASK_189B_BLE_PROOF_SAVE_TO_LEDGER',
        1,
    )

# Add a safe helper if not present.
if "recordLedgerSaveProofMetric" not in text:
    marker = "export default function"
    helper = '''
async function recordLedgerSaveProofMetric(ok: boolean, raw?: unknown) {
  const packetId = makeProofPacketId("MM-LEDGER");
  await recordProofMetricEvent({
    type: ok ? "ack_received" : "delivery_failed",
    packetId,
    fromNode: "proof-ledger",
    toNode: "local-device",
    transport: "BLE",
    reason: ok ? undefined : "ledger save failed",
    raw,
  });
}

'''
    text = text.replace(marker, helper + marker, 1)

# Best-effort: after successful save state text exists, record metric around apiPost if pattern exists.
if "recordLedgerSaveProofMetric(true" not in text:
    text = text.replace(
        "setSave(body.entry);",
        "setSave(body.entry);\n      await recordLedgerSaveProofMetric(true, body.entry);",
        1,
    )
    text = text.replace(
        "setError(message);",
        "setError(message);\n      await recordLedgerSaveProofMetric(false, message);",
        1,
    )

path.write_text(text)

print("ble-proof patched" if text != original else "ble-proof unchanged")
PY
else
  echo "WARN: app/ble-proof.tsx not found"
fi

echo ""
echo "7. Patch dashboard with Proof Metrics link if dashboard exists"

if [ -f "$ROOT/app/dashboard.tsx" ]; then
python3 <<'PY'
from pathlib import Path

path = Path("app/dashboard.tsx")
text = path.read_text()
original = text

if '"/proof-metrics"' not in text:
    if '["Proof Ledger", "/proof-ledger"]' in text:
        text = text.replace(
            '["Proof Ledger", "/proof-ledger"]',
            '["Proof Ledger", "/proof-ledger"],\n  ["Proof Metrics", "/proof-metrics"]',
            1,
        )
    elif "Proof Ledger" in text:
        text = text.replace("Proof Ledger", "Proof Ledger", 1)
    else:
        # leave route available even if dashboard pattern is unknown
        pass

path.write_text(text)
print("dashboard patched" if text != original else "dashboard unchanged")
PY
else
  echo "WARN: app/dashboard.tsx not found"
fi

echo ""
echo "8. Add pure proof metrics test"

cat > "$ROOT/tests/proof/task-190-proof-metrics-spine.test.ts" <<'TS'
import {
  TASK_190_PROOF_METRICS_SPINE_MARKER,
  makeProofPacketId,
} from "../../src/maurimesh/live/proofMetricsSpine";

if (TASK_190_PROOF_METRICS_SPINE_MARKER !== "TASK_190_PROOF_METRICS_SPINE_20260608_A") {
  throw new Error("Wrong metrics marker");
}

const packetId = makeProofPacketId("MM-TEST");

if (!packetId.startsWith("MM-TEST-")) {
  throw new Error("Packet id generator failed");
}

console.log("PASS: TASK_190_PROOF_METRICS_SPINE_STATIC_TEST_20260608_A");
TS

echo ""
echo "9. Add audit script"

cat > "$ROOT/scripts/audit-task-190-proof-metrics.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#190 Proof Metrics Spine Audit"
echo "============================================================"

grep -RniE "TASK_190|recordProofMetricEvent|Proof Metrics|proofMetricsSpine|useProofMetrics|send_attempt|ack_received|delivery_failed" \
  app src tests scripts docs 2>/dev/null || true

echo ""
echo "Required checks:"
test -f src/maurimesh/live/proofMetricsSpine.ts && echo "✅ proofMetricsSpine.ts"
test -f src/maurimesh/live/useProofMetrics.ts && echo "✅ useProofMetrics.ts"
test -f app/proof-metrics.tsx && echo "✅ proof metrics screen"
grep -q "recordProofMetricEvent" app/raw-packet-proof.tsx && echo "✅ raw packet proof records metrics"
grep -q "Proof Metrics" app/proof-metrics.tsx && echo "✅ proof metrics UI present"
SH

chmod +x "$ROOT/scripts/audit-task-190-proof-metrics.sh"

echo ""
echo "10. Docs"

cat > "$ROOT/docs/task-190-proof-events-to-live-metrics.md" <<'MD'
# Task #190 — Hardware Proof Events to Live Metrics Spine

Marker: `TASK_190_PROOF_METRICS_SPINE_20260608_A`

## Installed

- Shared proof metrics spine.
- Persistent local proof metric events.
- `useProofMetrics()` live hook.
- `/proof-metrics` screen.
- Raw packet proof send attempts record:
  - `send_attempt`
  - `send_submitted`
  - `delivery_failed`
- BLE proof ledger save can record:
  - `ack_received`
  - `delivery_failed`

## What this changes

Screens that previously showed zero delivery/ACK metrics now have a live spine that can be consumed by delivery, ACK, latency, store-forward, and route-health screens.

## Truth boundary

This records proof events only when instrumentation runs.

It still does not claim real delivery until:
- Phone A sends raw packet
- Phone B logs `RX_RAW_PACKET`
- Phone B logs `ACK_SENT=true`
- Phone A receives ACK
- Evidence is saved to Proof Ledger
MD

echo ""
echo "11. Run audit"
bash "$ROOT/scripts/audit-task-190-proof-metrics.sh"

echo ""
echo "12. Run static proof metrics test"
npx tsx "$ROOT/tests/proof/task-190-proof-metrics-spine.test.ts"

echo ""
echo "13. TypeScript check"
npx tsc --noEmit

echo ""
echo "14. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "#190 PROOF EVENTS TO LIVE METRICS SPINE INSTALLED"
echo "Backup: $BACKUP"
echo "Open route after build: /proof-metrics"
echo "Next physical step: run /raw-packet-proof on two phones and watch metrics rise."
echo "============================================================"
