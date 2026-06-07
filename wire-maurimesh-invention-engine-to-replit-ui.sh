#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "WIRE MAURIMESH INVENTION ENGINE TO REPLIT UI"
echo "Dashboard + Chat + Living Mesh + Mesh Status + API"
echo "============================================================"
echo ""

ROOT="$(pwd)"
BACKUP="$ROOT/backup-before-ui-engine-wire-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"
mkdir -p app
mkdir -p src/lib
mkdir -p src/components
mkdir -p src/maurimesh/ui
mkdir -p server

echo "Backup selected UI/API files if present..."
for f in \
  app/dashboard.tsx \
  app/chat.tsx \
  app/living-mesh.tsx \
  app/mesh-status.tsx \
  server/index.ts \
  src/lib/meshClient.ts
do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$f" "$BACKUP/$f"
  fi
done

# ============================================================
# 1. SAFETY CHECK — ENGINE MUST EXIST
# ============================================================

if [ ! -f "src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts" ]; then
  echo ""
  echo "ERROR: Invention engine not found."
  echo "Run the previous installer first:"
  echo "  install-maurimesh-invention-engine.sh"
  echo ""
  exit 1
fi

# ============================================================
# 2. UI ENGINE SINGLETON
# ============================================================

cat > src/maurimesh/ui/mauriUiEngine.ts <<'TS'
import {
  LivingSelfGovernedAiMesh,
  MeshNode,
  EngineResult,
} from "../invention-engine";

export type UiMeshNode = {
  id: string;
  label: string;
  status: "online" | "relay" | "offline";
  signal: number;
  x: number;
  y: number;
};

export type UiMeshRoute = {
  from: string;
  to: string;
  quality: number;
};

export type UiEngineSnapshot = {
  mode: "LIVE_ENGINE" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  nodes: UiMeshNode[];
  routes: UiMeshRoute[];
  ledgerCount: number;
  trustCount: number;
  routeMemoryCount: number;
  lastResult?: EngineResult;
  rawVisualSnapshot: unknown;
};

const engine = new LivingSelfGovernedAiMesh();

let lastResult: EngineResult | undefined;

const defaultNodes: MeshNode[] = [
  {
    id: "PHONE_A",
    label: "Devan Phone",
    role: "ENDPOINT",
    trust: "VERIFIED",
    batteryPct: 88,
    signalPct: 92,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE", "WIFI_DIRECT", "LOCAL_WIFI", "INTERNET"],
    culturalState: "WHANAUNGATANGA_TRUSTED",
  },
  {
    id: "PHONE_B",
    label: "Relay Phone",
    role: "RELAY",
    trust: "TRUSTED",
    batteryPct: 71,
    signalPct: 80,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE", "WIFI_DIRECT"],
  },
  {
    id: "PHONE_C",
    label: "Recipient Phone",
    role: "ENDPOINT",
    trust: "OBSERVED",
    batteryPct: 64,
    signalPct: 45,
    online: false,
    lastSeenMs: Date.now() - 60000,
    transports: ["BLE"],
  },
  {
    id: "GATEWAY_D",
    label: "Gateway D",
    role: "GATEWAY",
    trust: "VERIFIED",
    batteryPct: 97,
    signalPct: 89,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["LOCAL_WIFI", "INTERNET"],
  },
];

engine.setNodes(defaultNodes);

function xyForNode(index: number): { x: number; y: number } {
  const positions = [
    { x: 18, y: 30 },
    { x: 46, y: 55 },
    { x: 77, y: 28 },
    { x: 66, y: 78 },
    { x: 30, y: 78 },
    { x: 84, y: 56 },
  ];
  return positions[index % positions.length];
}

function toUiNodes(nodes: MeshNode[]): UiMeshNode[] {
  return nodes.map((node, index) => {
    const pos = xyForNode(index);
    return {
      id: node.id,
      label: node.label || node.id,
      status: !node.online ? "offline" : node.role === "RELAY" || node.role === "GATEWAY" || node.role === "SUPERNODE" ? "relay" : "online",
      signal: node.signalPct,
      x: pos.x,
      y: pos.y,
    };
  });
}

function toUiRoutes(result?: EngineResult): UiMeshRoute[] {
  if (!result) {
    return [
      { from: "PHONE_A", to: "PHONE_B", quality: 88 },
      { from: "PHONE_B", to: "PHONE_C", quality: 62 },
      { from: "PHONE_B", to: "GATEWAY_D", quality: 81 },
    ];
  }

  const routes: UiMeshRoute[] = [];
  const hops = result.routePlan.hops;

  if (hops.length === 0) {
    routes.push({
      from: result.packet.from,
      to: result.packet.to,
      quality: Math.round(result.routePlan.totalScore * 100),
    });
    return routes;
  }

  let previous = result.packet.from;
  for (const hop of hops) {
    routes.push({
      from: previous,
      to: hop.nodeId,
      quality: Math.round(hop.score * 100),
    });
    previous = hop.nodeId;
  }

  if (previous !== result.packet.to) {
    routes.push({
      from: previous,
      to: result.packet.to,
      quality: Math.round(result.routePlan.totalScore * 100),
    });
  }

  return routes;
}

export function getMauriUiEngine() {
  return engine;
}

export function runDemoMessage(body?: string): EngineResult {
  lastResult = engine.send({
    from: "PHONE_A",
    to: "PHONE_C",
    body: body || "Kia kaha, emergency help message through MauriMesh.",
  });

  return lastResult;
}

export function sendUiMessage(input: {
  from?: string;
  to?: string;
  body: string;
}): EngineResult {
  lastResult = engine.send({
    from: input.from || "PHONE_A",
    to: input.to || "PHONE_C",
    body: input.body,
  });

  return lastResult;
}

export function ackLastRoute(): void {
  if (!lastResult) return;
  const routeNodes = [
    lastResult.packet.from,
    ...lastResult.routePlan.hops.map((h) => h.nodeId),
    lastResult.packet.to,
  ];
  engine.ack(lastResult.packet.id, routeNodes, 420);
}

export function failLastRoute(reason = "Manual UI failure simulation."): void {
  if (!lastResult) return;
  const routeNodes = [
    lastResult.packet.from,
    ...lastResult.routePlan.hops.map((h) => h.nodeId),
    lastResult.packet.to,
  ];
  engine.fail(lastResult.packet.id, routeNodes, reason);
}

export function getUiEngineSnapshot(): UiEngineSnapshot {
  const rawVisualSnapshot = engine.visualSnapshot();

  return {
    mode: "LIVE_ENGINE",
    message:
      "MauriMesh invention engine is wired to Replit UI. This is logic-engine proof, not native BLE proof.",
    nodes: toUiNodes(engine.getNodes()),
    routes: toUiRoutes(lastResult),
    ledgerCount: engine.ledgerExport().length,
    trustCount: engine.trustMemoryExport().length,
    routeMemoryCount: engine.routeMemoryExport().length,
    lastResult,
    rawVisualSnapshot,
  };
}

export function resetUiEngineDemo(): UiEngineSnapshot {
  engine.setNodes(defaultNodes);
  lastResult = undefined;
  return getUiEngineSnapshot();
}
TS

# ============================================================
# 3. UI CLIENT
# ============================================================

cat > src/lib/inventionEngineClient.ts <<'TS'
import {
  ackLastRoute,
  failLastRoute,
  getUiEngineSnapshot,
  resetUiEngineDemo,
  runDemoMessage,
  sendUiMessage,
  UiEngineSnapshot,
} from "../maurimesh/ui/mauriUiEngine";

export type InventionEngineMode = "LOCAL_ENGINE";

export async function getInventionEngineStatus(): Promise<UiEngineSnapshot> {
  return getUiEngineSnapshot();
}

export async function runInventionDemo(body?: string): Promise<UiEngineSnapshot> {
  runDemoMessage(body);
  return getUiEngineSnapshot();
}

export async function sendMessageThroughInventionEngine(body: string): Promise<UiEngineSnapshot> {
  sendUiMessage({ body });
  return getUiEngineSnapshot();
}

export async function ackInventionRoute(): Promise<UiEngineSnapshot> {
  ackLastRoute();
  return getUiEngineSnapshot();
}

export async function failInventionRoute(): Promise<UiEngineSnapshot> {
  failLastRoute();
  return getUiEngineSnapshot();
}

export async function resetInventionEngine(): Promise<UiEngineSnapshot> {
  return resetUiEngineDemo();
}
TS

# ============================================================
# 4. ENGINE STATUS CARD
# ============================================================

cat > src/components/InventionEngineCard.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function InventionEngineCard({
  title,
  value,
  tone = "success",
}: {
  title: string;
  value: string;
  tone?: "success" | "warning" | "danger" | "info";
}) {
  return (
    <View style={styles.card}>
      <StatusPill label="INVENTION ENGINE" tone={tone} />
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.value}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 19,
    fontWeight: "900",
  },
  value: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 14,
    lineHeight: 21,
  },
});
TSX

# ============================================================
# 5. SYNTH PANEL
# ============================================================

cat > src/components/SynthPanel.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

export type SynthPanelMessage = {
  agent: string;
  tone: string;
  text: string;
};

export function SynthPanel({ messages }: { messages: SynthPanelMessage[] }) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Cleo + Chanelle Synth AI</Text>
      {messages.length === 0 ? (
        <Text style={styles.empty}>No synth explanation yet. Run a demo or send a message.</Text>
      ) : (
        messages.map((msg, index) => (
          <View key={`${msg.agent}-${index}`} style={styles.message}>
            <Text style={styles.agent}>{msg.agent} · {msg.tone}</Text>
            <Text style={styles.text}>{msg.text}</Text>
          </View>
        ))
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  empty: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  message: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    backgroundColor: "rgba(255,255,255,0.04)",
    gap: 6,
  },
  agent: {
    color: mauriTheme.colors.greenstone,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 0.6,
  },
  text: {
    color: mauriTheme.colors.white,
    lineHeight: 21,
  },
});
TSX

# ============================================================
# 6. ROUTE PLAN PANEL
# ============================================================

cat > src/components/RoutePlanPanel.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

type Hop = {
  nodeId: string;
  transport: string;
  score: number;
  reason: string;
};

export function RoutePlanPanel({
  routePlan,
}: {
  routePlan?: {
    totalScore: number;
    transport: string;
    decisionReason: string;
    storeAndForward: boolean;
    governanceApproved: boolean;
    hops: Hop[];
  };
}) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Adaptive Mesh Routing Intelligence</Text>
      {!routePlan ? (
        <Text style={styles.empty}>No route plan yet.</Text>
      ) : (
        <>
          <Text style={styles.summary}>
            {routePlan.decisionReason}
          </Text>
          <View style={styles.row}>
            <Text style={styles.k}>Transport</Text>
            <Text style={styles.v}>{routePlan.transport}</Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.k}>Score</Text>
            <Text style={styles.v}>{Math.round(routePlan.totalScore * 100)}%</Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.k}>Store + Forward</Text>
            <Text style={styles.v}>{routePlan.storeAndForward ? "YES" : "NO"}</Text>
          </View>
          <View style={styles.row}>
            <Text style={styles.k}>Governance</Text>
            <Text style={styles.v}>{routePlan.governanceApproved ? "APPROVED" : "REJECTED"}</Text>
          </View>

          {routePlan.hops.map((hop, index) => (
            <View key={`${hop.nodeId}-${index}`} style={styles.hop}>
              <Text style={styles.hopTitle}>Hop {index + 1}: {hop.nodeId}</Text>
              <Text style={styles.hopText}>{hop.transport} · {Math.round(hop.score * 100)}%</Text>
              <Text style={styles.hopText}>{hop.reason}</Text>
            </View>
          ))}
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  empty: {
    color: mauriTheme.colors.mutedWhite,
  },
  summary: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    borderBottomWidth: 1,
    borderBottomColor: "rgba(255,255,255,0.08)",
    paddingVertical: 8,
    gap: 12,
  },
  k: {
    color: mauriTheme.colors.mutedWhite,
    fontWeight: "700",
  },
  v: {
    color: mauriTheme.colors.white,
    fontWeight: "900",
    textAlign: "right",
    flex: 1,
  },
  hop: {
    marginTop: 8,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    backgroundColor: "rgba(0,208,132,0.08)",
    gap: 4,
  },
  hopTitle: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
  },
  hopText: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
});
TSX

# ============================================================
# 7. LEDGER PANEL
# ============================================================

cat > src/components/DeliveryLedgerPanel.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";

type LedgerEvent = {
  packetId: string;
  status: string;
  atMs: number;
  nodeId?: string;
  reason?: string;
};

export function DeliveryLedgerPanel({ ledger }: { ledger: LedgerEvent[] }) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Delivery Proof + ACK Ledger</Text>
      {ledger.length === 0 ? (
        <Text style={styles.empty}>No delivery events yet.</Text>
      ) : (
        ledger.slice(-8).reverse().map((event, index) => (
          <View key={`${event.packetId}-${event.status}-${index}`} style={styles.event}>
            <Text style={styles.status}>{event.status}</Text>
            <Text style={styles.text}>{event.reason || "Ledger event recorded."}</Text>
            <Text style={styles.meta}>
              {event.nodeId ? `${event.nodeId} · ` : ""}
              {new Date(event.atMs).toLocaleTimeString()}
            </Text>
          </View>
        ))
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  empty: {
    color: mauriTheme.colors.mutedWhite,
  },
  event: {
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.08)",
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    gap: 4,
  },
  status: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
  },
  text: {
    color: mauriTheme.colors.white,
    lineHeight: 20,
  },
  meta: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 12,
  },
});
TSX

# ============================================================
# 8. INVENTION CONTROL SCREEN
# ============================================================

cat > app/invention-engine.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { DeliveryLedgerPanel } from "../src/components/DeliveryLedgerPanel";
import { InventionEngineCard } from "../src/components/InventionEngineCard";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { MauriButton } from "../src/components/MauriButton";
import { RoutePlanPanel } from "../src/components/RoutePlanPanel";
import { StatusPill } from "../src/components/StatusPill";
import { SynthPanel } from "../src/components/SynthPanel";
import {
  ackInventionRoute,
  failInventionRoute,
  getInventionEngineStatus,
  resetInventionEngine,
  runInventionDemo,
} from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof getInventionEngineStatus>>;

export default function InventionEngineScreen() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  async function refresh() {
    setSnapshot(await getInventionEngineStatus());
  }

  useEffect(() => {
    refresh();
  }, []);

  async function runDemo() {
    setSnapshot(await runInventionDemo());
  }

  async function ackRoute() {
    setSnapshot(await ackInventionRoute());
  }

  async function failRoute() {
    setSnapshot(await failInventionRoute());
  }

  async function reset() {
    setSnapshot(await resetInventionEngine());
  }

  const result = snapshot?.lastResult;

  return (
    <AppShell>
      <StatusPill label="LOCAL LOGIC ENGINE" tone="success" />
      <Text style={styles.title}>MauriMesh Invention Engine</Text>
      <Text style={styles.subtitle}>
        This wires Mauri AI, Tikanga governance, hybrid routing, store-and-forward,
        self-healing, trust memory, and Cleo + Chanelle Synth AI into the Replit UI.
      </Text>

      <InventionEngineCard
        title="Engine Status"
        value={snapshot?.message || "Loading invention engine..."}
        tone="success"
      />

      <View style={styles.buttonGrid}>
        <MauriButton title="Run Demo Message" onPress={runDemo} />
        <MauriButton title="ACK Last Route" variant="secondary" onPress={ackRoute} />
        <MauriButton title="Fail Last Route" variant="danger" onPress={failRoute} />
        <MauriButton title="Reset Demo" variant="secondary" onPress={reset} />
      </View>

      <View style={styles.metrics}>
        <InventionEngineCard
          title="Ledger Events"
          value={`${snapshot?.ledgerCount || 0} proof event(s) recorded.`}
          tone="info"
        />
        <InventionEngineCard
          title="Trust Memory"
          value={`${snapshot?.trustCount || 0} node trust record(s) active.`}
          tone="info"
        />
        <InventionEngineCard
          title="Route Memory"
          value={`${snapshot?.routeMemoryCount || 0} route learning record(s) active.`}
          tone="info"
        />
      </View>

      <Text style={styles.section}>Living Mesh Visual Proof</Text>
      <LivingMeshCanvas
        nodes={snapshot?.nodes || []}
        routes={snapshot?.routes || []}
      />

      <RoutePlanPanel routePlan={result?.routePlan} />
      <SynthPanel messages={result?.synth || []} />
      <DeliveryLedgerPanel ledger={result?.ledger || []} />

      <Text style={styles.truth}>
        Truth: This proves the Replit-safe invention logic and UI wiring. Real BLE,
        phone-to-phone transport, background Bluetooth, and APK behaviour still need
        physical device validation.
      </Text>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
  buttonGrid: {
    gap: mauriTheme.spacing.md,
  },
  metrics: {
    gap: mauriTheme.spacing.md,
  },
  section: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
    marginTop: mauriTheme.spacing.sm,
  },
  truth: {
    color: mauriTheme.colors.warning,
    fontSize: 13,
    lineHeight: 20,
    fontWeight: "700",
  },
});
TSX

# ============================================================
# 9. UPDATED DASHBOARD WITH ENGINE ENTRY
# ============================================================

cat > app/dashboard.tsx <<'TSX'
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { InventionEngineCard } from "../src/components/InventionEngineCard";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getInventionEngineStatus } from "../src/lib/inventionEngineClient";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);
  const [engineMessage, setEngineMessage] = useState("Checking invention engine...");

  useEffect(() => {
    getMeshStatus().then(setMesh);
    getInventionEngineStatus().then((snapshot) => setEngineMessage(snapshot.message));
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        Command centre for messenger, living mesh, invention engine, AI governance,
        routing intelligence, and Replit-safe proof.
      </Text>

      <MeshSignalCard
        title="Mesh Status"
        value={mesh?.message || "Checking mesh status..."}
        status={mode}
      />

      <InventionEngineCard
        title="Living Self-Governed AI Mesh"
        value={engineMessage}
        tone="success"
      />

      <View style={styles.grid}>
        <MauriButton title="Invention Engine" onPress={() => router.push("/invention-engine")} />
        <MauriButton title="Chat" onPress={() => router.push("/chat")} />
        <MauriButton title="Living Mesh" onPress={() => router.push("/living-mesh")} />
        <MauriButton title="Mesh Status" onPress={() => router.push("/mesh-status")} />
        <MauriButton title="Add Friend" onPress={() => router.push("/add-friend")} />
        <MauriButton title="Pixel Calling" onPress={() => router.push("/pixel-calling")} />
        <MauriButton title="Settings" onPress={() => router.push("/settings")} />
      </View>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 36,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 15,
    lineHeight: 22,
  },
  grid: {
    gap: mauriTheme.spacing.md,
  },
});
TSX

# ============================================================
# 10. UPDATED CHAT WIRED TO INVENTION ENGINE
# ============================================================

cat > app/chat.tsx <<'TSX'
import React, { useState } from "react";
import { StyleSheet, Text, TextInput, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { ChatBubble } from "../src/components/ChatBubble";
import { DeliveryLedgerPanel } from "../src/components/DeliveryLedgerPanel";
import { MauriButton } from "../src/components/MauriButton";
import { RoutePlanPanel } from "../src/components/RoutePlanPanel";
import { SynthPanel } from "../src/components/SynthPanel";
import { sendMessageThroughInventionEngine } from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof sendMessageThroughInventionEngine>>;

export default function ChatScreen() {
  const [message, setMessage] = useState("");
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  async function send() {
    const clean = message.trim();
    if (!clean) return;
    const result = await sendMessageThroughInventionEngine(clean);
    setSnapshot(result);
    setMessage("");
  }

  const packet = snapshot?.lastResult?.packet;

  return (
    <AppShell>
      <Text style={styles.title}>Chat</Text>
      <Text style={styles.subtitle}>
        Message input is now wired through Mauri AI, Tikanga governance,
        hybrid routing, store-and-forward, trust memory, and Cleo + Chanelle Synth AI.
      </Text>

      <View style={styles.thread}>
        <ChatBubble text="MauriMesh route prepared." status="ENGINE READY" />
        {packet ? (
          <ChatBubble
            mine
            text={packet.body}
            status={`${packet.culturalState} · ${snapshot?.lastResult?.routePlan.transport}`}
          />
        ) : (
          <ChatBubble
            mine
            text="Type a message below to run it through the invention engine."
            status="waiting"
          />
        )}
      </View>

      <View style={styles.inputWrap}>
        <TextInput
          placeholder="Type message..."
          placeholderTextColor="rgba(255,255,255,0.45)"
          style={styles.input}
          value={message}
          onChangeText={setMessage}
          multiline
        />
        <MauriButton title="Send Through MauriMesh Engine" onPress={send} />
      </View>

      <RoutePlanPanel routePlan={snapshot?.lastResult?.routePlan} />
      <SynthPanel messages={snapshot?.lastResult?.synth || []} />
      <DeliveryLedgerPanel ledger={snapshot?.lastResult?.ledger || []} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
  thread: {
    minHeight: 220,
    gap: 8,
  },
  inputWrap: {
    gap: mauriTheme.spacing.sm,
  },
  input: {
    minHeight: 90,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    color: mauriTheme.colors.white,
    paddingHorizontal: mauriTheme.spacing.md,
    paddingVertical: mauriTheme.spacing.md,
    backgroundColor: mauriTheme.colors.panel,
  },
});
TSX

# ============================================================
# 11. UPDATED LIVING MESH SCREEN
# ============================================================

cat > app/living-mesh.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { InventionEngineCard } from "../src/components/InventionEngineCard";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { MauriButton } from "../src/components/MauriButton";
import { RoutePlanPanel } from "../src/components/RoutePlanPanel";
import { StatusPill } from "../src/components/StatusPill";
import {
  getInventionEngineStatus,
  runInventionDemo,
} from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof getInventionEngineStatus>>;

export default function LivingMeshScreen() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  async function refresh() {
    setSnapshot(await getInventionEngineStatus());
  }

  async function demo() {
    setSnapshot(await runInventionDemo());
  }

  useEffect(() => {
    refresh();
  }, []);

  return (
    <AppShell>
      <StatusPill label={snapshot?.mode || "CHECKING"} tone="success" />
      <Text style={styles.title}>Living Mesh</Text>
      <Text style={styles.subtitle}>
        {snapshot?.message || "Checking local invention engine."}
      </Text>

      <MauriButton title="Run Living Mesh Demo" onPress={demo} />

      <LivingMeshCanvas
        nodes={snapshot?.nodes || []}
        routes={snapshot?.routes || []}
      />

      <InventionEngineCard
        title="Visual Proof Layer"
        value={`${snapshot?.nodes.length || 0} node(s), ${snapshot?.routes.length || 0} route(s), ${snapshot?.ledgerCount || 0} ledger event(s).`}
        tone="info"
      />

      <RoutePlanPanel routePlan={snapshot?.lastResult?.routePlan} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
TSX

# ============================================================
# 12. UPDATED MESH STATUS SCREEN
# ============================================================

cat > app/mesh-status.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { DeliveryLedgerPanel } from "../src/components/DeliveryLedgerPanel";
import { InventionEngineCard } from "../src/components/InventionEngineCard";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { SynthPanel } from "../src/components/SynthPanel";
import { getInventionEngineStatus } from "../src/lib/inventionEngineClient";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof getInventionEngineStatus>>;

export default function MeshStatusScreen() {
  const [mesh, setMesh] = useState<MeshStatus | null>(null);
  const [engine, setEngine] = useState<Snapshot | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
    getInventionEngineStatus().then(setEngine);
  }, []);

  return (
    <AppShell>
      <Text style={styles.title}>Mesh Status</Text>

      <MeshSignalCard
        title="Replit Mesh API"
        value={mesh?.message || "Checking..."}
        status={mesh?.mode || "UNAVAILABLE"}
      />

      <InventionEngineCard
        title="Mauri AI Core"
        value={engine?.message || "Checking invention engine..."}
        tone="success"
      />

      <InventionEngineCard
        title="Self-Learning Route Memory"
        value={`${engine?.routeMemoryCount || 0} route learning record(s).`}
        tone="info"
      />

      <InventionEngineCard
        title="Decentralised Trust Memory"
        value={`${engine?.trustCount || 0} trust record(s).`}
        tone="info"
      />

      <InventionEngineCard
        title="Delivery Proof Ledger"
        value={`${engine?.ledgerCount || 0} delivery proof event(s).`}
        tone="info"
      />

      <SynthPanel messages={engine?.lastResult?.synth || []} />
      <DeliveryLedgerPanel ledger={engine?.lastResult?.ledger || []} />

      <Text style={styles.truth}>
        Replit status proves UI wiring and logic-engine operation only. Native BLE,
        Wi-Fi Direct, APK runtime, background service, and real phone-to-phone proof
        must be validated on physical Android devices.
      </Text>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  truth: {
    color: mauriTheme.colors.warning,
    fontSize: 13,
    lineHeight: 20,
    fontWeight: "700",
  },
});
TSX

# ============================================================
# 13. MESH CLIENT BRIDGE TO ENGINE SNAPSHOT
# ============================================================

cat > src/lib/meshClient.ts <<'TS'
import { apiGet } from "./api";
import { simulatedNodes, simulatedRoutes, SimNode, SimRoute } from "./simulation";
import { getUiEngineSnapshot } from "../maurimesh/ui/mauriUiEngine";

export type MeshStatus = {
  mode: "LIVE" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  nodes: SimNode[];
  routes: SimRoute[];
};

export async function getMeshStatus(): Promise<MeshStatus> {
  const engineSnapshot = getUiEngineSnapshot();

  if (engineSnapshot.nodes.length > 0) {
    return {
      mode: "LIVE",
      message:
        "Local MauriMesh invention engine is active in Replit UI. Native BLE still requires APK/device proof.",
      nodes: engineSnapshot.nodes,
      routes: engineSnapshot.routes,
    };
  }

  const result = await apiGet<{
    nodes?: SimNode[];
    routes?: SimRoute[];
  }>("/api/mesh/status");

  if (result.ok) {
    return {
      mode: "LIVE",
      message: "Connected to Mesh API.",
      nodes: result.data.nodes || [],
      routes: result.data.routes || [],
    };
  }

  return {
    mode: "SIMULATION",
    message:
      "Mesh API unavailable in Replit preview. Showing labelled simulation only.",
    nodes: simulatedNodes,
    routes: simulatedRoutes,
  };
}
TS

# ============================================================
# 14. SERVER ENGINE API
# ============================================================

cat > server/index.ts <<'TS'
import express from "express";
import { getUiEngineSnapshot, runDemoMessage, sendUiMessage, ackLastRoute, failLastRoute } from "../src/maurimesh/ui/mauriUiEngine";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "Replit API is development only. Native BLE requires APK and physical devices.",
  });
});

app.get("/api/mesh/status", (_req, res) => {
  const snapshot = getUiEngineSnapshot();

  res.json({
    mode: snapshot.mode,
    truth: snapshot.message,
    nodes: snapshot.nodes,
    routes: snapshot.routes,
    ledgerCount: snapshot.ledgerCount,
    trustCount: snapshot.trustCount,
    routeMemoryCount: snapshot.routeMemoryCount,
    lastResult: snapshot.lastResult,
  });
});

app.get("/api/invention/status", (_req, res) => {
  res.json(getUiEngineSnapshot());
});

app.post("/api/invention/demo", (req, res) => {
  const body =
    typeof req.body?.body === "string"
      ? req.body.body
      : "Kia kaha, emergency help message through MauriMesh.";

  runDemoMessage(body);
  res.json(getUiEngineSnapshot());
});

app.post("/api/invention/send", (req, res) => {
  const body =
    typeof req.body?.body === "string"
      ? req.body.body
      : "MauriMesh test message.";

  sendUiMessage({
    from: typeof req.body?.from === "string" ? req.body.from : "PHONE_A",
    to: typeof req.body?.to === "string" ? req.body.to : "PHONE_C",
    body,
  });

  res.json(getUiEngineSnapshot());
});

app.post("/api/invention/ack", (_req, res) => {
  ackLastRoute();
  res.json(getUiEngineSnapshot());
});

app.post("/api/invention/fail", (_req, res) => {
  failLastRoute("API-triggered failure simulation.");
  res.json(getUiEngineSnapshot());
});

app.listen(port, "0.0.0.0", () => {
  console.log(`[MauriMesh] Replit API running on port ${port}`);
});
TS

# ============================================================
# 15. PACKAGE SCRIPTS
# ============================================================

node <<'NODE'
const fs = require("fs");
const path = "package.json";

if (!fs.existsSync(path)) {
  console.log("package.json not found. Creating minimal package.json.");
  fs.writeFileSync(path, JSON.stringify({ scripts: {}, dependencies: {}, devDependencies: {} }, null, 2));
}

const pkg = JSON.parse(fs.readFileSync(path, "utf8"));

pkg.scripts = pkg.scripts || {};
pkg.scripts.start = pkg.scripts.start || "expo start --web";
pkg.scripts.dev = pkg.scripts.dev || "expo start --web";
pkg.scripts.api = "tsx server/index.ts";
pkg.scripts.check = "tsc --noEmit";
pkg.scripts.typecheck = "tsc --noEmit";
pkg.scripts["maurimesh:invention-demo"] = "tsx src/maurimesh/invention-engine/demo.ts";
pkg.scripts["maurimesh:ui-check"] = "tsc --noEmit";

pkg.dependencies = pkg.dependencies || {};
pkg.devDependencies = pkg.devDependencies || {};
pkg.dependencies.express = pkg.dependencies.express || "latest";
pkg.devDependencies.tsx = pkg.devDependencies.tsx || "latest";
pkg.devDependencies.typescript = pkg.devDependencies.typescript || "latest";
pkg.devDependencies["@types/express"] = pkg.devDependencies["@types/express"] || "latest";

fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
console.log("package.json patched.");
NODE

# ============================================================
# 16. COMPLETION REPORT
# ============================================================

cat > MAURIMESH_UI_ENGINE_WIRING_REPORT.md <<'MD'
# MauriMesh UI Engine Wiring Report

## Wired into Replit UI

- Dashboard now links to Invention Engine.
- Chat now sends messages through MauriMesh invention engine.
- Living Mesh now uses engine node/route snapshot.
- Mesh Status now shows Mauri AI, route memory, trust memory, ledger, and synth status.
- New `/invention-engine` screen controls:
  - Run demo message
  - ACK last route
  - Fail last route
  - Reset demo
  - View route plan
  - View Cleo + Chanelle Synth AI explanation
  - View delivery ledger
  - View living mesh visual proof

## API endpoints

- GET `/api/health`
- GET `/api/mesh/status`
- GET `/api/invention/status`
- POST `/api/invention/demo`
- POST `/api/invention/send`
- POST `/api/invention/ack`
- POST `/api/invention/fail`

## Truth boundary

This proves Replit-safe logic-engine wiring and UI visibility.

It does not prove:
- native BLE
- Wi-Fi Direct
- background Android service
- real APK packet transport
- physical phone-to-phone delivery
- live emergency routing on devices

Those require Android APK + physical phones.
MD

echo ""
echo "============================================================"
echo "WIRE COMPLETE"
echo "============================================================"
echo ""
echo "Created/updated:"
echo "  src/maurimesh/ui/mauriUiEngine.ts"
echo "  src/lib/inventionEngineClient.ts"
echo "  src/components/InventionEngineCard.tsx"
echo "  src/components/SynthPanel.tsx"
echo "  src/components/RoutePlanPanel.tsx"
echo "  src/components/DeliveryLedgerPanel.tsx"
echo "  app/invention-engine.tsx"
echo "  app/dashboard.tsx"
echo "  app/chat.tsx"
echo "  app/living-mesh.tsx"
echo "  app/mesh-status.tsx"
echo "  src/lib/meshClient.ts"
echo "  server/index.ts"
echo ""
echo "Run:"
echo "  npm install"
echo "  npm run check"
echo "  npm run api"
echo ""
echo "In another Replit shell:"
echo "  npm run dev"
echo ""
echo "Test API:"
echo "  curl http://localhost:3000/api/health"
echo "  curl http://localhost:3000/api/invention/status"
echo ""
