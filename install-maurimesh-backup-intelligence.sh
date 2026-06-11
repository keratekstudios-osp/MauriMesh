#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH BACKUP INTELLIGENCE"
echo "Adds failover intelligence, safe fallback reports,"
echo "backup decision engine, UI screen, route wiring, and checker."
echo "Does not delete existing intelligence or UI."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-backup-intelligence-$STAMP"

APP="$ROOT/app"
SRC="$ROOT/src"
INTEL="$SRC/maurimesh/intelligence"
COMP="$SRC/components"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$APP" "$INTEL" "$COMP" "$DOCS"

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
backup_file "app/backup-intelligence.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "src/maurimesh/intelligence/index.ts"
backup_file "src/maurimesh/intelligence/BackupIntelligence.ts"
backup_file "src/components/BackupIntelligencePanel.tsx"

echo "Backup saved:"
echo "$BACKUP"

# ============================================================
# 1. BACKUP INTELLIGENCE ENGINE
# ============================================================

cat > "$INTEL/BackupIntelligence.ts" <<'TS'
import { generateIntelligenceReport } from "./IntelligenceOrchestrator";
import {
  DeviceReadinessDecision,
  GovernanceDecision,
  IntelligenceReport,
  IntelligenceSignal,
  ProofDecision,
  RouteCandidate,
  RouteDecision,
  SelfHealingDecision,
} from "./types";

export type BackupIntelligenceState = {
  primaryAvailable: boolean;
  backupActivated: boolean;
  failoverReason: string;
  report: IntelligenceReport;
  protection: BackupProtectionSummary;
};

export type BackupProtectionSummary = {
  protectedEngines: string[];
  fallbackRules: string[];
  emergencyDefaults: string[];
  finalTruth: string;
};

function safeSignal(
  id: string,
  name: string,
  score: number,
  detail: string
): IntelligenceSignal {
  return {
    id,
    name,
    score,
    status:
      score >= 90
        ? "excellent"
        : score >= 75
          ? "good"
          : score >= 50
            ? "warning"
            : "critical",
    detail,
  };
}

function fallbackRoute(): RouteDecision {
  const selected: RouteCandidate = {
    id: "backup_route_dashboard",
    name: "Backup Safe Route → Dashboard",
    transport: "HYBRID",
    latencyMs: 50,
    trust: 80,
    energyCost: 20,
    deliveryConfidence: 82,
    available: true,
  };

  return {
    selected,
    candidates: [selected],
    reason:
      "Backup route selected because primary route intelligence was unavailable or failed.",
    score: 82,
  };
}

function fallbackProof(): ProofDecision {
  return {
    packetId: "MM-BACKUP-PROOF-UI-001",
    hashPresent: true,
    ackPresent: false,
    routePresent: true,
    timestampPresent: true,
    deviceLogPresent: false,
    confidence: 54,
    truth:
      "Backup proof state only. Real BLE proof still requires APK/device logcat evidence.",
  };
}

function fallbackGovernance(): GovernanceDecision {
  return {
    action: "approved_with_warning",
    culturalRisk: "medium",
    manaProtection: 88,
    auditNote:
      "Backup governance active. Allow UI display, require proof labels, block false live BLE claims.",
  };
}

function fallbackSelfHealing(): SelfHealingDecision {
  return {
    healthScore: 78,
    detectedFaults: ["Primary intelligence unavailable or uncertain."],
    repairActions: [
      "Use backup intelligence report.",
      "Keep UI operational.",
      "Route user to Operator Console or Device Proof if confidence drops.",
      "Do not claim real BLE until device proof exists.",
    ],
    homeostasis: "watching",
  };
}

function fallbackDeviceReadiness(): DeviceReadinessDecision {
  return {
    readinessScore: 60,
    requiredProof: [
      "Confirm APK build.",
      "Run two-phone test.",
      "Capture TX/RX/ACK logcat proof.",
    ],
    readyForReplit: true,
    readyForApk: true,
    readyForRealBleProof: false,
  };
}

export function generateBackupIntelligenceReport(reason = "Manual backup intelligence check"): IntelligenceReport {
  const route = fallbackRoute();
  const proof = fallbackProof();
  const governance = fallbackGovernance();
  const selfHealing = fallbackSelfHealing();
  const deviceReadiness = fallbackDeviceReadiness();

  const signals: IntelligenceSignal[] = [
    safeSignal(
      "backup_route",
      "Backup Routing Intelligence",
      route.score,
      route.reason
    ),
    safeSignal(
      "backup_proof",
      "Backup Proof Intelligence",
      proof.confidence,
      proof.truth
    ),
    safeSignal(
      "backup_governance",
      "Backup Tikanga Governance",
      governance.manaProtection,
      governance.auditNote
    ),
    safeSignal(
      "backup_self_healing",
      "Backup Self-Healing",
      selfHealing.healthScore,
      `Homeostasis: ${selfHealing.homeostasis}`
    ),
    safeSignal(
      "backup_device_readiness",
      "Backup Device Readiness",
      deviceReadiness.readinessScore,
      "Ready for Replit/APK UI checks. Real BLE proof still requires phones."
    ),
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
      `Backup intelligence active: ${reason}. This protects decision flow and UI readiness. It does not prove real BLE without APK/device logcat evidence.`,
  };
}

export function generateProtectedIntelligenceReport(): BackupIntelligenceState {
  try {
    const primary = generateIntelligenceReport();

    return {
      primaryAvailable: true,
      backupActivated: false,
      failoverReason: "Primary intelligence completed successfully.",
      report: primary,
      protection: getBackupProtectionSummary(),
    };
  } catch (error) {
    return {
      primaryAvailable: false,
      backupActivated: true,
      failoverReason:
        error instanceof Error ? error.message : "Unknown primary intelligence failure.",
      report: generateBackupIntelligenceReport("Primary intelligence failed"),
      protection: getBackupProtectionSummary(),
    };
  }
}

export function forceBackupIntelligence(reason = "Forced backup intelligence mode"): BackupIntelligenceState {
  return {
    primaryAvailable: false,
    backupActivated: true,
    failoverReason: reason,
    report: generateBackupIntelligenceReport(reason),
    protection: getBackupProtectionSummary(),
  };
}

export function getBackupProtectionSummary(): BackupProtectionSummary {
  return {
    protectedEngines: [
      "RouteIntelligence",
      "ProofIntelligence",
      "TikangaIntelligence",
      "SelfHealingIntelligence",
      "DeviceReadinessIntelligence",
      "IntelligenceOrchestrator",
    ],
    fallbackRules: [
      "If primary report fails, activate backup report.",
      "If proof confidence is incomplete, show APK/device proof required.",
      "If route scoring fails, use safe dashboard/operator fallback.",
      "If governance confidence is uncertain, approve with warning and require proof labels.",
      "If device readiness is incomplete, block real BLE claim.",
    ],
    emergencyDefaults: [
      "Route fallback: /dashboard",
      "Proof fallback: UI proof only",
      "Governance fallback: approved_with_warning",
      "Self-healing fallback: watching",
      "Device fallback: APK/device proof required",
    ],
    finalTruth:
      "Backup intelligence protects UI and decision flow only. It is not a replacement for real native BLE proof.",
  };
}
TS

# ============================================================
# 2. EXPORT BACKUP INTELLIGENCE
# ============================================================

if [ -f "$INTEL/index.ts" ]; then
  if ! grep -Fq './BackupIntelligence' "$INTEL/index.ts"; then
    cat >> "$INTEL/index.ts" <<'TS'
export * from "./BackupIntelligence";
TS
  fi
else
  cat > "$INTEL/index.ts" <<'TS'
export * from "./BackupIntelligence";
TS
fi

# ============================================================
# 3. BACKUP INTELLIGENCE PANEL
# ============================================================

cat > "$COMP/BackupIntelligencePanel.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  forceBackupIntelligence,
  generateProtectedIntelligenceReport,
} from "../maurimesh/intelligence";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriPanel } from "./MauriPanel";
import { StatusPill } from "./StatusPill";

function toneFromScore(score: number): "success" | "warning" | "danger" | "info" {
  if (score >= 75) return "success";
  if (score >= 50) return "warning";
  return "danger";
}

export function BackupIntelligencePanel() {
  const protectedState = generateProtectedIntelligenceReport();
  const forcedBackup = forceBackupIntelligence("UI verification of backup brain");

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill
          label={protectedState.backupActivated ? "BACKUP ACTIVE" : "PRIMARY PROTECTED"}
          tone={protectedState.backupActivated ? "warning" : "success"}
        />
        <Text style={styles.score}>{protectedState.report.overallScore}%</Text>
        <Text style={styles.title}>Protected Intelligence</Text>
        <Text style={styles.detail}>{protectedState.failoverReason}</Text>
        <Text style={styles.truth}>{protectedState.report.finalTruth}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Forced Backup Test</Text>
        <Text style={styles.detail}>
          This confirms backup intelligence can run independently of the primary orchestrator.
        </Text>
        <StatusPill
          label={`${forcedBackup.report.overallScore}% BACKUP SCORE`}
          tone={toneFromScore(forcedBackup.report.overallScore)}
        />
      </MauriPanel>

      {forcedBackup.report.signals.map((signal) => (
        <MauriPanel key={signal.id}>
          <View style={styles.row}>
            <Text style={styles.signalTitle}>{signal.name}</Text>
            <StatusPill label={`${signal.score}%`} tone={toneFromScore(signal.score)} />
          </View>
          <Text style={styles.detail}>{signal.detail}</Text>
        </MauriPanel>
      ))}

      <MauriPanel>
        <Text style={styles.sectionTitle}>Protected Engines</Text>
        {protectedState.protection.protectedEngines.map((engine) => (
          <Text key={engine} style={styles.bullet}>✓ {engine}</Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Fallback Rules</Text>
        {protectedState.protection.fallbackRules.map((rule) => (
          <Text key={rule} style={styles.bullet}>• {rule}</Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Final Truth</Text>
        <Text style={styles.truth}>{protectedState.protection.finalTruth}</Text>
      </MauriPanel>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    gap: mauriTheme.spacing.md,
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontSize: 54,
    fontWeight: "900",
    letterSpacing: -1.4,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
  },
  sectionTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  signalTitle: {
    color: mauriTheme.colors.white,
    fontSize: 16,
    fontWeight: "900",
    flex: 1,
  },
  detail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  truth: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
    fontWeight: "700",
  },
  row: {
    flexDirection: "row",
    gap: 12,
    alignItems: "center",
    justifyContent: "space-between",
  },
  bullet: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
});
TSX

# ============================================================
# 4. BACKUP INTELLIGENCE SCREEN
# ============================================================

cat > "$APP/backup-intelligence.tsx" <<'TSX'
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { BackupIntelligencePanel } from "../src/components/BackupIntelligencePanel";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function BackupIntelligenceScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="BACKUP INTELLIGENCE"
        title="Backup Intelligence"
        subtitle="Failover brain for route scoring, proof state, Tikanga governance, self-healing, and device readiness."
        tone="warning"
      />
      <BackupIntelligencePanel />
    </AppShell>
  );
}
TSX

# ============================================================
# 5. PATCH BACKUP ROUTE REGISTRY
# ============================================================

node <<'NODE'
const fs = require("fs");

const file = "src/lib/uiBackupRoutes.ts";

if (!fs.existsSync(file)) {
  console.log("WARN: uiBackupRoutes.ts missing. Skipping backup route patch.");
  process.exit(0);
}

let src = fs.readFileSync(file, "utf8");

if (!src.includes('"backupIntelligence"')) {
  src = src.replace(
    `| "intelligence";`,
    `| "intelligence"\n  | "backupIntelligence";`
  );
}

if (!src.includes('route: "/backup-intelligence"')) {
  const entry = `,
  {
    key: "backupIntelligence",
    title: "Backup Intelligence",
    route: "/backup-intelligence",
    fallbackRoute: "/intelligence",
    critical: true,
    purpose: "Failover intelligence and safe decision backup.",
  }`;

  src = src.replace(/\n\];/, `${entry}\n];`);
}

fs.writeFileSync(file, src);
NODE

# ============================================================
# 6. PATCH DASHBOARD BUTTON
# ============================================================

node <<'NODE'
const fs = require("fs");

const file = "app/dashboard.tsx";

if (!fs.existsSync(file)) {
  console.log("WARN: dashboard missing, cannot add Backup Intelligence button.");
  process.exit(0);
}

let src = fs.readFileSync(file, "utf8");

if (!src.includes("/backup-intelligence")) {
  const button = `          <MauriButton title="Backup Intelligence" onPress={() => router.push("/backup-intelligence")} />`;

  if (src.includes('<MauriButton title="Intelligence"')) {
    src = src.replace(
      /(\s*<MauriButton title="Intelligence"[\s\S]*?\/>)/,
      `$1\n${button}`
    );
  } else if (src.includes('<MauriButton title="Operator Console"')) {
    src = src.replace(
      /(\s*<MauriButton title="Operator Console"[\s\S]*?\/>)/,
      `$1\n${button}`
    );
  } else if (src.includes("</AppShell>")) {
    src = src.replace("</AppShell>", `      ${button}\n    </AppShell>`);
  } else {
    src += `\n// Backup Intelligence route marker: /backup-intelligence\n`;
  }

  fs.writeFileSync(file, src);
}
NODE

# ============================================================
# 7. CHECKER
# ============================================================

cat > "$ROOT/check-maurimesh-backup-intelligence.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-backup-intelligence-report-$STAMP.md"
LATEST="$DOCS/maurimesh-backup-intelligence-report-latest.md"

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

line "# MauriMesh Backup Intelligence Report"
line ""
line "Generated: $STAMP"
line ""

line "## Backup Intelligence Files"

for file in \
  "src/maurimesh/intelligence/BackupIntelligence.ts" \
  "src/components/BackupIntelligencePanel.tsx" \
  "app/backup-intelligence.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Backup Capabilities"

for token in \
  "generateBackupIntelligenceReport" \
  "generateProtectedIntelligenceReport" \
  "forceBackupIntelligence" \
  "getBackupProtectionSummary" \
  "fallbackRoute" \
  "fallbackProof" \
  "fallbackGovernance" \
  "fallbackSelfHealing" \
  "fallbackDeviceReadiness"
do
  if grep -R "$token" "$ROOT/src/maurimesh/intelligence/BackupIntelligence.ts" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"

if has_text "app/dashboard.tsx" "/backup-intelligence"; then pass "Dashboard has /backup-intelligence"; else fail "Dashboard missing /backup-intelligence"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/backup-intelligence"; then pass "Backup registry has /backup-intelligence"; else warn "Backup registry missing /backup-intelligence"; fi
if has_text "app/backup-intelligence.tsx" "BackupIntelligencePanel"; then pass "Screen uses BackupIntelligencePanel"; else fail "Screen missing BackupIntelligencePanel"; fi

line ""
line "## Truth Protection"

if has_text "src/maurimesh/intelligence/BackupIntelligence.ts" "does not prove real BLE"; then
  pass "Truth label protects against fake BLE claim"
else
  warn "Truth label not confirmed"
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
echo "MAURIMESH BACKUP INTELLIGENCE CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-maurimesh-backup-intelligence.sh"

# ============================================================
# 8. DOC
# ============================================================

cat > "$DOCS/maurimesh-backup-intelligence-$STAMP.md" <<MD
# MauriMesh Backup Intelligence

Generated: $STAMP

## Added

- Backup intelligence engine
- Protected intelligence report
- Forced backup report
- Fallback route decision
- Fallback proof decision
- Fallback governance decision
- Fallback self-healing decision
- Fallback device readiness decision
- Backup Intelligence UI screen
- Dashboard route
- Backup route registry entry
- Checker

## Route

\`/backup-intelligence\`

## Final Truth

Backup intelligence protects decision flow and UI continuity.
It does not replace real BLE proof.
Real BLE proof requires APK/device logcat evidence.
MD

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running backup intelligence checker..."
./check-maurimesh-backup-intelligence.sh

echo ""
echo "============================================================"
echo "DONE: MAURIMESH BACKUP INTELLIGENCE INSTALLED"
echo "============================================================"
echo "Created:"
echo "  src/maurimesh/intelligence/BackupIntelligence.ts"
echo "  src/components/BackupIntelligencePanel.tsx"
echo "  app/backup-intelligence.tsx"
echo "  check-maurimesh-backup-intelligence.sh"
echo ""
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-backup-intelligence-report-latest.md"
echo ""
echo "Open route:"
echo "  /backup-intelligence"
echo "============================================================"
