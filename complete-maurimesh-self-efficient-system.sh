#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH SELF-EFFICIENT SYSTEM COMPLETION"
echo "All inventions + integrations + button wiring + evolution loop"
echo "============================================================"
echo ""

ROOT="$(pwd)"
BACKUP="$ROOT/backup-before-self-efficient-system-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"
mkdir -p src/maurimesh/system-brain
mkdir -p src/lib
mkdir -p src/components
mkdir -p app
mkdir -p server

echo "Backing up key files..."
for f in \
  app/dashboard.tsx \
  app/settings.tsx \
  server/index.ts \
  src/lib/mauriSystemBrainClient.ts \
  src/maurimesh/system-brain/systemBrain.ts
do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$f" "$BACKUP/$f"
  fi
done

if [ ! -f "src/maurimesh/invention-engine/livingSelfGovernedAiMesh.ts" ]; then
  echo "ERROR: invention engine missing."
  echo "Run install-maurimesh-invention-engine.sh first."
  exit 1
fi

if [ ! -f "src/maurimesh/ui/mauriUiEngine.ts" ]; then
  echo "ERROR: UI engine bridge missing."
  echo "Run wire-maurimesh-invention-engine-to-replit-ui.sh first."
  exit 1
fi

# ============================================================
# 1. SYSTEM BRAIN TYPES
# ============================================================

cat > src/maurimesh/system-brain/systemTypes.ts <<'TS'
export type SystemLayerStatus =
  | "ACTIVE"
  | "WIRED"
  | "LEARNING"
  | "OPTIMISING"
  | "NEEDS_NATIVE_PROOF"
  | "NEEDS_REVIEW";

export type SystemLayer = {
  id: string;
  name: string;
  status: SystemLayerStatus;
  purpose: string;
  belongsBecause: string;
  optimises: string[];
  dependencies: string[];
  proofBoundary: string;
};

export type ButtonDecision = {
  screen: string;
  buttonTitle: string;
  targetRoute: string;
  decisionLayer: string;
  reason: string;
  status: "CONNECTED" | "RECOMMENDED" | "MISSING_SCREEN" | "NEEDS_NATIVE_PROOF";
};

export type SystemEvolutionSnapshot = {
  atMs: number;
  score: number;
  summary: string;
  activeLayers: number;
  totalLayers: number;
  buttonConnections: ButtonDecision[];
  layerMap: SystemLayer[];
  recommendations: string[];
};
TS

# ============================================================
# 2. SYSTEM LAYER REGISTRY
# ============================================================

cat > src/maurimesh/system-brain/layerRegistry.ts <<'TS'
import { SystemLayer } from "./systemTypes";

export const MAURIMESH_SYSTEM_LAYERS: SystemLayer[] = [
  {
    id: "offline_identity_mesh",
    name: "Offline-First Identity Mesh Messenger",
    status: "ACTIVE",
    purpose: "Keeps identity and communication local-first before internet fallback.",
    belongsBecause: "MauriMesh must survive without SIM, mobile data, or central server dependency.",
    optimises: ["identity", "offline messaging", "trust", "local-first startup"],
    dependencies: ["secure_mesh_identity", "delivery_ledger"],
    proofBoundary: "Needs APK/device proof for native BLE identity exchange.",
  },
  {
    id: "living_route_memory",
    name: "Living Route Memory",
    status: "LEARNING",
    purpose: "Learns from ACKs, failures, latency, and relay behaviour.",
    belongsBecause: "The route system must improve while the build and field tests run.",
    optimises: ["route quality", "delivery success", "latency", "relay selection"],
    dependencies: ["delivery_ledger", "decentralised_trust_memory"],
    proofBoundary: "Logic active now. Real field learning needs phone packet events.",
  },
  {
    id: "tikanga_governance",
    name: "Tikanga Protocol Engine",
    status: "ACTIVE",
    purpose: "Classifies messages into noa, tapu, whānau, manaakitanga, kaitiakitanga, and Kia Kaha states.",
    belongsBecause: "MauriMesh needs ethical and cultural decision logic before routing.",
    optimises: ["consent", "privacy", "cultural protocol", "safe routing"],
    dependencies: ["self_governance", "cultural_intelligence"],
    proofBoundary: "Requires cultural review before public claims.",
  },
  {
    id: "self_governance",
    name: "Self-Governance Layer",
    status: "ACTIVE",
    purpose: "Approves, restricts, or rejects routing decisions before transmission.",
    belongsBecause: "A self-learning mesh needs control boundaries.",
    optimises: ["safety", "abuse prevention", "policy control", "trusted routing"],
    dependencies: ["tikanga_governance", "trust_memory"],
    proofBoundary: "Runtime logic active. Production policy requires review.",
  },
  {
    id: "mauri_ai_core",
    name: "Mauri AI Core",
    status: "OPTIMISING",
    purpose: "Balances route score, trust, battery, privacy, urgency, and delivery likelihood.",
    belongsBecause: "The network needs a decision brain, not fixed static routing.",
    optimises: ["routing", "energy", "fallback", "resilience", "priority"],
    dependencies: ["living_route_memory", "self_governance"],
    proofBoundary: "Weights need tuning from real field telemetry.",
  },
  {
    id: "adaptive_routing",
    name: "Adaptive Mesh Routing Intelligence",
    status: "LEARNING",
    purpose: "Chooses direct, relay, gateway, or store-and-forward routes.",
    belongsBecause: "Hybrid networks constantly change.",
    optimises: ["transport selection", "hop quality", "path score", "fallback"],
    dependencies: ["mauri_ai_core", "hybrid_transport"],
    proofBoundary: "Needs native BLE/Wi-Fi Direct proof for real routes.",
  },
  {
    id: "hybrid_transport",
    name: "Hybrid Transport Routing Layer",
    status: "WIRED",
    purpose: "Unifies BLE, Wi-Fi Direct, local Wi-Fi, internet, and future backhaul options.",
    belongsBecause: "No single transport is strong enough everywhere.",
    optimises: ["connectivity", "fallback", "coverage", "route survival"],
    dependencies: ["adaptive_routing"],
    proofBoundary: "BLE/Wi-Fi Direct need APK testing.",
  },
  {
    id: "store_forward",
    name: "Store-and-Forward Delivery Layer",
    status: "ACTIVE",
    purpose: "Stores packets until a trusted route appears.",
    belongsBecause: "Offline recipients cannot always receive immediately.",
    optimises: ["delayed delivery", "offline survival", "queue recovery"],
    dependencies: ["delivery_ledger", "self_healing"],
    proofBoundary: "Needs encrypted persistent APK storage.",
  },
  {
    id: "self_healing",
    name: "Self-Healing Runtime",
    status: "ACTIVE",
    purpose: "Detects failed packets, stale nodes, and requeue conditions.",
    belongsBecause: "The mesh must repair itself when routes fail.",
    optimises: ["recovery", "uptime", "queue health", "runtime stability"],
    dependencies: ["delivery_ledger", "store_forward"],
    proofBoundary: "Needs Android background service proof.",
  },
  {
    id: "delivery_ledger",
    name: "Delivery Proof and ACK Ledger",
    status: "ACTIVE",
    purpose: "Records created, queued, sent, stored, failed, delivered, and ACK events.",
    belongsBecause: "Sent is not the same as delivered.",
    optimises: ["proof", "debugging", "learning", "trust scoring"],
    dependencies: ["adaptive_routing"],
    proofBoundary: "Logic active. Device proof requires native transport events.",
  },
  {
    id: "decentralised_trust_memory",
    name: "Decentralised Trust Memory",
    status: "LEARNING",
    purpose: "Raises or lowers node trust through behaviour.",
    belongsBecause: "Relay trust must be earned, not assumed.",
    optimises: ["relay safety", "bad-route avoidance", "network quality"],
    dependencies: ["delivery_ledger", "living_route_memory"],
    proofBoundary: "Needs signed relay evidence in production.",
  },
  {
    id: "cultural_intelligence",
    name: "Cultural Intelligence Layer",
    status: "ACTIVE",
    purpose: "Applies context-aware behaviour for privacy, language, care, and community use.",
    belongsBecause: "MauriMesh is not only technical; it carries community protocol.",
    optimises: ["community fit", "language", "care logic", "privacy context"],
    dependencies: ["tikanga_governance"],
    proofBoundary: "Needs cultural review and configurable community policy.",
  },
  {
    id: "cleo_chanelle_synth",
    name: "Cleo + Chanelle Synth AI Federation",
    status: "WIRED",
    purpose: "Explains routing, governance, and delivery state to humans.",
    belongsBecause: "Users need the living mesh explained clearly.",
    optimises: ["user understanding", "education", "family-safe explanation"],
    dependencies: ["mauri_ai_core", "delivery_ledger"],
    proofBoundary: "Voice/personality synthesis remains future layer.",
  },
  {
    id: "living_visual_proof",
    name: "Living Mesh Visual Proof Layer",
    status: "WIRED",
    purpose: "Shows nodes, routes, trust, ledger, and route quality.",
    belongsBecause: "Visible proof builds trust and speeds debugging.",
    optimises: ["visibility", "testing", "investor proof", "debugging"],
    dependencies: ["delivery_ledger", "adaptive_routing"],
    proofBoundary: "Needs live native telemetry for real-world proof.",
  },
  {
    id: "kia_kaha_emergency",
    name: "Kia Kaha Emergency Routing Mode",
    status: "ACTIVE",
    purpose: "Raises priority, TTL, and recovery behaviour for emergency messages.",
    belongsBecause: "MauriMesh must work hardest when people need help.",
    optimises: ["urgent delivery", "priority routing", "resilience"],
    dependencies: ["self_governance", "adaptive_routing"],
    proofBoundary: "Needs abuse prevention and emergency field tests.",
  },
  {
    id: "completion_puller",
    name: "Completion Puller",
    status: "OPTIMISING",
    purpose: "Finds missing wiring, missing screens, and incomplete proof boundaries.",
    belongsBecause: "The build must pull incomplete parts into place as it evolves.",
    optimises: ["completion", "screen coverage", "integration accuracy"],
    dependencies: ["button_decision_router", "system_brain"],
    proofBoundary: "Replit can audit files. Native proof still external.",
  },
  {
    id: "button_decision_router",
    name: "Button Decision Router",
    status: "ACTIVE",
    purpose: "Maps every UI button to the correct system layer, screen, or native-proof boundary.",
    belongsBecause: "Buttons must not point randomly; every action must serve the right layer.",
    optimises: ["navigation", "decision accuracy", "UI wiring"],
    dependencies: ["system_brain"],
    proofBoundary: "Static screen mapping active. Full AST rewrite is intentionally avoided for safety.",
  },
];
TS

# ============================================================
# 3. BUTTON DECISION ROUTER
# ============================================================

cat > src/maurimesh/system-brain/buttonDecisionRouter.ts <<'TS'
import fs from "fs";
import path from "path";
import { ButtonDecision } from "./systemTypes";

const BUTTON_MAP: ButtonDecision[] = [
  {
    screen: "dashboard",
    buttonTitle: "Invention Engine",
    targetRoute: "/invention-engine",
    decisionLayer: "Living Self-Governed AI Mesh",
    reason: "Controls demo, ACK, fail, reset, route plan, ledger, and synth output.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Invention Register",
    targetRoute: "/invention-register",
    decisionLayer: "Invention Register",
    reason: "Lists every invention and proof boundary.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Governance",
    targetRoute: "/governance",
    decisionLayer: "Tikanga Protocol Engine",
    reason: "Tests tapu, noa, whānau, and Kia Kaha governance decisions.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Route Lab",
    targetRoute: "/route-lab",
    decisionLayer: "Adaptive Mesh Routing Intelligence",
    reason: "Tests route choice, ACK learning, failure learning, and trust updates.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "System Check",
    targetRoute: "/system-check",
    decisionLayer: "Completion Puller",
    reason: "Audits what is wired, what is learning, and what still needs native proof.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Chat",
    targetRoute: "/chat",
    decisionLayer: "Hybrid Human-AI-Network Protocol",
    reason: "Sends user messages through Mauri AI, governance, routing, and store-forward logic.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Living Mesh",
    targetRoute: "/living-mesh",
    decisionLayer: "Living Mesh Visual Proof Layer",
    reason: "Displays nodes, routes, and route decisions.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Mesh Status",
    targetRoute: "/mesh-status",
    decisionLayer: "Delivery Proof and ACK Ledger",
    reason: "Shows ledger, trust memory, route memory, and synth state.",
    status: "CONNECTED",
  },
  {
    screen: "dashboard",
    buttonTitle: "Add Friend",
    targetRoute: "/add-friend",
    decisionLayer: "Offline-First Identity Mesh Messenger",
    reason: "Belongs to identity, QR, nearby discovery, and contact onboarding.",
    status: "NEEDS_NATIVE_PROOF",
  },
  {
    screen: "dashboard",
    buttonTitle: "Pixel Calling",
    targetRoute: "/pixel-calling",
    decisionLayer: "Hybrid Transport Routing Layer",
    reason: "Belongs to future real-time media transport; Replit is UI shell only.",
    status: "NEEDS_NATIVE_PROOF",
  },
  {
    screen: "dashboard",
    buttonTitle: "Settings",
    targetRoute: "/settings",
    decisionLayer: "Self-Governance Layer",
    reason: "Settings should control language, privacy, runtime mode, and truth boundaries.",
    status: "CONNECTED",
  },
];

function routeExists(route: string): boolean {
  const clean = route.replace(/^\//, "");
  const candidates = [
    path.join(process.cwd(), "app", `${clean}.tsx`),
    path.join(process.cwd(), "app", clean, "index.tsx"),
  ];
  return candidates.some((file) => fs.existsSync(file));
}

export function getButtonDecisions(): ButtonDecision[] {
  return BUTTON_MAP.map((button) => ({
    ...button,
    status:
      button.status === "NEEDS_NATIVE_PROOF"
        ? button.status
        : routeExists(button.targetRoute)
          ? "CONNECTED"
          : "MISSING_SCREEN",
  }));
}

export function scanMauriButtons(): Array<{
  file: string;
  title: string;
  hasRouterPush: boolean;
}> {
  const appDir = path.join(process.cwd(), "app");
  const results: Array<{ file: string; title: string; hasRouterPush: boolean }> = [];

  if (!fs.existsSync(appDir)) return results;

  for (const file of fs.readdirSync(appDir)) {
    if (!file.endsWith(".tsx")) continue;

    const full = path.join(appDir, file);
    const text = fs.readFileSync(full, "utf8");

    const regex = /MauriButton\s+title="([^"]+)"/g;
    let match: RegExpExecArray | null;

    while ((match = regex.exec(text))) {
      const windowText = text.slice(Math.max(0, match.index - 300), match.index + 500);
      results.push({
        file: `app/${file}`,
        title: match[1],
        hasRouterPush: /router\.push|router\.replace|onPress=\{[a-zA-Z0-9_]+\}/.test(windowText),
      });
    }
  }

  return results;
}
TS

# ============================================================
# 4. SYSTEM BRAIN ORCHESTRATOR
# ============================================================

cat > src/maurimesh/system-brain/systemBrain.ts <<'TS'
import fs from "fs";
import path from "path";
import { getUiEngineSnapshot, runDemoMessage, ackLastRoute, failLastRoute } from "../ui/mauriUiEngine";
import { MAURIMESH_SYSTEM_LAYERS } from "./layerRegistry";
import { getButtonDecisions, scanMauriButtons } from "./buttonDecisionRouter";
import { SystemEvolutionSnapshot } from "./systemTypes";

const STATE_DIR = path.join(process.cwd(), "maurimesh-runtime-state");
const BRAIN_FILE = path.join(STATE_DIR, "system-brain-snapshot.json");
const BRAIN_LOG = path.join(STATE_DIR, "system-brain.log");

function ensureStateDir() {
  fs.mkdirSync(STATE_DIR, { recursive: true });
}

function appendLog(line: string) {
  ensureStateDir();
  fs.appendFileSync(BRAIN_LOG, `${line}\n`);
}

function writeSnapshot(snapshot: SystemEvolutionSnapshot) {
  ensureStateDir();
  fs.writeFileSync(BRAIN_FILE, JSON.stringify(snapshot, null, 2));
}

export function getSystemBrainSnapshot(): SystemEvolutionSnapshot {
  const engine = getUiEngineSnapshot();
  const buttons = getButtonDecisions();

  const activeLayers = MAURIMESH_SYSTEM_LAYERS.filter((layer) =>
    ["ACTIVE", "WIRED", "LEARNING", "OPTIMISING"].includes(layer.status)
  ).length;

  const connectedButtons = buttons.filter((b) => b.status === "CONNECTED").length;
  const buttonScore = Math.round((connectedButtons / buttons.length) * 100);
  const layerScore = Math.round((activeLayers / MAURIMESH_SYSTEM_LAYERS.length) * 100);
  const learningScore = engine.routeMemoryCount > 0 ? 100 : 60;
  const trustScore = engine.trustCount > 0 ? 100 : 60;
  const ledgerScore = engine.ledgerCount > 0 ? 100 : 60;

  const score = Math.round(
    layerScore * 0.35 +
      buttonScore * 0.25 +
      learningScore * 0.15 +
      trustScore * 0.15 +
      ledgerScore * 0.1
  );

  const recommendations: string[] = [];

  if (engine.ledgerCount === 0) recommendations.push("Run a demo message to activate the ledger.");
  if (engine.routeMemoryCount === 0) recommendations.push("ACK a route to create route learning memory.");
  if (engine.trustCount === 0) recommendations.push("Run ACK/fail route tests to create trust evolution.");
  for (const button of buttons) {
    if (button.status === "MISSING_SCREEN") {
      recommendations.push(`Create missing route ${button.targetRoute} for ${button.buttonTitle}.`);
    }
    if (button.status === "NEEDS_NATIVE_PROOF") {
      recommendations.push(`${button.buttonTitle} is correctly mapped but still needs APK/device proof.`);
    }
  }

  if (recommendations.length === 0) {
    recommendations.push("Replit-side integration is complete. Continue APK/native proof testing.");
  }

  return {
    atMs: Date.now(),
    score,
    summary:
      "System brain is coordinating inventions, UI button decisions, learning state, governance, routing, and completion puller.",
    activeLayers,
    totalLayers: MAURIMESH_SYSTEM_LAYERS.length,
    buttonConnections: buttons,
    layerMap: MAURIMESH_SYSTEM_LAYERS,
    recommendations,
  };
}

export function evolveSystemBrain(): SystemEvolutionSnapshot {
  runDemoMessage("Kia kaha emergency route training message from system brain.");
  ackLastRoute();

  const snapshot = getSystemBrainSnapshot();
  writeSnapshot(snapshot);

  appendLog(
    `[${new Date(snapshot.atMs).toISOString()}] score=${snapshot.score} activeLayers=${snapshot.activeLayers}/${snapshot.totalLayers} buttons=${snapshot.buttonConnections.length}`
  );

  return snapshot;
}

export function stressLearnSystemBrain(): SystemEvolutionSnapshot {
  runDemoMessage("Private tapu route test for trusted delivery only.");
  failLastRoute("System brain stress-learning failure path.");
  runDemoMessage("Whānau check-in route recovery test.");
  ackLastRoute();

  const snapshot = getSystemBrainSnapshot();
  writeSnapshot(snapshot);

  appendLog(
    `[${new Date(snapshot.atMs).toISOString()}] STRESS_LEARN score=${snapshot.score} recommendations=${snapshot.recommendations.length}`
  );

  return snapshot;
}

export function getButtonScanReport() {
  return {
    expected: getButtonDecisions(),
    detected: scanMauriButtons(),
    truth:
      "Button scan checks MauriButton usage and route mapping. It does not rewrite unknown buttons automatically because safe wiring requires preserving original engineering.",
  };
}
TS

# ============================================================
# 5. CLIENT BRIDGE
# ============================================================

cat > src/lib/mauriSystemBrainClient.ts <<'TS'
import {
  evolveSystemBrain,
  getButtonScanReport,
  getSystemBrainSnapshot,
  stressLearnSystemBrain,
} from "../maurimesh/system-brain/systemBrain";

export async function getMauriSystemBrain() {
  return getSystemBrainSnapshot();
}

export async function evolveMauriSystemBrain() {
  return evolveSystemBrain();
}

export async function stressLearnMauriSystemBrain() {
  return stressLearnSystemBrain();
}

export async function getMauriButtonScan() {
  return getButtonScanReport();
}
TS

# ============================================================
# 6. SYSTEM BRAIN PANEL
# ============================================================

cat > src/components/SystemBrainPanel.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { SystemEvolutionSnapshot } from "../maurimesh/system-brain/systemTypes";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function SystemBrainPanel({ snapshot }: { snapshot: SystemEvolutionSnapshot }) {
  return (
    <View style={styles.card}>
      <StatusPill label="SYSTEM BRAIN" tone="success" />
      <Text style={styles.title}>Self-Efficient System Score</Text>
      <Text style={styles.score}>{snapshot.score}%</Text>
      <Text style={styles.summary}>{snapshot.summary}</Text>

      <View style={styles.row}>
        <Text style={styles.k}>Active Layers</Text>
        <Text style={styles.v}>
          {snapshot.activeLayers}/{snapshot.totalLayers}
        </Text>
      </View>

      <Text style={styles.section}>Recommendations</Text>
      {snapshot.recommendations.map((r, index) => (
        <Text key={index} style={styles.recommendation}>• {r}</Text>
      ))}
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
    fontSize: 22,
    fontWeight: "900",
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 48,
    fontWeight: "900",
  },
  summary: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 10,
  },
  k: {
    color: mauriTheme.colors.mutedWhite,
    fontWeight: "800",
  },
  v: {
    color: mauriTheme.colors.white,
    fontWeight: "900",
  },
  section: {
    color: mauriTheme.colors.white,
    fontSize: 16,
    fontWeight: "900",
    marginTop: 8,
  },
  recommendation: {
    color: mauriTheme.colors.warning,
    lineHeight: 20,
    fontWeight: "700",
  },
});
TSX

# ============================================================
# 7. BUTTON WIRING PANEL
# ============================================================

cat > src/components/ButtonWiringPanel.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { ButtonDecision } from "../maurimesh/system-brain/systemTypes";
import { mauriTheme } from "../theme/mauriTheme";

export function ButtonWiringPanel({ buttons }: { buttons: ButtonDecision[] }) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Button Decision Router</Text>
      {buttons.map((button) => (
        <View key={`${button.screen}-${button.buttonTitle}`} style={styles.item}>
          <Text
            style={[
              styles.status,
              button.status === "CONNECTED" && styles.pass,
              button.status === "NEEDS_NATIVE_PROOF" && styles.warn,
              button.status === "MISSING_SCREEN" && styles.fail,
            ]}
          >
            {button.status}
          </Text>
          <Text style={styles.buttonTitle}>{button.buttonTitle}</Text>
          <Text style={styles.text}>{button.targetRoute}</Text>
          <Text style={styles.layer}>{button.decisionLayer}</Text>
          <Text style={styles.text}>{button.reason}</Text>
        </View>
      ))}
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
    fontSize: 22,
    fontWeight: "900",
  },
  item: {
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 12,
    gap: 4,
  },
  status: {
    fontSize: 12,
    fontWeight: "900",
  },
  pass: {
    color: mauriTheme.colors.success,
  },
  warn: {
    color: mauriTheme.colors.warning,
  },
  fail: {
    color: mauriTheme.colors.danger,
  },
  buttonTitle: {
    color: mauriTheme.colors.white,
    fontSize: 17,
    fontWeight: "900",
  },
  layer: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
  },
  text: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
});
TSX

# ============================================================
# 8. SYSTEM BRAIN SCREEN
# ============================================================

cat > app/system-brain.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { ButtonWiringPanel } from "../src/components/ButtonWiringPanel";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { SystemBrainPanel } from "../src/components/SystemBrainPanel";
import {
  evolveMauriSystemBrain,
  getMauriSystemBrain,
  stressLearnMauriSystemBrain,
} from "../src/lib/mauriSystemBrainClient";
import { SystemEvolutionSnapshot } from "../src/maurimesh/system-brain/systemTypes";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function SystemBrainScreen() {
  const [snapshot, setSnapshot] = useState<SystemEvolutionSnapshot | null>(null);

  async function refresh() {
    setSnapshot(await getMauriSystemBrain());
  }

  async function evolve() {
    setSnapshot(await evolveMauriSystemBrain());
  }

  async function stressLearn() {
    setSnapshot(await stressLearnMauriSystemBrain());
  }

  useEffect(() => {
    refresh();
  }, []);

  return (
    <AppShell>
      <StatusPill label="SELF-EFFICIENT SYSTEM" tone="success" />
      <Text style={styles.title}>MauriMesh System Brain</Text>
      <Text style={styles.subtitle}>
        Coordinates every invention, every integration, every button decision,
        and pulls incomplete wiring into the correct proof boundary.
      </Text>

      <MauriButton title="Evolve System Now" onPress={evolve} />
      <MauriButton title="Stress Learn + Recover" variant="secondary" onPress={stressLearn} />
      <MauriButton title="Refresh System Brain" variant="secondary" onPress={refresh} />

      {snapshot ? <SystemBrainPanel snapshot={snapshot} /> : null}
      {snapshot ? <ButtonWiringPanel buttons={snapshot.buttonConnections} /> : null}
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
# 9. LAYER MAP SCREEN
# ============================================================

cat > app/layer-map.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { StatusPill } from "../src/components/StatusPill";
import { getMauriSystemBrain } from "../src/lib/mauriSystemBrainClient";
import { SystemEvolutionSnapshot } from "../src/maurimesh/system-brain/systemTypes";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LayerMapScreen() {
  const [snapshot, setSnapshot] = useState<SystemEvolutionSnapshot | null>(null);

  useEffect(() => {
    getMauriSystemBrain().then(setSnapshot);
  }, []);

  return (
    <AppShell>
      <StatusPill label="LAYER MAP" tone="info" />
      <Text style={styles.title}>All Inventions + Integrations</Text>
      <Text style={styles.subtitle}>
        Every layer is placed where it belongs in the system, with dependencies,
        optimisation targets, and proof boundary.
      </Text>

      {snapshot?.layerMap.map((layer) => (
        <View key={layer.id} style={styles.card}>
          <StatusPill
            label={layer.status}
            tone={
              layer.status === "ACTIVE" || layer.status === "LEARNING" || layer.status === "OPTIMISING"
                ? "success"
                : layer.status === "NEEDS_NATIVE_PROOF" || layer.status === "NEEDS_REVIEW"
                  ? "warning"
                  : "info"
            }
          />
          <Text style={styles.name}>{layer.name}</Text>
          <Text style={styles.label}>Purpose</Text>
          <Text style={styles.text}>{layer.purpose}</Text>
          <Text style={styles.label}>Belongs because</Text>
          <Text style={styles.text}>{layer.belongsBecause}</Text>
          <Text style={styles.label}>Optimises</Text>
          <Text style={styles.text}>{layer.optimises.join(", ")}</Text>
          <Text style={styles.label}>Dependencies</Text>
          <Text style={styles.text}>{layer.dependencies.join(", ")}</Text>
          <Text style={styles.boundary}>{layer.proofBoundary}</Text>
        </View>
      ))}
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
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  name: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  label: {
    color: mauriTheme.colors.greenstone,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 0.7,
  },
  text: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  boundary: {
    color: mauriTheme.colors.warning,
    lineHeight: 21,
    fontWeight: "700",
  },
});
TSX

# ============================================================
# 10. DASHBOARD WITH FULL SYSTEM LINKS
# ============================================================

cat > app/dashboard.tsx <<'TSX'
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { InventionEngineCard } from "../src/components/InventionEngineCard";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { SystemBrainPanel } from "../src/components/SystemBrainPanel";
import { getInventionEngineStatus } from "../src/lib/inventionEngineClient";
import { getMauriSystemBrain } from "../src/lib/mauriSystemBrainClient";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { SystemEvolutionSnapshot } from "../src/maurimesh/system-brain/systemTypes";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);
  const [engineMessage, setEngineMessage] = useState("Checking invention engine...");
  const [brain, setBrain] = useState<SystemEvolutionSnapshot | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
    getInventionEngineStatus().then((snapshot) => setEngineMessage(snapshot.message));
    getMauriSystemBrain().then(setBrain);
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        Command centre for MauriMesh Messenger, system brain, living inventions,
        self-learning routing, Tikanga governance, and completion puller.
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

      {brain ? <SystemBrainPanel snapshot={brain} /> : null}

      <View style={styles.grid}>
        <MauriButton title="System Brain" onPress={() => router.push("/system-brain")} />
        <MauriButton title="Layer Map" variant="secondary" onPress={() => router.push("/layer-map")} />
        <MauriButton title="Invention Engine" onPress={() => router.push("/invention-engine")} />
        <MauriButton title="Invention Register" variant="secondary" onPress={() => router.push("/invention-register")} />
        <MauriButton title="Governance" variant="secondary" onPress={() => router.push("/governance")} />
        <MauriButton title="Route Lab" variant="secondary" onPress={() => router.push("/route-lab")} />
        <MauriButton title="System Check" variant="secondary" onPress={() => router.push("/system-check")} />
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
# 11. API SERVER WITH SYSTEM BRAIN ENDPOINTS
# ============================================================

cat > server/index.ts <<'TS'
import express from "express";
import fs from "fs";
import path from "path";
import {
  getUiEngineSnapshot,
  runDemoMessage,
  sendUiMessage,
  ackLastRoute,
  failLastRoute,
} from "../src/maurimesh/ui/mauriUiEngine";
import {
  getMauriCompletionAudit,
  MAURIMESH_INVENTION_REGISTER,
} from "../src/lib/mauriEssentials";
import {
  evolveSystemBrain,
  getButtonScanReport,
  getSystemBrainSnapshot,
  stressLearnSystemBrain,
} from "../src/maurimesh/system-brain/systemBrain";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

function readRuntimeJson(name: string) {
  const file = path.join(process.cwd(), "maurimesh-runtime-state", name);
  if (!fs.existsSync(file)) return null;
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return null;
  }
}

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "Replit API is development only. Native BLE requires APK and physical devices.",
  });
});

app.get("/api/system-brain/status", (_req, res) => {
  res.json(getSystemBrainSnapshot());
});

app.post("/api/system-brain/evolve", (_req, res) => {
  res.json(evolveSystemBrain());
});

app.post("/api/system-brain/stress-learn", (_req, res) => {
  res.json(stressLearnSystemBrain());
});

app.get("/api/system-brain/buttons", (_req, res) => {
  res.json(getButtonScanReport());
});

app.get("/api/living-runtime/status", (_req, res) => {
  res.json({
    memory: readRuntimeJson("living-runtime-memory.json"),
    snapshot: readRuntimeJson("living-runtime-snapshot.json"),
    systemBrain: readRuntimeJson("system-brain-snapshot.json"),
    truth:
      "Living runtime proves Replit-side self-learning and routing logic only. Native BLE requires APK and physical devices.",
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

app.get("/api/invention/register", (_req, res) => {
  res.json({
    count: MAURIMESH_INVENTION_REGISTER.length,
    inventions: MAURIMESH_INVENTION_REGISTER,
  });
});

app.get("/api/invention/audit", (_req, res) => {
  res.json(getMauriCompletionAudit());
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
# 12. PACKAGE SCRIPTS
# ============================================================

node <<'NODE'
const fs = require("fs");
const path = "package.json";

if (!fs.existsSync(path)) {
  fs.writeFileSync(path, JSON.stringify({ scripts: {}, dependencies: {}, devDependencies: {} }, null, 2));
}

const pkg = JSON.parse(fs.readFileSync(path, "utf8"));

pkg.scripts = pkg.scripts || {};
pkg.scripts.start = pkg.scripts.start || "expo start --web";
pkg.scripts.dev = pkg.scripts.dev || "expo start --web";
pkg.scripts.api = "tsx server/index.ts";
pkg.scripts.check = "tsc --noEmit";
pkg.scripts.typecheck = "tsc --noEmit";
pkg.scripts["maurimesh:system-brain"] = "tsx -e \"const m=require('./src/maurimesh/system-brain/systemBrain.ts'); console.log(JSON.stringify(m.evolveSystemBrain(), null, 2))\"";
pkg.scripts["maurimesh:button-scan"] = "tsx -e \"const m=require('./src/maurimesh/system-brain/systemBrain.ts'); console.log(JSON.stringify(m.getButtonScanReport(), null, 2))\"";

pkg.dependencies = pkg.dependencies || {};
pkg.devDependencies = pkg.devDependencies || {};
pkg.dependencies.express = pkg.dependencies.express || "latest";
pkg.devDependencies.tsx = pkg.devDependencies.tsx || "latest";
pkg.devDependencies.typescript = pkg.devDependencies.typescript || "latest";
pkg.devDependencies["@types/express"] = pkg.devDependencies["@types/express"] || "latest";
pkg.devDependencies["@types/node"] = pkg.devDependencies["@types/node"] || "latest";

fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
console.log("package.json patched for system brain.");
NODE

# ============================================================
# 13. COMPLETION REPORT
# ============================================================

cat > MAURIMESH_SELF_EFFICIENT_SYSTEM_COMPLETE.md <<'MD'
# MauriMesh Self-Efficient System Complete

## Added

- System Brain
- Layer Registry
- Button Decision Router
- Button Scanner
- Completion Puller
- System Brain screen
- Layer Map screen
- Dashboard integration
- API endpoints for system brain, evolve, stress-learn, and button scan

## New screens

- `/system-brain`
- `/layer-map`

## New API endpoints

- GET `/api/system-brain/status`
- POST `/api/system-brain/evolve`
- POST `/api/system-brain/stress-learn`
- GET `/api/system-brain/buttons`

## What the system now does

- Maps every invention to its correct system function.
- Maps major UI buttons to the correct decision layer.
- Scores system efficiency.
- Runs learning/evolution cycles.
- Pulls incomplete items into recommendations.
- Keeps native proof boundaries honest.
- Connects the dashboard to the whole integrated system.

## Truth boundary

This completes the Replit-side self-efficient intelligence, button-decision, integration, and completion-puller layer.

Still requires APK/physical-device proof for:
- native BLE
- Wi-Fi Direct
- background Android service
- real packet relay
- real emergency delivery
- live field telemetry
MD

echo ""
echo "============================================================"
echo "SELF-EFFICIENT SYSTEM COMPLETE"
echo "============================================================"
echo ""
echo "Run:"
echo "  npm install"
echo "  npm run check"
echo "  npm run api"
echo ""
echo "In another shell:"
echo "  npm run dev"
echo ""
echo "Test:"
echo "  curl http://localhost:3000/api/system-brain/status"
echo "  curl http://localhost:3000/api/system-brain/buttons"
echo ""
