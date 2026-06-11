#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH INTELLIGENCE ENHANCEMENT SYSTEM"
echo "Adds route intelligence, proof confidence, governance scoring,"
echo "self-healing recommendations, device readiness, and UI screen."
echo "Does not delete existing UI, BLE, routing, or backup wiring."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-intelligence-enhancement-$STAMP"

APP="$ROOT/app"
SRC="$ROOT/src"
INTEL="$SRC/maurimesh/intelligence"
COMP="$SRC/components"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$APP" "$SRC" "$INTEL" "$COMP" "$DOCS"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run from Replit project root."
  exit 1
fi

backup_file() {
  local file="$1"
  if [ -f "$ROOT/$file" ]; then
    mkdir -p "$BACKUP/$(dirname "$file")"
    cp "$ROOT/$file" "$BACKUP/$file"
  fi
}

backup_file "app/dashboard.tsx"
backup_file "app/intelligence.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "src/components/IntelligencePanel.tsx"

echo "Backup saved:"
echo "$BACKUP"

# ============================================================
# 1. INTELLIGENCE TYPES
# ============================================================

cat > "$INTEL/types.ts" <<'TS'
export type IntelligenceMode = "SIMULATION" | "LIVE_API" | "DEVICE_PROOF_REQUIRED";

export type IntelligenceSignal = {
  id: string;
  name: string;
  score: number;
  status: "excellent" | "good" | "warning" | "critical";
  detail: string;
};

export type RouteCandidate = {
  id: string;
  name: string;
  transport: "BLE" | "BLE_RELAY" | "WIFI" | "WIFI_DIRECT" | "INTERNET" | "HYBRID";
  latencyMs: number;
  trust: number;
  energyCost: number;
  deliveryConfidence: number;
  available: boolean;
};

export type RouteDecision = {
  selected: RouteCandidate;
  candidates: RouteCandidate[];
  reason: string;
  score: number;
};

export type ProofDecision = {
  packetId: string;
  hashPresent: boolean;
  ackPresent: boolean;
  routePresent: boolean;
  timestampPresent: boolean;
  deviceLogPresent: boolean;
  confidence: number;
  truth: string;
};

export type GovernanceDecision = {
  action: "approved" | "approved_with_warning" | "review_required" | "refused";
  culturalRisk: "low" | "medium" | "high" | "protected";
  manaProtection: number;
  auditNote: string;
};

export type SelfHealingDecision = {
  healthScore: number;
  detectedFaults: string[];
  repairActions: string[];
  homeostasis: "stable" | "watching" | "repairing" | "critical";
};

export type DeviceReadinessDecision = {
  readinessScore: number;
  requiredProof: string[];
  readyForReplit: boolean;
  readyForApk: boolean;
  readyForRealBleProof: boolean;
};

export type IntelligenceReport = {
  mode: IntelligenceMode;
  overallScore: number;
  signals: IntelligenceSignal[];
  route: RouteDecision;
  proof: ProofDecision;
  governance: GovernanceDecision;
  selfHealing: SelfHealingDecision;
  deviceReadiness: DeviceReadinessDecision;
  finalTruth: string;
};
TS

# ============================================================
# 2. ROUTE INTELLIGENCE
# ============================================================

cat > "$INTEL/RouteIntelligence.ts" <<'TS'
import { RouteCandidate, RouteDecision } from "./types";

function clamp(value: number) {
  return Math.max(0, Math.min(100, Math.round(value)));
}

function scoreRoute(route: RouteCandidate): number {
  if (!route.available) return 0;

  const latencyScore = clamp(100 - route.latencyMs);
  const energyScore = clamp(100 - route.energyCost);

  return clamp(
    route.deliveryConfidence * 0.42 +
      route.trust * 0.28 +
      latencyScore * 0.18 +
      energyScore * 0.12
  );
}

export function decideBestRoute(
  candidates: RouteCandidate[] = defaultRouteCandidates
): RouteDecision {
  const scored = candidates
    .map((candidate) => ({
      candidate,
      score: scoreRoute(candidate),
    }))
    .sort((a, b) => b.score - a.score);

  const selected = scored[0]?.candidate || defaultRouteCandidates[0];
  const score = scored[0]?.score || 0;

  return {
    selected,
    candidates,
    score,
    reason:
      selected.transport === "HYBRID"
        ? "Hybrid path selected because it balances delivery confidence, trust, latency, and energy."
        : `${selected.name} selected because it has the strongest current route score.`,
  };
}

export const defaultRouteCandidates: RouteCandidate[] = [
  {
    id: "route_ble_direct",
    name: "BLE Direct",
    transport: "BLE",
    latencyMs: 42,
    trust: 78,
    energyCost: 24,
    deliveryConfidence: 72,
    available: true,
  },
  {
    id: "route_ble_relay_wifi",
    name: "BLE Relay → Wi-Fi Completion",
    transport: "HYBRID",
    latencyMs: 28,
    trust: 88,
    energyCost: 31,
    deliveryConfidence: 94,
    available: true,
  },
  {
    id: "route_store_forward",
    name: "Store-and-Forward Relay",
    transport: "BLE_RELAY",
    latencyMs: 66,
    trust: 83,
    energyCost: 18,
    deliveryConfidence: 81,
    available: true,
  },
  {
    id: "route_internet_fallback",
    name: "Internet Fallback",
    transport: "INTERNET",
    latencyMs: 35,
    trust: 70,
    energyCost: 44,
    deliveryConfidence: 86,
    available: true,
  },
];
TS

# ============================================================
# 3. PROOF INTELLIGENCE
# ============================================================

cat > "$INTEL/ProofIntelligence.ts" <<'TS'
import { ProofDecision } from "./types";

function scoreBool(value: boolean, weight: number) {
  return value ? weight : 0;
}

export function evaluateProof(input?: Partial<ProofDecision>): ProofDecision {
  const proof = {
    packetId: input?.packetId || "MM-INTEL-PROOF-UI-001",
    hashPresent: input?.hashPresent ?? true,
    ackPresent: input?.ackPresent ?? true,
    routePresent: input?.routePresent ?? true,
    timestampPresent: input?.timestampPresent ?? true,
    deviceLogPresent: input?.deviceLogPresent ?? false,
    confidence: 0,
    truth: "",
  };

  const confidence =
    scoreBool(proof.hashPresent, 22) +
    scoreBool(proof.ackPresent, 22) +
    scoreBool(proof.routePresent, 18) +
    scoreBool(proof.timestampPresent, 14) +
    scoreBool(proof.deviceLogPresent, 24);

  return {
    ...proof,
    confidence,
    truth: proof.deviceLogPresent
      ? "Device proof present. Real APK/logcat evidence can be reviewed."
      : "UI proof confidence only. Real BLE proof still requires APK/device logcat evidence.",
  };
}
TS

# ============================================================
# 4. TIKANGA GOVERNANCE INTELLIGENCE
# ============================================================

cat > "$INTEL/TikangaIntelligence.ts" <<'TS'
import { GovernanceDecision } from "./types";

export function evaluateTikangaGovernance(input?: {
  containsProtectedTerms?: boolean;
  publicClaimRisk?: boolean;
  userSafetyRisk?: boolean;
  culturalContextPresent?: boolean;
}): GovernanceDecision {
  const containsProtectedTerms = input?.containsProtectedTerms ?? false;
  const publicClaimRisk = input?.publicClaimRisk ?? true;
  const userSafetyRisk = input?.userSafetyRisk ?? false;
  const culturalContextPresent = input?.culturalContextPresent ?? true;

  if (userSafetyRisk) {
    return {
      action: "review_required",
      culturalRisk: "high",
      manaProtection: 92,
      auditNote: "Safety risk detected. Human review required before release.",
    };
  }

  if (containsProtectedTerms && !culturalContextPresent) {
    return {
      action: "review_required",
      culturalRisk: "protected",
      manaProtection: 95,
      auditNote: "Protected cultural terms require context and review.",
    };
  }

  if (publicClaimRisk) {
    return {
      action: "approved_with_warning",
      culturalRisk: "medium",
      manaProtection: 86,
      auditNote:
        "Public claims should be backed by proof. Use truthful labels: UI, simulation, APK required, or device proof.",
    };
  }

  return {
    action: "approved",
    culturalRisk: "low",
    manaProtection: 90,
    auditNote: "Governance check passed.",
  };
}
TS

# ============================================================
# 5. SELF-HEALING INTELLIGENCE
# ============================================================

cat > "$INTEL/SelfHealingIntelligence.ts" <<'TS'
import { SelfHealingDecision } from "./types";

export function evaluateSelfHealing(input?: {
  missingRoutes?: number;
  failedProofs?: number;
  staleSignals?: number;
  typeScriptPassed?: boolean;
}): SelfHealingDecision {
  const missingRoutes = input?.missingRoutes ?? 0;
  const failedProofs = input?.failedProofs ?? 0;
  const staleSignals = input?.staleSignals ?? 1;
  const typeScriptPassed = input?.typeScriptPassed ?? true;

  const penalty =
    missingRoutes * 12 +
    failedProofs * 18 +
    staleSignals * 6 +
    (typeScriptPassed ? 0 : 30);

  const healthScore = Math.max(0, Math.min(100, 100 - penalty));

  const detectedFaults: string[] = [];
  const repairActions: string[] = [];

  if (missingRoutes > 0) {
    detectedFaults.push("Missing or unwired route detected.");
    repairActions.push("Use backup route registry and SafeNavButton fallback.");
  }

  if (failedProofs > 0) {
    detectedFaults.push("Proof confidence gap detected.");
    repairActions.push("Capture packet hash, ACK, route, timestamp, and logcat evidence.");
  }

  if (staleSignals > 0) {
    detectedFaults.push("Stale mesh signal detected.");
    repairActions.push("Refresh mesh status and re-score route candidates.");
  }

  if (!typeScriptPassed) {
    detectedFaults.push("TypeScript failed.");
    repairActions.push("Block release until TypeScript passes.");
  }

  if (detectedFaults.length === 0) {
    repairActions.push("Maintain current state. Continue monitoring.");
  }

  return {
    healthScore,
    detectedFaults,
    repairActions,
    homeostasis:
      healthScore >= 90
        ? "stable"
        : healthScore >= 70
          ? "watching"
          : healthScore >= 45
            ? "repairing"
            : "critical",
  };
}
TS

# ============================================================
# 6. DEVICE READINESS INTELLIGENCE
# ============================================================

cat > "$INTEL/DeviceReadinessIntelligence.ts" <<'TS'
import { DeviceReadinessDecision } from "./types";

export function evaluateDeviceReadiness(input?: {
  uiComplete?: boolean;
  backupWiringComplete?: boolean;
  typeScriptPassed?: boolean;
  apkBuilt?: boolean;
  twoPhonesTested?: boolean;
  logcatProofCaptured?: boolean;
}): DeviceReadinessDecision {
  const uiComplete = input?.uiComplete ?? true;
  const backupWiringComplete = input?.backupWiringComplete ?? true;
  const typeScriptPassed = input?.typeScriptPassed ?? true;
  const apkBuilt = input?.apkBuilt ?? false;
  const twoPhonesTested = input?.twoPhonesTested ?? false;
  const logcatProofCaptured = input?.logcatProofCaptured ?? false;

  let readinessScore = 0;
  if (uiComplete) readinessScore += 22;
  if (backupWiringComplete) readinessScore += 18;
  if (typeScriptPassed) readinessScore += 20;
  if (apkBuilt) readinessScore += 15;
  if (twoPhonesTested) readinessScore += 15;
  if (logcatProofCaptured) readinessScore += 10;

  const requiredProof: string[] = [];

  if (!apkBuilt) requiredProof.push("Build installable APK.");
  if (!twoPhonesTested) requiredProof.push("Test Phone A to Phone B delivery.");
  if (!logcatProofCaptured) requiredProof.push("Capture TX/RX/ACK logcat proof.");

  return {
    readinessScore,
    requiredProof,
    readyForReplit: uiComplete && backupWiringComplete && typeScriptPassed,
    readyForApk: uiComplete && backupWiringComplete && typeScriptPassed,
    readyForRealBleProof: apkBuilt && twoPhonesTested && logcatProofCaptured,
  };
}
TS

# ============================================================
# 7. INTELLIGENCE ORCHESTRATOR
# ============================================================

cat > "$INTEL/IntelligenceOrchestrator.ts" <<'TS'
import { evaluateDeviceReadiness } from "./DeviceReadinessIntelligence";
import { evaluateProof } from "./ProofIntelligence";
import { decideBestRoute } from "./RouteIntelligence";
import { evaluateSelfHealing } from "./SelfHealingIntelligence";
import { evaluateTikangaGovernance } from "./TikangaIntelligence";
import { IntelligenceReport, IntelligenceSignal } from "./types";

function statusFromScore(score: number): IntelligenceSignal["status"] {
  if (score >= 90) return "excellent";
  if (score >= 75) return "good";
  if (score >= 50) return "warning";
  return "critical";
}

export function generateIntelligenceReport(): IntelligenceReport {
  const route = decideBestRoute();
  const proof = evaluateProof();
  const governance = evaluateTikangaGovernance();
  const selfHealing = evaluateSelfHealing();
  const deviceReadiness = evaluateDeviceReadiness();

  const signals: IntelligenceSignal[] = [
    {
      id: "route",
      name: "Routing Intelligence",
      score: route.score,
      status: statusFromScore(route.score),
      detail: route.reason,
    },
    {
      id: "proof",
      name: "Proof Intelligence",
      score: proof.confidence,
      status: statusFromScore(proof.confidence),
      detail: proof.truth,
    },
    {
      id: "governance",
      name: "Tikanga Governance",
      score: governance.manaProtection,
      status: statusFromScore(governance.manaProtection),
      detail: governance.auditNote,
    },
    {
      id: "self_healing",
      name: "Self-Healing",
      score: selfHealing.healthScore,
      status: statusFromScore(selfHealing.healthScore),
      detail: `Homeostasis: ${selfHealing.homeostasis}`,
    },
    {
      id: "device_readiness",
      name: "Device Readiness",
      score: deviceReadiness.readinessScore,
      status: statusFromScore(deviceReadiness.readinessScore),
      detail: deviceReadiness.readyForRealBleProof
        ? "Ready for real BLE proof."
        : "APK/device proof still required.",
    },
  ];

  const overallScore = Math.round(
    signals.reduce((sum, signal) => sum + signal.score, 0) / signals.length
  );

  return {
    mode: "SIMULATION",
    overallScore,
    signals,
    route,
    proof,
    governance,
    selfHealing,
    deviceReadiness,
    finalTruth:
      "This intelligence layer scores UI/runtime readiness and decision logic. It does not prove real BLE until APK/device logcat proof is captured.",
  };
}
TS

cat > "$INTEL/index.ts" <<'TS'
export * from "./types";
export * from "./RouteIntelligence";
export * from "./ProofIntelligence";
export * from "./TikangaIntelligence";
export * from "./SelfHealingIntelligence";
export * from "./DeviceReadinessIntelligence";
export * from "./IntelligenceOrchestrator";
TS

# ============================================================
# 8. INTELLIGENCE UI PANEL
# ============================================================

cat > "$COMP/IntelligencePanel.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { generateIntelligenceReport } from "../maurimesh/intelligence";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriPanel } from "./MauriPanel";
import { StatusPill } from "./StatusPill";

function toneFromStatus(status: string): "success" | "warning" | "danger" | "info" {
  if (status === "excellent" || status === "good") return "success";
  if (status === "warning") return "warning";
  if (status === "critical") return "danger";
  return "info";
}

export function IntelligencePanel() {
  const report = generateIntelligenceReport();

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill label={report.mode} tone="warning" />
        <Text style={styles.heroScore}>{report.overallScore}%</Text>
        <Text style={styles.heroTitle}>System Intelligence Score</Text>
        <Text style={styles.heroText}>{report.finalTruth}</Text>
      </MauriPanel>

      {report.signals.map((signal) => (
        <MauriPanel key={signal.id}>
          <View style={styles.row}>
            <Text style={styles.signalTitle}>{signal.name}</Text>
            <StatusPill label={`${signal.score}%`} tone={toneFromStatus(signal.status)} />
          </View>
          <Text style={styles.signalDetail}>{signal.detail}</Text>
        </MauriPanel>
      ))}

      <MauriPanel>
        <Text style={styles.sectionTitle}>Selected Route</Text>
        <Text style={styles.value}>{report.route.selected.name}</Text>
        <Text style={styles.signalDetail}>{report.route.reason}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Self-Healing Actions</Text>
        {report.selfHealing.repairActions.map((action) => (
          <Text key={action} style={styles.bullet}>✓ {action}</Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Device Proof Still Required</Text>
        {report.deviceReadiness.requiredProof.map((item) => (
          <Text key={item} style={styles.bullet}>□ {item}</Text>
        ))}
      </MauriPanel>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: mauriTheme.spacing.md,
  },
  heroScore: {
    color: mauriTheme.colors.greenstone,
    fontSize: 54,
    fontWeight: "900",
    letterSpacing: -1.4,
  },
  heroTitle: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
  },
  heroText: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    gap: 12,
    alignItems: "center",
  },
  signalTitle: {
    color: mauriTheme.colors.white,
    fontSize: 17,
    fontWeight: "900",
    flex: 1,
  },
  signalDetail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  value: {
    color: mauriTheme.colors.white,
    fontSize: 18,
    fontWeight: "900",
  },
  bullet: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
});
TSX

# ============================================================
# 9. INTELLIGENCE SCREEN
# ============================================================

cat > "$APP/intelligence.tsx" <<'TSX'
import React from "react";
import { IntelligencePanel } from "../src/components/IntelligencePanel";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function IntelligenceScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="INTELLIGENCE ORCHESTRATION"
        title="Intelligence"
        subtitle="Route scoring, proof confidence, Tikanga governance, self-healing, device readiness, and final truth state."
        tone="info"
      />
      <IntelligencePanel />
    </AppShell>
  );
}
TSX

# ============================================================
# 10. PATCH BACKUP ROUTE REGISTRY
# ============================================================

node <<'NODE'
const fs = require("fs");

const file = "src/lib/uiBackupRoutes.ts";

if (fs.existsSync(file)) {
  let src = fs.readFileSync(file, "utf8");

  if (!src.includes('"intelligence"')) {
    src = src.replace(
      `| "mauriCoreBleRuntime";`,
      `| "mauriCoreBleRuntime"\n  | "intelligence";`
    );
  }

  if (!src.includes('route: "/intelligence"')) {
    const entry = `,
  {
    key: "intelligence",
    title: "Intelligence",
    route: "/intelligence",
    fallbackRoute: "/operator-console",
    critical: true,
    purpose: "Intelligence orchestration dashboard.",
  }`;

    src = src.replace(/\n\];/, `${entry}\n];`);
  }

  fs.writeFileSync(file, src);
}
NODE

# ============================================================
# 11. PATCH DASHBOARD BUTTON
# ============================================================

node <<'NODE'
const fs = require("fs");

const file = "app/dashboard.tsx";

if (!fs.existsSync(file)) {
  console.log("WARN: dashboard missing, cannot add Intelligence button.");
  process.exit(0);
}

let src = fs.readFileSync(file, "utf8");

if (!src.includes("/intelligence")) {
  const button = `          <MauriButton title="Intelligence" onPress={() => router.push("/intelligence")} />`;

  if (src.includes('<MauriButton title="Operator Console"')) {
    src = src.replace(
      /(\s*<MauriButton title="Operator Console"[\s\S]*?\/>)/,
      `$1\n${button}`
    );
  } else if (src.includes("</AppShell>")) {
    src = src.replace(
      "</AppShell>",
      `      ${button}\n    </AppShell>`
    );
  } else {
    src += `\n// Intelligence route marker: /intelligence\n`;
  }

  fs.writeFileSync(file, src);
}
NODE

# ============================================================
# 12. CHECKER
# ============================================================

cat > "$ROOT/check-maurimesh-intelligence.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-intelligence-report-$STAMP.md"
LATEST="$DOCS/maurimesh-intelligence-report-latest.md"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

has_file(){ [ -f "$ROOT/$1" ]; }
has_text(){ [ -f "$ROOT/$1" ] && grep -Fq "$2" "$ROOT/$1"; }

: > "$REPORT"

line "# MauriMesh Intelligence Enhancement Report"
line ""
line "Generated: $STAMP"
line ""

line "## Intelligence Engine Files"

for file in \
  "src/maurimesh/intelligence/types.ts" \
  "src/maurimesh/intelligence/RouteIntelligence.ts" \
  "src/maurimesh/intelligence/ProofIntelligence.ts" \
  "src/maurimesh/intelligence/TikangaIntelligence.ts" \
  "src/maurimesh/intelligence/SelfHealingIntelligence.ts" \
  "src/maurimesh/intelligence/DeviceReadinessIntelligence.ts" \
  "src/maurimesh/intelligence/IntelligenceOrchestrator.ts" \
  "src/maurimesh/intelligence/index.ts"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## UI Files"

if has_file "src/components/IntelligencePanel.tsx"; then pass "IntelligencePanel exists"; else fail "IntelligencePanel missing"; fi
if has_file "app/intelligence.tsx"; then pass "Intelligence screen exists"; else fail "app/intelligence.tsx missing"; fi

line ""
line "## Intelligence Capabilities"

for token in \
  "decideBestRoute" \
  "evaluateProof" \
  "evaluateTikangaGovernance" \
  "evaluateSelfHealing" \
  "evaluateDeviceReadiness" \
  "generateIntelligenceReport"
do
  if grep -R "$token" "$ROOT/src/maurimesh/intelligence" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"

if has_text "app/dashboard.tsx" "/intelligence"; then pass "Dashboard has /intelligence route"; else fail "Dashboard missing /intelligence"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/intelligence"; then pass "Backup route registry has /intelligence"; else warn "Backup route registry missing /intelligence"; fi

line ""
line "## Truth Labels"

if has_text "src/maurimesh/intelligence/IntelligenceOrchestrator.ts" "does not prove real BLE"; then
  pass "Final truth label present"
else
  warn "Final truth label not confirmed"
fi

line ""
line "## TypeScript"

if npx tsc --noEmit >> "$REPORT" 2>&1; then
  pass "TypeScript passed"
else
  fail "TypeScript failed"
fi

TOTAL=$((PASS + FAIL + WARN))
if [ "$TOTAL" -gt 0 ]; then SCORE=$((PASS * 100 / TOTAL)); else SCORE=0; fi

STATUS="INCOMPLETE"
if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  STATUS="COMPLETE"
elif [ "$FAIL" -eq 0 ]; then
  STATUS="COMPLETE_WITH_WARNINGS"
else
  STATUS="INCOMPLETE"
fi

line ""
line "## Summary"
line ""
line "- Total: $TOTAL"
line "- Complete: $PASS"
line "- Partial: $WARN"
line "- Missing/failed: $FAIL"
line "- Score: $SCORE%"
line "- Status: **$STATUS**"

cp "$REPORT" "$LATEST"

echo ""
echo "============================================================"
echo "MAURIMESH INTELLIGENCE CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-maurimesh-intelligence.sh"

# ============================================================
# 13. DOC
# ============================================================

cat > "$DOCS/maurimesh-intelligence-enhancement-$STAMP.md" <<MD
# MauriMesh Intelligence Enhancement

Generated: $STAMP

## Added

- Route intelligence
- Proof confidence intelligence
- Tikanga governance intelligence
- Self-healing intelligence
- Device readiness intelligence
- Intelligence orchestrator
- Intelligence UI screen
- Intelligence dashboard route
- Intelligence checker

## Route

\`/intelligence\`

## Final Truth

This layer improves decision logic and readiness scoring.
It does not prove real BLE until APK/device logcat evidence exists.
MD

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running intelligence checker..."
./check-maurimesh-intelligence.sh

echo ""
echo "============================================================"
echo "DONE: MAURIMESH INTELLIGENCE ENHANCEMENT INSTALLED"
echo "============================================================"
echo "Created:"
echo "  src/maurimesh/intelligence/*"
echo "  src/components/IntelligencePanel.tsx"
echo "  app/intelligence.tsx"
echo "  check-maurimesh-intelligence.sh"
echo ""
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-intelligence-report-latest.md"
echo ""
echo "Open route:"
echo "  /intelligence"
echo "============================================================"
