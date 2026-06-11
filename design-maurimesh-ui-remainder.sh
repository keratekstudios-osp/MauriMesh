#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH UI REMAINDER DESIGNER"
echo "Scans current UI and creates the design plan for what is left"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
APP="$ROOT/app"
SRC="$ROOT/src"
COMP="$SRC/components"
THEME="$SRC/theme"
LIB="$SRC/lib"

mkdir -p "$DOCS" "$APP" "$COMP" "$THEME" "$LIB"

REPORT="$DOCS/maurimesh-ui-remainder-blueprint-$STAMP.md"
JSON="$DOCS/maurimesh-ui-remainder-tasks-$STAMP.json"
LATEST="$DOCS/maurimesh-ui-remainder-blueprint-latest.md"

pass=0
missing=0
partial=0

check_file() {
  local file="$1"
  local label="$2"
  if [ -f "$ROOT/$file" ]; then
    echo "FOUND|$label|$file"
    pass=$((pass+1))
  else
    echo "MISSING|$label|$file"
    missing=$((missing+1))
  fi
}

check_marker() {
  local file="$1"
  local marker="$2"
  local label="$3"
  if [ -f "$ROOT/$file" ] && grep -Fq "$marker" "$ROOT/$file"; then
    echo "FOUND|$label|$file contains $marker"
    pass=$((pass+1))
  else
    echo "PARTIAL|$label|$file missing marker: $marker"
    partial=$((partial+1))
  fi
}

SCAN="$(mktemp)"

{
  echo "SCREEN CHECKS"
  check_file "app/login.tsx" "Login screen"
  check_file "app/dashboard.tsx" "Dashboard screen"
  check_file "app/chat.tsx" "Chat screen"
  check_file "app/settings.tsx" "Settings screen"
  check_file "app/add-friend.tsx" "Add Friend screen"
  check_file "app/living-mesh.tsx" "Living Mesh screen"
  check_file "app/mesh-status.tsx" "Mesh Status screen"
  check_file "app/pixel-calling.tsx" "Pixel Calling screen"
  check_file "app/mauricore-governance.tsx" "MauriCore Governance screen"
  check_file "app/mauricore-ble-runtime.tsx" "MauriCore BLE Runtime screen"
  check_file "app/proof-ledger.tsx" "Proof Ledger screen"
  check_file "app/route-lab.tsx" "Route Lab screen"
  check_file "app/tikanga-engine.tsx" "Tikanga Engine screen"
  check_file "app/self-healing.tsx" "Self-Healing screen"
  check_file "app/operator-console.tsx" "Operator Console screen"
  check_file "app/device-proof.tsx" "Device Proof screen"
  check_file "app/ui-roadmap.tsx" "UI Roadmap screen"

  echo ""
  echo "COMPONENT CHECKS"
  check_file "src/components/AppShell.tsx" "AppShell"
  check_file "src/components/MauriButton.tsx" "MauriButton"
  check_file "src/components/StatusPill.tsx" "StatusPill"
  check_file "src/components/MeshSignalCard.tsx" "MeshSignalCard"
  check_file "src/components/LivingMeshCanvas.tsx" "LivingMeshCanvas"
  check_file "src/components/ChatBubble.tsx" "ChatBubble"
  check_file "src/components/UiRoadmapCard.tsx" "UiRoadmapCard"
  check_file "src/components/ProofLedgerPanel.tsx" "ProofLedgerPanel"
  check_file "src/components/RouteDecisionPanel.tsx" "RouteDecisionPanel"
  check_file "src/components/TikangaDecisionCard.tsx" "TikangaDecisionCard"
  check_file "src/components/SelfHealingPanel.tsx" "SelfHealingPanel"
  check_file "src/components/DeviceProofCard.tsx" "DeviceProofCard"
  check_file "src/components/MauriCoreStatusPanel.tsx" "MauriCoreStatusPanel"

  echo ""
  echo "LIBRARY CHECKS"
  check_file "src/theme/mauriTheme.ts" "Mauri theme"
  check_file "src/lib/api.ts" "API client"
  check_file "src/lib/meshClient.ts" "Mesh client"
  check_file "src/lib/simulation.ts" "Simulation data"
  check_file "src/lib/uiRemainder.ts" "UI remainder data"

  echo ""
  echo "MARKER CHECKS"
  check_marker "app/dashboard.tsx" "/chat" "Dashboard Chat route"
  check_marker "app/dashboard.tsx" "/living-mesh" "Dashboard Living Mesh route"
  check_marker "app/dashboard.tsx" "/mesh-status" "Dashboard Mesh Status route"
  check_marker "app/dashboard.tsx" "/pixel-calling" "Dashboard Pixel Calling route"
  check_marker "app/dashboard.tsx" "/add-friend" "Dashboard Add Friend route"
  check_marker "app/dashboard.tsx" "/settings" "Dashboard Settings route"
  check_marker "app/pixel-calling.tsx" "UI SHELL" "Pixel Calling truth label"
  check_marker "app/living-mesh.tsx" "SIMULATION" "Living Mesh simulation label"
  check_marker "src/lib/meshClient.ts" "SIMULATION" "Mesh simulation fallback"
} > "$SCAN"

TOTAL=$((pass + missing + partial))
if [ "$TOTAL" -eq 0 ]; then
  SCORE=0
else
  SCORE=$((pass * 100 / TOTAL))
fi

cat > "$SRC/lib/uiRemainder.ts" <<'TS'
export type UiRemainderTask = {
  id: string;
  title: string;
  area: "screen" | "component" | "native-proof" | "data" | "design-system" | "navigation";
  priority: "P0" | "P1" | "P2" | "P3";
  status: "missing" | "partial" | "ready" | "requires-device-proof";
  why: string;
  build: string[];
  acceptance: string[];
};

export const uiRemainderTasks: UiRemainderTask[] = [
  {
    id: "ui-001",
    title: "Proof Ledger Screen",
    area: "screen",
    priority: "P0",
    status: "missing",
    why: "You need a visual proof page showing packet ID, hash, route, ACK state, timestamp, and truth label.",
    build: [
      "Create app/proof-ledger.tsx",
      "Create src/components/ProofLedgerPanel.tsx",
      "Show packet proof rows",
      "Clearly label SIMULATION vs DEVICE PROOF",
      "Add dashboard button to /proof-ledger"
    ],
    acceptance: [
      "Screen opens without crash",
      "Shows packet ID, route, hash, ACK status",
      "Does not claim real BLE unless APK/device proof exists"
    ]
  },
  {
    id: "ui-002",
    title: "Route Lab Screen",
    area: "screen",
    priority: "P0",
    status: "missing",
    why: "You need a UI where routing decisions are visible: BLE, Wi-Fi, relay, internet fallback, TTL, trust, and path score.",
    build: [
      "Create app/route-lab.tsx",
      "Create src/components/RouteDecisionPanel.tsx",
      "Show candidate routes",
      "Show chosen route reason",
      "Add dashboard button to /route-lab"
    ],
    acceptance: [
      "Shows at least 3 route candidates",
      "Shows selected route",
      "Shows why the system selected that route"
    ]
  },
  {
    id: "ui-003",
    title: "Tikanga Engine Screen",
    area: "screen",
    priority: "P0",
    status: "missing",
    why: "The governance engine needs a dedicated screen showing approve/warn/review/refuse decisions.",
    build: [
      "Create app/tikanga-engine.tsx",
      "Create src/components/TikangaDecisionCard.tsx",
      "Show mana, tapu/noa, cultural risk, decision, and audit note",
      "Add dashboard button to /tikanga-engine"
    ],
    acceptance: [
      "Shows governance decision",
      "Shows cultural risk level",
      "Shows audit trail message"
    ]
  },
  {
    id: "ui-004",
    title: "Self-Healing Screen",
    area: "screen",
    priority: "P1",
    status: "missing",
    why: "The living system needs a screen showing faults, repairs, resilience, and homeostasis.",
    build: [
      "Create app/self-healing.tsx",
      "Create src/components/SelfHealingPanel.tsx",
      "Show detected fault",
      "Show repair action",
      "Show resilience score",
      "Add dashboard button to /self-healing"
    ],
    acceptance: [
      "Shows health state",
      "Shows repair queue",
      "Shows resilience score"
    ]
  },
  {
    id: "ui-005",
    title: "Device Proof Screen",
    area: "native-proof",
    priority: "P0",
    status: "requires-device-proof",
    why: "Real BLE, QR camera, native Bluetooth, and packet ACK proof cannot be proven by Replit preview.",
    build: [
      "Create app/device-proof.tsx",
      "Create src/components/DeviceProofCard.tsx",
      "Show APK required checklist",
      "Show phone A / phone B status",
      "Show permission readiness",
      "Add dashboard button to /device-proof"
    ],
    acceptance: [
      "Shows APK/device requirements",
      "Does not fake BLE proof",
      "Can display pasted logcat proof later"
    ]
  },
  {
    id: "ui-006",
    title: "Operator Console Screen",
    area: "screen",
    priority: "P1",
    status: "missing",
    why: "You need one command screen for system state, API URL, mode, build status, and completion percentage.",
    build: [
      "Create app/operator-console.tsx",
      "Show UI completion score",
      "Show API base URL",
      "Show current app mode",
      "Show build readiness",
      "Add dashboard button to /operator-console"
    ],
    acceptance: [
      "Shows project mode",
      "Shows completion score",
      "Shows warnings clearly"
    ]
  },
  {
    id: "ui-007",
    title: "MauriCore Status Panel",
    area: "component",
    priority: "P1",
    status: "missing",
    why: "MauriCore needs a compact reusable panel for living memory, governance, BLE runtime, and routing state.",
    build: [
      "Create src/components/MauriCoreStatusPanel.tsx",
      "Use it on Dashboard",
      "Use it on Governance or BLE Runtime screen"
    ],
    acceptance: [
      "Reusable component imports cleanly",
      "Shows core state",
      "Shows no false native claims"
    ]
  },
  {
    id: "ui-008",
    title: "Dashboard Final Button Wiring",
    area: "navigation",
    priority: "P0",
    status: "partial",
    why: "Every completed or planned screen must be reachable from Dashboard or UI Roadmap.",
    build: [
      "Add buttons for /proof-ledger",
      "Add buttons for /route-lab",
      "Add buttons for /tikanga-engine",
      "Add buttons for /self-healing",
      "Add buttons for /device-proof",
      "Add buttons for /operator-console",
      "Add buttons for /ui-roadmap"
    ],
    acceptance: [
      "Every screen opens from dashboard",
      "No dead buttons",
      "No route crash"
    ]
  },
  {
    id: "ui-009",
    title: "Empty State and Error State Design",
    area: "design-system",
    priority: "P2",
    status: "partial",
    why: "All screens need consistent empty/error/loading states so the APK does not look unfinished.",
    build: [
      "Create EmptyState component",
      "Create ErrorState component",
      "Create LoadingState component",
      "Use across Mesh Status, Living Mesh, Proof Ledger, Route Lab"
    ],
    acceptance: [
      "Every async screen has loading state",
      "Every failed API state has safe fallback",
      "No blank screens"
    ]
  },
  {
    id: "ui-010",
    title: "Final Design Polish Layer",
    area: "design-system",
    priority: "P3",
    status: "partial",
    why: "After function is complete, the UI needs premium visual consistency.",
    build: [
      "Standardize page headers",
      "Standardize cards",
      "Standardize spacing",
      "Add status pills to every technical screen",
      "Keep greenstone/emerald design language"
    ],
    acceptance: [
      "All screens feel like one product",
      "No mixed random styles",
      "Readable on Android phone"
    ]
  }
];

export function getUiRemainderSummary() {
  const total = uiRemainderTasks.length;
  const p0 = uiRemainderTasks.filter((t) => t.priority === "P0").length;
  const missing = uiRemainderTasks.filter((t) => t.status === "missing").length;
  const partial = uiRemainderTasks.filter((t) => t.status === "partial").length;
  const deviceProof = uiRemainderTasks.filter((t) => t.status === "requires-device-proof").length;

  return {
    total,
    p0,
    missing,
    partial,
    deviceProof,
    message:
      "This roadmap shows what remains to complete the MauriMesh UI layer before final APK/device proof."
  };
}
TS

cat > "$COMP/UiRoadmapCard.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { UiRemainderTask } from "../lib/uiRemainder";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function UiRoadmapCard({ task }: { task: UiRemainderTask }) {
  const tone =
    task.priority === "P0"
      ? "danger"
      : task.priority === "P1"
        ? "warning"
        : "info";

  return (
    <View style={styles.card}>
      <View style={styles.row}>
        <StatusPill label={task.priority} tone={tone} />
        <StatusPill
          label={task.status.toUpperCase()}
          tone={task.status === "ready" ? "success" : task.status === "requires-device-proof" ? "warning" : "info"}
        />
      </View>

      <Text style={styles.title}>{task.title}</Text>
      <Text style={styles.why}>{task.why}</Text>

      <Text style={styles.heading}>Build</Text>
      {task.build.map((item) => (
        <Text key={item} style={styles.item}>• {item}</Text>
      ))}

      <Text style={styles.heading}>Acceptance</Text>
      {task.acceptance.map((item) => (
        <Text key={item} style={styles.item}>✓ {item}</Text>
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
  row: {
    flexDirection: "row",
    gap: 8,
    flexWrap: "wrap",
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  why: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 14,
    lineHeight: 21,
  },
  heading: {
    color: mauriTheme.colors.greenstone,
    fontSize: 13,
    fontWeight: "900",
    marginTop: 6,
    letterSpacing: 0.8,
  },
  item: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 13,
    lineHeight: 19,
  },
});
TSX

cat > "$APP/ui-roadmap.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { StatusPill } from "../src/components/StatusPill";
import { UiRoadmapCard } from "../src/components/UiRoadmapCard";
import { getUiRemainderSummary, uiRemainderTasks } from "../src/lib/uiRemainder";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function UiRoadmapScreen() {
  const summary = getUiRemainderSummary();

  return (
    <AppShell>
      <StatusPill label="UI REMAINDER BLUEPRINT" tone="info" />
      <Text style={styles.title}>What Is Left To Create</Text>
      <Text style={styles.subtitle}>{summary.message}</Text>

      <View style={styles.summaryCard}>
        <Text style={styles.summaryText}>Total tasks: {summary.total}</Text>
        <Text style={styles.summaryText}>P0 critical: {summary.p0}</Text>
        <Text style={styles.summaryText}>Missing: {summary.missing}</Text>
        <Text style={styles.summaryText}>Partial: {summary.partial}</Text>
        <Text style={styles.summaryText}>Requires APK/device proof: {summary.deviceProof}</Text>
      </View>

      {uiRemainderTasks.map((task) => (
        <UiRoadmapCard key={task.id} task={task} />
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
    fontSize: 15,
    lineHeight: 22,
  },
  summaryCard: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: 6,
  },
  summaryText: {
    color: mauriTheme.colors.white,
    fontSize: 14,
    fontWeight: "800",
  },
});
TSX

cat > "$REPORT" <<MD
# MauriMesh UI Remainder Blueprint

Generated: $STAMP

## Current Scan Score

- Passed checks: $pass
- Missing checks: $missing
- Partial checks: $partial
- Completion score: $SCORE%

## What This Script Created

- \`src/lib/uiRemainder.ts\`
- \`src/components/UiRoadmapCard.tsx\`
- \`app/ui-roadmap.tsx\`
- \`docs/maurimesh-ui-remainder-blueprint-$STAMP.md\`
- \`docs/maurimesh-ui-remainder-tasks-$STAMP.json\`

## Current Project Scan

\`\`\`
$(cat "$SCAN")
\`\`\`

## UI Screens Left To Create Or Finish

### P0 — Critical Before Final UI

1. **Proof Ledger Screen**
   - File: \`app/proof-ledger.tsx\`
   - Component: \`src/components/ProofLedgerPanel.tsx\`
   - Purpose: show packet ID, payload hash, route path, ACK status, timestamp, proof state.
   - Must label: simulation vs device proof.

2. **Route Lab Screen**
   - File: \`app/route-lab.tsx\`
   - Component: \`src/components/RouteDecisionPanel.tsx\`
   - Purpose: show BLE, relay, Wi-Fi, internet fallback, TTL, trust, latency, and selected route.

3. **Tikanga Engine Screen**
   - File: \`app/tikanga-engine.tsx\`
   - Component: \`src/components/TikangaDecisionCard.tsx\`
   - Purpose: show governance result: approved, warning, review, refused.

4. **Device Proof Screen**
   - File: \`app/device-proof.tsx\`
   - Component: \`src/components/DeviceProofCard.tsx\`
   - Purpose: show APK/phone proof checklist and pasted logcat proof later.

5. **Dashboard Final Wiring**
   - Add buttons for:
     - \`/ui-roadmap\`
     - \`/proof-ledger\`
     - \`/route-lab\`
     - \`/tikanga-engine\`
     - \`/self-healing\`
     - \`/device-proof\`
     - \`/operator-console\`

## P1 — Strong Product Layer

1. **Self-Healing Screen**
   - File: \`app/self-healing.tsx\`
   - Shows fault detection, repair queue, resilience score, homeostasis.

2. **Operator Console**
   - File: \`app/operator-console.tsx\`
   - Shows API URL, current mode, UI completion score, build readiness.

3. **MauriCore Status Panel**
   - File: \`src/components/MauriCoreStatusPanel.tsx\`
   - Reusable status card for governance, BLE runtime, routing, living memory.

## P2 — Reliability UI

1. Empty state component.
2. Error state component.
3. Loading state component.
4. Consistent fallback language.
5. No blank screens.

## P3 — Final Polish

1. Standardize page headers.
2. Standardize card layout.
3. Standardize greenstone/emerald color system.
4. Make all technical screens look like one product.
5. Test readability on Android screen.

## Final Truth

The UI can be completed in Replit.

Real BLE, real phone-to-phone delivery, native Bluetooth scanning, QR camera scanning, and real calling transport still require APK/device proof.
MD

cp "$REPORT" "$LATEST"

cat > "$JSON" <<JSON
{
  "project": "MauriMesh Messenger",
  "generated": "$STAMP",
  "completion_score_percent": $SCORE,
  "passed_checks": $pass,
  "missing_checks": $missing,
  "partial_checks": $partial,
  "created_files": [
    "src/lib/uiRemainder.ts",
    "src/components/UiRoadmapCard.tsx",
    "app/ui-roadmap.tsx",
    "docs/maurimesh-ui-remainder-blueprint-$STAMP.md",
    "docs/maurimesh-ui-remainder-tasks-$STAMP.json"
  ],
  "critical_remaining": [
    "Proof Ledger Screen",
    "Route Lab Screen",
    "Tikanga Engine Screen",
    "Device Proof Screen",
    "Dashboard Final Wiring"
  ],
  "strong_product_remaining": [
    "Self-Healing Screen",
    "Operator Console",
    "MauriCore Status Panel"
  ],
  "truth": "Replit can complete UI and simulation/fallback layers. APK/device proof is still required for real BLE, native scanning, QR camera, and real calling."
}
JSON

echo ""
echo "============================================================"
echo "UI REMAINDER DESIGN COMPLETE"
echo "============================================================"
echo "Created:"
echo "  $REPORT"
echo "  $JSON"
echo "  $LATEST"
echo "  src/lib/uiRemainder.ts"
echo "  src/components/UiRoadmapCard.tsx"
echo "  app/ui-roadmap.tsx"
echo ""
echo "Current scan:"
echo "  Passed:  $pass"
echo "  Missing: $missing"
echo "  Partial: $partial"
echo "  Score:   $SCORE%"
echo ""
echo "Next:"
echo "  Open /ui-roadmap in the app after wiring a dashboard button."
echo "  Or paste the next script to auto-wire the dashboard button."
echo "============================================================"
echo ""

rm -f "$SCAN"
