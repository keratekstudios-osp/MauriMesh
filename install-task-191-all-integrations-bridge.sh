#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#191 — ALL INTEGRATIONS BRIDGE"
echo "Connects proof metrics into delivery, ACK, latency, queue, route health, and integration hub"
echo "No fake physical proof. Metrics rise only from recorded proof events."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-191-all-integrations-$STAMP"

mkdir -p "$BACKUP/app" "$BACKUP/src" \
  "$ROOT/app" \
  "$ROOT/src/maurimesh/integration" \
  "$ROOT/src/maurimesh/live" \
  "$ROOT/scripts" \
  "$ROOT/docs" \
  "$ROOT/tests/integration"

echo ""
echo "1. Backup integration screens"

for f in \
  app/dashboard.tsx \
  app/integration-hub.tsx \
  app/delivery-analytics.tsx \
  app/ack-tracking.tsx \
  app/store-forward-queue.tsx \
  app/latency-monitoring.tsx \
  app/route-health.tsx \
  app/proof-metrics.tsx \
  src/maurimesh/integration/allIntegrationsBridge.ts
do
  if [ -f "$ROOT/$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$ROOT/$f" "$BACKUP/$f"
    echo "Backed up: $f"
  fi
done

echo "Backup: $BACKUP"

echo ""
echo "2. Install all integrations bridge"

cat > "$ROOT/src/maurimesh/integration/allIntegrationsBridge.ts" <<'TS'
import {
  getProofMetricsSnapshot,
  ProofMetricsSnapshot,
} from "../live/proofMetricsSpine";

export const TASK_191_ALL_INTEGRATIONS_BRIDGE_MARKER =
  "TASK_191_ALL_INTEGRATIONS_BRIDGE_20260608_A";

export type IntegrationStatus =
  | "wired"
  | "ready_for_apk"
  | "physical_proof_required"
  | "no_data_yet";

export type AllIntegrationsSnapshot = {
  marker: string;
  updatedAt: number;
  truthLevel: "physical_proof";
  proofMetrics: ProofMetricsSnapshot;
  deliveryAnalytics: {
    delivered: number;
    failed: number;
    successRate: number;
    attempted: number;
    acknowledged: number;
    relayHops: number;
    avgLatencyMs: number;
    status: IntegrationStatus;
  };
  ackTracking: {
    delivered: number;
    acked: number;
    inTransit: number;
    ackRate: number;
    status: IntegrationStatus;
  };
  storeForward: {
    total: number;
    pending: number;
    failed: number;
    reachablePeers: number;
    relayCount: number;
    deliveryCount: number;
    status: IntegrationStatus;
  };
  latency: {
    avgLatencyMs: number;
    samples: number;
    failures: number;
    reachablePeers: number;
    status: IntegrationStatus;
  };
  routeHealth: {
    healthGood: number;
    healthWeak: number;
    healthPoor: number;
    packetLossPercent: number;
    relayHops: number;
    status: IntegrationStatus;
  };
  nextPhysicalProof: string[];
};

function statusFrom(metrics: ProofMetricsSnapshot): IntegrationStatus {
  if (metrics.attempted === 0 && metrics.events.length === 0) return "no_data_yet";
  if (metrics.delivered > 0 || metrics.acknowledged > 0) return "wired";
  return "physical_proof_required";
}

export async function getAllIntegrationsSnapshot(): Promise<AllIntegrationsSnapshot> {
  const metrics = await getProofMetricsSnapshot();
  const status = statusFrom(metrics);

  const healthGood = metrics.successRate >= 80 && metrics.packetLossPercent <= 10 ? 1 : 0;
  const healthWeak =
    metrics.attempted > 0 && metrics.successRate >= 40 && metrics.successRate < 80 ? 1 : 0;
  const healthPoor =
    metrics.attempted > 0 && (metrics.successRate < 40 || metrics.packetLossPercent > 50) ? 1 : 0;

  return {
    marker: TASK_191_ALL_INTEGRATIONS_BRIDGE_MARKER,
    updatedAt: Date.now(),
    truthLevel: "physical_proof",
    proofMetrics: metrics,
    deliveryAnalytics: {
      delivered: metrics.delivered,
      failed: metrics.failed,
      successRate: metrics.successRate,
      attempted: metrics.attempted,
      acknowledged: metrics.acknowledged,
      relayHops: metrics.relayHops,
      avgLatencyMs: metrics.avgLatencyMs,
      status,
    },
    ackTracking: {
      delivered: metrics.delivered,
      acked: metrics.acknowledged,
      inTransit: metrics.inTransit,
      ackRate: metrics.ackRate,
      status,
    },
    storeForward: {
      total: metrics.storeForwardTotal,
      pending: metrics.storeForwardPending,
      failed: metrics.storeForwardFailed,
      reachablePeers: metrics.reachablePeers,
      relayCount: metrics.relayHops,
      deliveryCount: metrics.delivered,
      status,
    },
    latency: {
      avgLatencyMs: metrics.avgLatencyMs,
      samples: metrics.events.filter((event) => typeof event.latencyMs === "number").length,
      failures: metrics.failed,
      reachablePeers: metrics.reachablePeers,
      status,
    },
    routeHealth: {
      healthGood,
      healthWeak,
      healthPoor,
      packetLossPercent: metrics.packetLossPercent,
      relayHops: metrics.relayHops,
      status,
    },
    nextPhysicalProof: [
      "Install latest APK on two phones.",
      "Open /raw-packet-proof on both phones.",
      "Start receiver on both phones.",
      "Send proof packet from Phone A to Phone B.",
      "Capture Phone B RX_RAW_PACKET.",
      "Capture Phone B ACK_SENT=true.",
      "Capture Phone A ACK received.",
      "Open /ble-proof and save evidence to Proof Ledger.",
      "Open /proof-metrics and confirm metrics rise from recorded proof events.",
    ],
  };
}
TS

echo ""
echo "3. Install shared hook"

cat > "$ROOT/src/maurimesh/integration/useAllIntegrations.ts" <<'TS'
import { useEffect, useState } from "react";
import {
  AllIntegrationsSnapshot,
  getAllIntegrationsSnapshot,
} from "./allIntegrationsBridge";

export const TASK_191_USE_ALL_INTEGRATIONS_MARKER =
  "TASK_191_USE_ALL_INTEGRATIONS_20260608_A";

export function useAllIntegrations(pollMs = 1500) {
  const [snapshot, setSnapshot] = useState<AllIntegrationsSnapshot | null>(null);

  useEffect(() => {
    let alive = true;

    async function load() {
      const next = await getAllIntegrationsSnapshot();
      if (alive) setSnapshot(next);
    }

    load();
    const timer = setInterval(load, pollMs);

    return () => {
      alive = false;
      clearInterval(timer);
    };
  }, [pollMs]);

  return {
    marker: TASK_191_USE_ALL_INTEGRATIONS_MARKER,
    snapshot,
  };
}
TS

echo ""
echo "4. Install integration hub screen"

cat > "$ROOT/app/integration-hub.tsx" <<'TSX'
import React from "react";
import { Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useRouter } from "expo-router";
import { useAllIntegrations } from "../src/maurimesh/integration/useAllIntegrations";

const MARKER = "TASK_191_INTEGRATION_HUB_SCREEN_20260608_A";

function Row({ label, value }: { label: string; value: string | number }) {
  return (
    <View style={styles.row}>
      <Text style={styles.rowLabel}>{label}</Text>
      <Text style={styles.rowValue}>{value}</Text>
    </View>
  );
}

function NavButton({ title, route }: { title: string; route: string }) {
  const router = useRouter();
  return (
    <Pressable style={styles.button} onPress={() => router.push(route as never)}>
      <Text style={styles.buttonText}>{title}</Text>
    </Pressable>
  );
}

export default function IntegrationHubScreen() {
  const { snapshot } = useAllIntegrations(1000);

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Integration Hub</Text>
      <Text style={styles.subtitle}>{MARKER}</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>All Integration Status</Text>
        <Row label="Delivery status" value={snapshot?.deliveryAnalytics.status || "loading"} />
        <Row label="ACK status" value={snapshot?.ackTracking.status || "loading"} />
        <Row label="Queue status" value={snapshot?.storeForward.status || "loading"} />
        <Row label="Latency status" value={snapshot?.latency.status || "loading"} />
        <Row label="Route health status" value={snapshot?.routeHealth.status || "loading"} />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Live Proof Metrics</Text>
        <Row label="Attempted" value={snapshot?.proofMetrics.attempted ?? 0} />
        <Row label="Delivered" value={snapshot?.proofMetrics.delivered ?? 0} />
        <Row label="ACKed" value={snapshot?.proofMetrics.acknowledged ?? 0} />
        <Row label="Failed" value={snapshot?.proofMetrics.failed ?? 0} />
        <Row label="Success %" value={`${snapshot?.proofMetrics.successRate ?? 0}%`} />
        <Row label="ACK %" value={`${snapshot?.proofMetrics.ackRate ?? 0}%`} />
      </View>

      <View style={styles.grid}>
        <NavButton title="Raw Packet Proof" route="/raw-packet-proof" />
        <NavButton title="BLE Proof" route="/ble-proof" />
        <NavButton title="Proof Metrics" route="/proof-metrics" />
        <NavButton title="Proof Ledger" route="/proof-ledger" />
        <NavButton title="Delivery Analytics" route="/delivery-analytics" />
        <NavButton title="ACK Tracking" route="/ack-tracking" />
        <NavButton title="Store-Forward Queue" route="/store-forward-queue" />
        <NavButton title="Latency Monitoring" route="/latency-monitoring" />
        <NavButton title="Route Health" route="/route-health" />
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          This hub wires the integration layer. It does not claim delivery until real
          TX/RX/ACK events are recorded by the hardware proof flow.
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
  row: { flexDirection: "row", justifyContent: "space-between", gap: 10 },
  rowLabel: { color: "rgba(255,255,255,0.72)", fontWeight: "700", flex: 1 },
  rowValue: { color: "#00D084", fontWeight: "900", textAlign: "right" },
  grid: { gap: 10 },
  button: {
    minHeight: 50,
    borderRadius: 16,
    backgroundColor: "rgba(0,208,132,0.14)",
    borderWidth: 1,
    borderColor: "rgba(0,208,132,0.4)",
    alignItems: "center",
    justifyContent: "center",
  },
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
echo "5. Install metric-backed delivery/ACK/queue/latency/route screens"

cat > "$ROOT/app/delivery-analytics.tsx" <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useAllIntegrations } from "../src/maurimesh/integration/useAllIntegrations";

export default function DeliveryAnalyticsScreen() {
  const { snapshot } = useAllIntegrations(1000);
  const data = snapshot?.deliveryAnalytics;

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Delivery Analytics</Text>
      <Text style={styles.subtitle}>End-to-end delivery outcomes</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Delivery Summary</Text>
        <Text style={styles.big}>{data?.delivered ?? 0}</Text>
        <Text style={styles.line}>Delivered</Text>
        <Text style={styles.line}>Failed: {data?.failed ?? 0}</Text>
        <Text style={styles.line}>Success: {data?.successRate ?? 0}%</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Delivery Breakdown</Text>
        <Text style={styles.line}>Attempted: {data?.attempted ?? 0}</Text>
        <Text style={styles.line}>Delivered: {data?.delivered ?? 0}</Text>
        <Text style={styles.line}>Acknowledged: {data?.acknowledged ?? 0}</Text>
        <Text style={styles.line}>ACK rate: {snapshot?.proofMetrics.ackRate ?? 0}%</Text>
        <Text style={styles.line}>Failures: {data?.failed ?? 0}</Text>
        <Text style={styles.line}>Relay hops: {data?.relayHops ?? 0}</Text>
        <Text style={styles.line}>Avg latency: {data?.avgLatencyMs ?? 0} ms</Text>
        <Text style={styles.line}>Truth level: physical_proof</Text>
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          Delivery counts come from proof metric events only. No delivery is claimed
          until a real TX/RX/ACK round-trip occurs.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 34, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.6)", fontSize: 16, fontWeight: "800" },
  card: { borderWidth: 1, borderColor: "rgba(0,208,132,0.26)", backgroundColor: "rgba(255,255,255,0.045)", borderRadius: 18, padding: 16, gap: 10 },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  big: { color: "#00D084", fontSize: 34, fontWeight: "900", textAlign: "center" },
  line: { color: "rgba(255,255,255,0.78)", fontSize: 16, lineHeight: 24 },
  truth: { borderWidth: 1, borderColor: "rgba(245,158,11,0.45)", borderRadius: 18, padding: 16 },
  truthTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900" },
  truthText: { color: "rgba(255,255,255,0.7)", lineHeight: 22, marginTop: 8 },
});
TSX

cat > "$ROOT/app/ack-tracking.tsx" <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useAllIntegrations } from "../src/maurimesh/integration/useAllIntegrations";

export default function AckTrackingScreen() {
  const { snapshot } = useAllIntegrations(1000);
  const data = snapshot?.ackTracking;

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>ACK Tracking</Text>
      <Text style={styles.subtitle}>Message acknowledgement paths</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>ACK Statistics</Text>
        <Text style={styles.line}>Delivered: {data?.delivered ?? 0}</Text>
        <Text style={styles.line}>ACKed: {data?.acked ?? 0}</Text>
        <Text style={styles.line}>In transit: {data?.inTransit ?? 0}</Text>
        <Text style={styles.line}>ACK rate: {data?.ackRate ?? 0}%</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Delivery Pipeline</Text>
        <Text style={styles.line}>Relay count: {snapshot?.proofMetrics.relayHops ?? 0}</Text>
        <Text style={styles.line}>Delivery count: {snapshot?.proofMetrics.delivered ?? 0}</Text>
        <Text style={styles.line}>ACK count: {snapshot?.proofMetrics.acknowledged ?? 0}</Text>
        <Text style={styles.line}>Failures: {snapshot?.proofMetrics.failed ?? 0}</Text>
        <Text style={styles.line}>Avg latency: {snapshot?.proofMetrics.avgLatencyMs ?? 0} ms</Text>
        <Text style={styles.line}>Truth level: physical_proof</Text>
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          ACK counts update only from proof metric ACK events. No acknowledgement is
          claimed until a real ACK event is recorded.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 34, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.6)", fontSize: 16, fontWeight: "800" },
  card: { borderWidth: 1, borderColor: "rgba(0,208,132,0.26)", backgroundColor: "rgba(255,255,255,0.045)", borderRadius: 18, padding: 16, gap: 10 },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  line: { color: "rgba(255,255,255,0.78)", fontSize: 16, lineHeight: 24 },
  truth: { borderWidth: 1, borderColor: "rgba(245,158,11,0.45)", borderRadius: 18, padding: 16 },
  truthTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900" },
  truthText: { color: "rgba(255,255,255,0.7)", lineHeight: 22, marginTop: 8 },
});
TSX

cat > "$ROOT/app/store-forward-queue.tsx" <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useAllIntegrations } from "../src/maurimesh/integration/useAllIntegrations";

export default function StoreForwardQueueScreen() {
  const { snapshot } = useAllIntegrations(1000);
  const data = snapshot?.storeForward;

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Store-Forward Queue</Text>
      <Text style={styles.subtitle}>Offline message relay</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Queue Summary</Text>
        <Text style={styles.line}>Total: {data?.total ?? 0}</Text>
        <Text style={styles.line}>Pending: {data?.pending ?? 0}</Text>
        <Text style={styles.line}>Failed: {data?.failed ?? 0}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Transport</Text>
        <Text style={styles.line}>Reachable peers: {data?.reachablePeers ?? 0}</Text>
        <Text style={styles.line}>Relay count: {data?.relayCount ?? 0}</Text>
        <Text style={styles.line}>Delivery count: {data?.deliveryCount ?? 0}</Text>
        <Text style={styles.line}>Truth level: physical_proof</Text>
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          Queue counts update from proof metric events. Real store-forward delivery
          still requires hardware proof.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 34, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.6)", fontSize: 16, fontWeight: "800" },
  card: { borderWidth: 1, borderColor: "rgba(0,208,132,0.26)", backgroundColor: "rgba(255,255,255,0.045)", borderRadius: 18, padding: 16, gap: 10 },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  line: { color: "rgba(255,255,255,0.78)", fontSize: 16, lineHeight: 24 },
  truth: { borderWidth: 1, borderColor: "rgba(245,158,11,0.45)", borderRadius: 18, padding: 16 },
  truthTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900" },
  truthText: { color: "rgba(255,255,255,0.7)", lineHeight: 22, marginTop: 8 },
});
TSX

cat > "$ROOT/app/latency-monitoring.tsx" <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useAllIntegrations } from "../src/maurimesh/integration/useAllIntegrations";

export default function LatencyMonitoringScreen() {
  const { snapshot } = useAllIntegrations(1000);
  const data = snapshot?.latency;

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Latency Monitoring</Text>
      <Text style={styles.subtitle}>Round-trip timing and reachability</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Latency Overview</Text>
        <Text style={styles.line}>Avg latency: {data?.avgLatencyMs ?? 0} ms</Text>
        <Text style={styles.line}>Samples: {data?.samples ?? 0}</Text>
        <Text style={styles.line}>Failures: {data?.failures ?? 0}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Peer Reachability</Text>
        <Text style={styles.line}>Reachable peers: {data?.reachablePeers ?? 0}</Text>
        <Text style={styles.line}>Truth level: physical_proof</Text>
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          Average latency comes from recorded proof metric events only. It does not
          simulate radio latency.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 34, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.6)", fontSize: 16, fontWeight: "800" },
  card: { borderWidth: 1, borderColor: "rgba(0,208,132,0.26)", backgroundColor: "rgba(255,255,255,0.045)", borderRadius: 18, padding: 16, gap: 10 },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  line: { color: "rgba(255,255,255,0.78)", fontSize: 16, lineHeight: 24 },
  truth: { borderWidth: 1, borderColor: "rgba(245,158,11,0.45)", borderRadius: 18, padding: 16 },
  truthTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900" },
  truthText: { color: "rgba(255,255,255,0.7)", lineHeight: 22, marginTop: 8 },
});
TSX

cat > "$ROOT/app/route-health.tsx" <<'TSX'
import React from "react";
import { ScrollView, StyleSheet, Text, View } from "react-native";
import { useAllIntegrations } from "../src/maurimesh/integration/useAllIntegrations";

export default function RouteHealthScreen() {
  const { snapshot } = useAllIntegrations(1000);
  const data = snapshot?.routeHealth;

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>
      <Text style={styles.brand}>MauriMesh</Text>
      <Text style={styles.title}>Route Health</Text>
      <Text style={styles.subtitle}>Path quality summary</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Health Summary</Text>
        <Text style={styles.line}>Good: {data?.healthGood ?? 0}</Text>
        <Text style={styles.line}>Weak: {data?.healthWeak ?? 0}</Text>
        <Text style={styles.line}>Poor: {data?.healthPoor ?? 0}</Text>
        <Text style={styles.line}>Packet loss: {data?.packetLossPercent ?? 0}%</Text>
        <Text style={styles.line}>Relay hops: {data?.relayHops ?? 0}</Text>
      </View>

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth Boundary</Text>
        <Text style={styles.truthText}>
          Route health is derived from proof metrics. It improves only after real
          delivery/ACK evidence is recorded.
        </Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#020403" },
  content: { padding: 22, gap: 16 },
  brand: { color: "#00D084", fontSize: 34, fontWeight: "900" },
  title: { color: "#FFFFFF", fontSize: 30, fontWeight: "900" },
  subtitle: { color: "rgba(255,255,255,0.6)", fontSize: 16, fontWeight: "800" },
  card: { borderWidth: 1, borderColor: "rgba(0,208,132,0.26)", backgroundColor: "rgba(255,255,255,0.045)", borderRadius: 18, padding: 16, gap: 10 },
  cardTitle: { color: "#FFFFFF", fontSize: 20, fontWeight: "900" },
  line: { color: "rgba(255,255,255,0.78)", fontSize: 16, lineHeight: 24 },
  truth: { borderWidth: 1, borderColor: "rgba(245,158,11,0.45)", borderRadius: 18, padding: 16 },
  truthTitle: { color: "#FFFFFF", fontSize: 18, fontWeight: "900" },
  truthText: { color: "rgba(255,255,255,0.7)", lineHeight: 22, marginTop: 8 },
});
TSX

echo ""
echo "6. Patch dashboard with Integration Hub link"

if [ -f "$ROOT/app/dashboard.tsx" ]; then
python3 <<'PY'
from pathlib import Path

path = Path("app/dashboard.tsx")
text = path.read_text()
original = text

if '"/integration-hub"' not in text:
    if '["Proof Metrics", "/proof-metrics"]' in text:
        text = text.replace(
            '["Proof Metrics", "/proof-metrics"]',
            '["Proof Metrics", "/proof-metrics"],\n  ["Integration Hub", "/integration-hub"]',
            1,
        )
    elif '["Proof Ledger", "/proof-ledger"]' in text:
        text = text.replace(
            '["Proof Ledger", "/proof-ledger"]',
            '["Proof Ledger", "/proof-ledger"],\n  ["Proof Metrics", "/proof-metrics"],\n  ["Integration Hub", "/integration-hub"]',
            1,
        )

path.write_text(text)
print("dashboard patched" if text != original else "dashboard unchanged")
PY
fi

echo ""
echo "7. Add integration test"

cat > "$ROOT/tests/integration/task-191-all-integrations-static.test.ts" <<'TS'
import {
  TASK_191_ALL_INTEGRATIONS_BRIDGE_MARKER,
} from "../../src/maurimesh/integration/allIntegrationsBridge";

if (
  TASK_191_ALL_INTEGRATIONS_BRIDGE_MARKER !==
  "TASK_191_ALL_INTEGRATIONS_BRIDGE_20260608_A"
) {
  throw new Error("Wrong #191 bridge marker");
}

console.log("PASS: TASK_191_ALL_INTEGRATIONS_STATIC_TEST_20260608_A");
TS

echo ""
echo "8. Add audit script"

cat > "$ROOT/scripts/audit-task-191-all-integrations.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#191 All Integrations Audit"
echo "============================================================"

grep -RniE "TASK_191|Integration Hub|useAllIntegrations|deliveryAnalytics|ackTracking|storeForward|routeHealth|latency" \
  app src tests scripts docs 2>/dev/null || true

echo ""
echo "Required checks:"
test -f src/maurimesh/integration/allIntegrationsBridge.ts && echo "✅ allIntegrationsBridge.ts"
test -f src/maurimesh/integration/useAllIntegrations.ts && echo "✅ useAllIntegrations.ts"
test -f app/integration-hub.tsx && echo "✅ integration hub screen"
test -f app/delivery-analytics.tsx && echo "✅ delivery analytics screen"
test -f app/ack-tracking.tsx && echo "✅ ACK tracking screen"
test -f app/store-forward-queue.tsx && echo "✅ store-forward queue screen"
test -f app/latency-monitoring.tsx && echo "✅ latency monitoring screen"
test -f app/route-health.tsx && echo "✅ route health screen"
grep -q "Integration Hub" app/dashboard.tsx && echo "✅ dashboard Integration Hub link"
SH

chmod +x "$ROOT/scripts/audit-task-191-all-integrations.sh"

echo ""
echo "9. Docs"

cat > "$ROOT/docs/task-191-all-integrations-bridge.md" <<'MD'
# Task #191 — All Integrations Bridge

Marker: `TASK_191_ALL_INTEGRATIONS_BRIDGE_20260608_A`

## Installed

- Shared all-integrations bridge.
- Live integration hook.
- Integration Hub screen.
- Metric-backed:
  - Delivery Analytics
  - ACK Tracking
  - Store-Forward Queue
  - Latency Monitoring
  - Route Health

## Data source

The screens consume `proofMetricsSpine`, which is updated by:
- raw packet proof send attempt
- raw packet proof send submitted/failure
- BLE proof evidence save
- future RX/ACK/relay instrumentation

## Truth boundary

This is a real integration wiring layer, not a fake proof layer.
Physical delivery still requires:
- Phone B `RX_RAW_PACKET`
- Phone B `ACK_SENT=true`
- Phone A ACK received
- saved evidence report
MD

echo ""
echo "10. Run audit"
bash "$ROOT/scripts/audit-task-191-all-integrations.sh"

echo ""
echo "11. Run static integration test"
npx tsx "$ROOT/tests/integration/task-191-all-integrations-static.test.ts"

echo ""
echo "12. TypeScript check"
npx tsc --noEmit

echo ""
echo "13. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "#191 ALL INTEGRATIONS BRIDGE INSTALLED"
echo "Backup: $BACKUP"
echo "Open route after build: /integration-hub"
echo "Then use /raw-packet-proof and /proof-metrics for physical proof flow."
echo "============================================================"
