#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "COMPLETE MAURIMESH INVENTIONS + UI ESSENTIALS"
echo "Register + Governance + Route Lab + System Check + Audit"
echo "============================================================"
echo ""

ROOT="$(pwd)"
BACKUP="$ROOT/backup-before-final-ui-essentials-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"
mkdir -p app
mkdir -p src/lib
mkdir -p src/components
mkdir -p server

echo "Backing up selected files..."
for f in \
  app/dashboard.tsx \
  app/settings.tsx \
  server/index.ts \
  src/lib/mauriEssentials.ts \
  src/components/CompletionAuditPanel.tsx
do
  if [ -f "$f" ]; then
    mkdir -p "$BACKUP/$(dirname "$f")"
    cp "$f" "$BACKUP/$f"
  fi
done

if [ ! -f "src/maurimesh/ui/mauriUiEngine.ts" ]; then
  echo "ERROR: UI engine bridge missing."
  echo "Run wire-maurimesh-invention-engine-to-replit-ui.sh first."
  exit 1
fi

# ============================================================
# 1. ESSENTIALS LIBRARY
# ============================================================

cat > src/lib/mauriEssentials.ts <<'TS'
import { getUiEngineSnapshot } from "../maurimesh/ui/mauriUiEngine";

export type InventionStatus =
  | "CODED_LOGIC"
  | "UI_WIRED"
  | "NEEDS_NATIVE_PROOF"
  | "NEEDS_FIELD_TEST"
  | "PROTECTED_CONCEPT";

export type MauriInventionRecord = {
  id: number;
  name: string;
  status: InventionStatus;
  reason: string;
  enhances: string;
  proofBoundary: string;
};

export const MAURIMESH_INVENTION_REGISTER: MauriInventionRecord[] = [
  {
    id: 1,
    name: "Offline-First Identity Mesh Messenger",
    status: "CODED_LOGIC",
    reason: "Gives devices identity before depending on internet or SIM-based delivery.",
    enhances: "Allows MauriMesh to act as a trusted local messenger during weak or failed connectivity.",
    proofBoundary: "Needs APK and physical phone validation for native BLE identity exchange.",
  },
  {
    id: 2,
    name: "Living Route Memory",
    status: "CODED_LOGIC",
    reason: "Records route success, failure, latency, and trust change.",
    enhances: "Makes routing stronger over time instead of static.",
    proofBoundary: "Needs real packet outcomes from phones to become field-proven.",
  },
  {
    id: 3,
    name: "Tikanga-Based Network Governance",
    status: "UI_WIRED",
    reason: "Adds cultural and ethical decision rules before route selection.",
    enhances: "Prevents raw speed or automation from overriding safety, consent, and protocol.",
    proofBoundary: "Needs cultural review before public or iwi/community deployment.",
  },
  {
    id: 4,
    name: "Mauri AI Routing Conscience",
    status: "CODED_LOGIC",
    reason: "Balances signal, battery, trust, urgency, privacy, and delivery chance.",
    enhances: "Makes the network intelligent without becoming reckless.",
    proofBoundary: "Needs field telemetry to tune weighting.",
  },
  {
    id: 5,
    name: "Cleo + Chanelle Synth AI Federation",
    status: "UI_WIRED",
    reason: "Creates a human-facing explanation layer for mesh decisions.",
    enhances: "Helps users understand routing, delivery, emergency state, and safety.",
    proofBoundary: "Needs voice/personality layer later if used as real synth AI.",
  },
  {
    id: 6,
    name: "Self-Healing Messenger Runtime",
    status: "CODED_LOGIC",
    reason: "Detects failed packets, stale nodes, missing ACKs, and recovery actions.",
    enhances: "Keeps the system alive under real-world failure.",
    proofBoundary: "Needs Android background service integration.",
  },
  {
    id: 7,
    name: "Store-and-Forward Social Mesh",
    status: "CODED_LOGIC",
    reason: "Stores messages when the recipient is unavailable and forwards later.",
    enhances: "Allows delayed offline delivery across broken time windows.",
    proofBoundary: "Needs persistent encrypted local storage in APK.",
  },
  {
    id: 8,
    name: "Living Mesh Visual Proof Layer",
    status: "UI_WIRED",
    reason: "Shows nodes, routes, ledger, route quality, and engine state.",
    enhances: "Turns invisible routing into visible proof.",
    proofBoundary: "Needs live native telemetry feed for real-world proof.",
  },
  {
    id: 9,
    name: "Hybrid Human-AI-Network Protocol",
    status: "CODED_LOGIC",
    reason: "Combines user intent, AI routing, governance, and device network behaviour.",
    enhances: "Makes MauriMesh a coordination protocol, not only a chat app.",
    proofBoundary: "Needs full integration with native send/receive pipeline.",
  },
  {
    id: 10,
    name: "Kia Kaha Emergency Routing Mode",
    status: "CODED_LOGIC",
    reason: "Raises priority, TTL, and emergency routing behaviour under urgent conditions.",
    enhances: "Positions MauriMesh for outage and safety use cases.",
    proofBoundary: "Needs strict abuse prevention and physical test proof.",
  },
  {
    id: 11,
    name: "Tapu / Noa Digital Privacy States",
    status: "CODED_LOGIC",
    reason: "Applies contextual privacy states to packets and relay permissions.",
    enhances: "Adds deeper privacy than simple public/private toggles.",
    proofBoundary: "Needs legal and cultural review before public claims.",
  },
  {
    id: 12,
    name: "Pathway + Pipeline Dual Architecture",
    status: "CODED_LOGIC",
    reason: "Separates where a message travels from how it is processed.",
    enhances: "Improves debugging, scaling, and proof reporting.",
    proofBoundary: "Needs full production telemetry logging.",
  },
  {
    id: 13,
    name: "Decentralised Trust Memory",
    status: "CODED_LOGIC",
    reason: "Lets node trust rise or fall based on behaviour.",
    enhances: "Reduces reliance on unreliable or unsafe relays.",
    proofBoundary: "Needs anti-spoofing and signed relay evidence.",
  },
  {
    id: 14,
    name: "Mesh Messenger as Community Infrastructure",
    status: "PROTECTED_CONCEPT",
    reason: "Frames the messenger as local community resilience infrastructure.",
    enhances: "Supports families, iwi, schools, hospitals, security, rural areas, and emergencies.",
    proofBoundary: "Needs pilot partners and deployment governance.",
  },
  {
    id: 15,
    name: "Living Self-Governed AI Mesh",
    status: "UI_WIRED",
    reason: "Unifies mesh routing, self-learning, self-healing, governance, cultural protocol, and synth explanation.",
    enhances: "Creates the master MauriMesh operating model.",
    proofBoundary: "Needs APK proof, two-phone proof, and multi-device field testing.",
  },
];

export type MauriAuditItem = {
  name: string;
  status: "PASS" | "WARN" | "FAIL";
  detail: string;
};

export type MauriCompletionAudit = {
  score: number;
  summary: string;
  items: MauriAuditItem[];
};

export function getMauriCompletionAudit(): MauriCompletionAudit {
  const snapshot = getUiEngineSnapshot();

  const items: MauriAuditItem[] = [
    {
      name: "Invention engine bridge",
      status: snapshot.mode === "LIVE_ENGINE" ? "PASS" : "FAIL",
      detail: snapshot.message,
    },
    {
      name: "Living mesh nodes",
      status: snapshot.nodes.length > 0 ? "PASS" : "FAIL",
      detail: `${snapshot.nodes.length} node(s) visible to UI.`,
    },
    {
      name: "Route visualisation",
      status: snapshot.routes.length > 0 ? "PASS" : "WARN",
      detail: `${snapshot.routes.length} route(s) visible to UI.`,
    },
    {
      name: "Delivery ledger",
      status: snapshot.ledgerCount > 0 ? "PASS" : "WARN",
      detail:
        snapshot.ledgerCount > 0
          ? `${snapshot.ledgerCount} ledger event(s) recorded.`
          : "No ledger events yet. Run a demo message.",
    },
    {
      name: "Trust memory",
      status: snapshot.trustCount > 0 ? "PASS" : "WARN",
      detail:
        snapshot.trustCount > 0
          ? `${snapshot.trustCount} trust record(s) active.`
          : "No trust memory yet. Run a demo and ACK/fail route.",
    },
    {
      name: "Route memory",
      status: snapshot.routeMemoryCount > 0 ? "PASS" : "WARN",
      detail:
        snapshot.routeMemoryCount > 0
          ? `${snapshot.routeMemoryCount} route learning record(s) active.`
          : "No learned route yet. ACK a route to create memory.",
    },
    {
      name: "Native BLE proof",
      status: "WARN",
      detail: "Not proven in Replit. Requires Android APK and physical phones.",
    },
    {
      name: "Wi-Fi Direct proof",
      status: "WARN",
      detail: "Not proven in Replit. Requires native Android integration.",
    },
    {
      name: "Background runtime proof",
      status: "WARN",
      detail: "Not proven in Replit. Requires Android service validation.",
    },
  ];

  const pass = items.filter((i) => i.status === "PASS").length;
  const score = Math.round((pass / items.length) * 100);

  return {
    score,
    summary:
      "MauriMesh inventions and UI are wired as a Replit-safe logic layer. Native transport proof remains APK/device work.",
    items,
  };
}
TS

# ============================================================
# 2. COMPLETION AUDIT PANEL
# ============================================================

cat > src/components/CompletionAuditPanel.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { MauriCompletionAudit } from "../lib/mauriEssentials";
import { mauriTheme } from "../theme/mauriTheme";

export function CompletionAuditPanel({ audit }: { audit: MauriCompletionAudit }) {
  return (
    <View style={styles.card}>
      <Text style={styles.title}>Completion Audit</Text>
      <Text style={styles.score}>{audit.score}%</Text>
      <Text style={styles.summary}>{audit.summary}</Text>

      {audit.items.map((item) => (
        <View key={item.name} style={styles.item}>
          <Text
            style={[
              styles.status,
              item.status === "PASS" && styles.pass,
              item.status === "WARN" && styles.warn,
              item.status === "FAIL" && styles.fail,
            ]}
          >
            {item.status}
          </Text>
          <View style={styles.itemBody}>
            <Text style={styles.itemName}>{item.name}</Text>
            <Text style={styles.detail}>{item.detail}</Text>
          </View>
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
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 44,
    fontWeight: "900",
  },
  summary: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  item: {
    flexDirection: "row",
    gap: 12,
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
    paddingTop: 12,
  },
  status: {
    width: 48,
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
  itemBody: {
    flex: 1,
    gap: 4,
  },
  itemName: {
    color: mauriTheme.colors.white,
    fontWeight: "900",
  },
  detail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
});
TSX

# ============================================================
# 3. INVENTION REGISTER SCREEN
# ============================================================

cat > app/invention-register.tsx <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { StatusPill } from "../src/components/StatusPill";
import { MAURIMESH_INVENTION_REGISTER } from "../src/lib/mauriEssentials";
import { mauriTheme } from "../src/theme/mauriTheme";

function toneForStatus(status: string): "success" | "warning" | "danger" | "info" {
  if (status === "UI_WIRED" || status === "CODED_LOGIC") return "success";
  if (status === "PROTECTED_CONCEPT") return "info";
  return "warning";
}

export default function InventionRegisterScreen() {
  return (
    <AppShell>
      <StatusPill label="OFFICIAL REGISTER" tone="success" />
      <Text style={styles.title}>MauriMesh Invention Register</Text>
      <Text style={styles.subtitle}>
        All invention candidates are listed with their current build status,
        reason, enhancement value, and proof boundary.
      </Text>

      {MAURIMESH_INVENTION_REGISTER.map((item) => (
        <View key={item.id} style={styles.card}>
          <StatusPill label={item.status} tone={toneForStatus(item.status)} />
          <Text style={styles.itemTitle}>
            {item.id}. {item.name}
          </Text>
          <Text style={styles.label}>Reason it belongs</Text>
          <Text style={styles.text}>{item.reason}</Text>
          <Text style={styles.label}>Enhancement</Text>
          <Text style={styles.text}>{item.enhances}</Text>
          <Text style={styles.label}>Proof boundary</Text>
          <Text style={styles.boundary}>{item.proofBoundary}</Text>
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
  itemTitle: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  label: {
    color: mauriTheme.colors.greenstone,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 0.7,
    marginTop: 6,
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
# 4. GOVERNANCE SCREEN
# ============================================================

cat > app/governance.tsx <<'TSX'
import React, { useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { RoutePlanPanel } from "../src/components/RoutePlanPanel";
import { StatusPill } from "../src/components/StatusPill";
import { SynthPanel } from "../src/components/SynthPanel";
import { sendMessageThroughInventionEngine } from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof sendMessageThroughInventionEngine>>;

export default function GovernanceScreen() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  async function sendPrivate() {
    setSnapshot(await sendMessageThroughInventionEngine("Private tapu message for trusted delivery only."));
  }

  async function sendFamily() {
    setSnapshot(await sendMessageThroughInventionEngine("Whānau family check-in through MauriMesh."));
  }

  async function sendEmergency() {
    setSnapshot(await sendMessageThroughInventionEngine("Kia kaha emergency help message."));
  }

  const governance = snapshot?.lastResult?.governance;

  return (
    <AppShell>
      <StatusPill label="TIKANGA PROTOCOL ENGINE" tone="success" />
      <Text style={styles.title}>Governance</Text>
      <Text style={styles.subtitle}>
        Test how MauriMesh classifies messages into cultural/privacy states before routing.
      </Text>

      <View style={styles.buttons}>
        <MauriButton title="Test Tapu / Private" onPress={sendPrivate} />
        <MauriButton title="Test Whānau / Trusted" variant="secondary" onPress={sendFamily} />
        <MauriButton title="Test Kia Kaha / Emergency" variant="danger" onPress={sendEmergency} />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Governance Decision</Text>
        {!governance ? (
          <Text style={styles.text}>No governance decision yet.</Text>
        ) : (
          <>
            <Text style={styles.state}>{governance.culturalState}</Text>
            <Text style={styles.text}>{governance.reason}</Text>
            {governance.restrictions.map((r, index) => (
              <Text key={index} style={styles.restriction}>• {r}</Text>
            ))}
          </>
        )}
      </View>

      <RoutePlanPanel routePlan={snapshot?.lastResult?.routePlan} />
      <SynthPanel messages={snapshot?.lastResult?.synth || []} />
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
  buttons: {
    gap: mauriTheme.spacing.md,
  },
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  cardTitle: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  state: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  text: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  restriction: {
    color: mauriTheme.colors.warning,
    lineHeight: 20,
    fontWeight: "700",
  },
});
TSX

# ============================================================
# 5. ROUTE LAB SCREEN
# ============================================================

cat > app/route-lab.tsx <<'TSX'
import React, { useState } from "react";
import { StyleSheet, Text, TextInput, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { DeliveryLedgerPanel } from "../src/components/DeliveryLedgerPanel";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { MauriButton } from "../src/components/MauriButton";
import { RoutePlanPanel } from "../src/components/RoutePlanPanel";
import { StatusPill } from "../src/components/StatusPill";
import { SynthPanel } from "../src/components/SynthPanel";
import {
  ackInventionRoute,
  failInventionRoute,
  getInventionEngineStatus,
  sendMessageThroughInventionEngine,
} from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof getInventionEngineStatus>>;

export default function RouteLabScreen() {
  const [message, setMessage] = useState("Kia kaha emergency help message through MauriMesh.");
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  async function run() {
    setSnapshot(await sendMessageThroughInventionEngine(message));
  }

  async function ack() {
    setSnapshot(await ackInventionRoute());
  }

  async function fail() {
    setSnapshot(await failInventionRoute());
  }

  return (
    <AppShell>
      <StatusPill label="ROUTE LAB" tone="info" />
      <Text style={styles.title}>Route Lab</Text>
      <Text style={styles.subtitle}>
        Test routing decisions, store-and-forward, ACK learning, failed-route learning,
        trust memory, and synth explanations.
      </Text>

      <TextInput
        style={styles.input}
        multiline
        value={message}
        onChangeText={setMessage}
        placeholder="Type route test message..."
        placeholderTextColor="rgba(255,255,255,0.45)"
      />

      <View style={styles.buttons}>
        <MauriButton title="Run Route Test" onPress={run} />
        <MauriButton title="ACK Last Route" variant="secondary" onPress={ack} />
        <MauriButton title="Fail Last Route" variant="danger" onPress={fail} />
      </View>

      <LivingMeshCanvas nodes={snapshot?.nodes || []} routes={snapshot?.routes || []} />
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
  input: {
    minHeight: 110,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    color: mauriTheme.colors.white,
    paddingHorizontal: mauriTheme.spacing.md,
    paddingVertical: mauriTheme.spacing.md,
    backgroundColor: mauriTheme.colors.panel,
  },
  buttons: {
    gap: mauriTheme.spacing.md,
  },
});
TSX

# ============================================================
# 6. SYSTEM CHECK SCREEN
# ============================================================

cat > app/system-check.tsx <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { CompletionAuditPanel } from "../src/components/CompletionAuditPanel";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { getMauriCompletionAudit, MauriCompletionAudit } from "../src/lib/mauriEssentials";
import { runInventionDemo } from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function SystemCheckScreen() {
  const [audit, setAudit] = useState<MauriCompletionAudit | null>(null);

  function refresh() {
    setAudit(getMauriCompletionAudit());
  }

  async function demoThenAudit() {
    await runInventionDemo();
    refresh();
  }

  useEffect(() => {
    refresh();
  }, []);

  return (
    <AppShell>
      <StatusPill label="SYSTEM CHECK" tone="success" />
      <Text style={styles.title}>MauriMesh System Check</Text>
      <Text style={styles.subtitle}>
        Final Replit-side audit for invention engine, UI wiring, ledger, route memory,
        trust memory, and native proof boundaries.
      </Text>

      <MauriButton title="Run Demo + Refresh Audit" onPress={demoThenAudit} />
      <MauriButton title="Refresh Audit" variant="secondary" onPress={refresh} />

      {audit ? <CompletionAuditPanel audit={audit} /> : null}

      <Text style={styles.truth}>
        Completion truth: Replit can prove logic, screens, state transitions, and API wiring.
        Physical phone proof is still required for real BLE, Wi-Fi Direct, background service,
        and offline phone-to-phone packet transport.
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
  truth: {
    color: mauriTheme.colors.warning,
    fontSize: 13,
    lineHeight: 20,
    fontWeight: "700",
  },
});
TSX

# ============================================================
# 7. DASHBOARD FINAL LINKS
# ============================================================

cat > app/dashboard.tsx <<'TSX'
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { CompletionAuditPanel } from "../src/components/CompletionAuditPanel";
import { InventionEngineCard } from "../src/components/InventionEngineCard";
import { MauriButton } from "../src/components/MauriButton";
import { MeshSignalCard } from "../src/components/MeshSignalCard";
import { getMauriCompletionAudit, MauriCompletionAudit } from "../src/lib/mauriEssentials";
import { getInventionEngineStatus } from "../src/lib/inventionEngineClient";
import { getMeshStatus, MeshStatus } from "../src/lib/meshClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DashboardScreen() {
  const router = useRouter();
  const [mesh, setMesh] = useState<MeshStatus | null>(null);
  const [engineMessage, setEngineMessage] = useState("Checking invention engine...");
  const [audit, setAudit] = useState<MauriCompletionAudit | null>(null);

  useEffect(() => {
    getMeshStatus().then(setMesh);
    getInventionEngineStatus().then((snapshot) => setEngineMessage(snapshot.message));
    setAudit(getMauriCompletionAudit());
  }, []);

  const mode = mesh?.mode || "UNAVAILABLE";

  return (
    <AppShell>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.subtitle}>
        Command centre for MauriMesh Messenger, invention register, living mesh,
        Mauri AI, Tikanga governance, routing intelligence, and Replit-safe proof.
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

      {audit ? <CompletionAuditPanel audit={audit} /> : null}
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
# 8. SERVER FINAL API WITH AUDIT ENDPOINT
# ============================================================

cat > server/index.ts <<'TS'
import express from "express";
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
# 9. FINAL PROJECT REPORT
# ============================================================

cat > MAURIMESH_FINAL_INVENTIONS_UI_COMPLETION.md <<'MD'
# MauriMesh Final Inventions + UI Completion

## Added final essentials

- Invention Register screen
- Governance screen
- Route Lab screen
- System Check screen
- Completion Audit component
- Final dashboard links
- API invention register endpoint
- API invention audit endpoint
- Replit-safe proof boundary report

## New screens

- `/invention-register`
- `/governance`
- `/route-lab`
- `/system-check`

## Existing wired screens

- `/dashboard`
- `/chat`
- `/living-mesh`
- `/mesh-status`
- `/invention-engine`

## API endpoints

- GET `/api/health`
- GET `/api/mesh/status`
- GET `/api/invention/status`
- GET `/api/invention/register`
- GET `/api/invention/audit`
- POST `/api/invention/demo`
- POST `/api/invention/send`
- POST `/api/invention/ack`
- POST `/api/invention/fail`

## Current truth

Completed in Replit:
- Logic engine
- UI wiring
- Invention register
- Governance demo
- Route lab
- Store-and-forward logic
- ACK/fail simulation
- Route memory logic
- Trust memory logic
- Cleo + Chanelle Synth explanation
- Living mesh visual proof
- Completion audit

Still requires APK/phones:
- Real BLE packet transfer
- Real Wi-Fi Direct transport
- Android background service
- Persistent encrypted local packet store
- Multi-device relay field test
- Real emergency-routing field proof
MD

# ============================================================
# 10. PACKAGE PATCH
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
pkg.scripts["maurimesh:ui-check"] = "tsc --noEmit";
pkg.scripts["maurimesh:invention-demo"] = "tsx src/maurimesh/invention-engine/demo.ts";

pkg.dependencies = pkg.dependencies || {};
pkg.devDependencies = pkg.devDependencies || {};
pkg.dependencies.express = pkg.dependencies.express || "latest";
pkg.devDependencies.tsx = pkg.devDependencies.tsx || "latest";
pkg.devDependencies.typescript = pkg.devDependencies.typescript || "latest";
pkg.devDependencies["@types/express"] = pkg.devDependencies["@types/express"] || "latest";

fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
console.log("package.json patched for final essentials.");
NODE

echo ""
echo "============================================================"
echo "FINAL ESSENTIALS COMPLETE"
echo "============================================================"
echo ""
echo "Added:"
echo "  app/invention-register.tsx"
echo "  app/governance.tsx"
echo "  app/route-lab.tsx"
echo "  app/system-check.tsx"
echo "  src/lib/mauriEssentials.ts"
echo "  src/components/CompletionAuditPanel.tsx"
echo "  Updated dashboard"
echo "  Updated API server"
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
echo "  curl http://localhost:3000/api/invention/register"
echo "  curl http://localhost:3000/api/invention/audit"
echo ""
