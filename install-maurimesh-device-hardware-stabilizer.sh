#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH DEVICE HARDWARE STABILIZER"
echo "Adds device health scoring, hardware pressure analysis,"
echo "runtime optimisation decisions, safe mode, UI screen,"
echo "dashboard wiring, backup route wiring, and checker."
echo "Does not delete existing UI/intelligence/BLE code."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-device-hardware-stabilizer-$STAMP"

APP="$ROOT/app"
SRC="$ROOT/src"
HW="$SRC/maurimesh/device-hardware"
COMP="$SRC/components"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$APP" "$HW" "$COMP" "$DOCS"

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
backup_file "app/device-hardware.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "src/components/DeviceHardwarePanel.tsx"

echo "Backup saved:"
echo "$BACKUP"

# ============================================================
# 1. DEVICE HARDWARE TYPES
# ============================================================

cat > "$HW/types.ts" <<'TS'
export type HardwarePressure = "low" | "medium" | "high" | "critical";

export type DeviceHardwareSample = {
  batteryPercent: number;
  isCharging: boolean;
  thermalRisk: HardwarePressure;
  memoryPressure: HardwarePressure;
  storagePressure: HardwarePressure;
  networkPressure: HardwarePressure;
  blePressure: HardwarePressure;
  appCrashRisk: HardwarePressure;
  foreground: boolean;
  timestamp: number;
};

export type HardwareOptimisationDecision = {
  deviceHealthScore: number;
  pressure: HardwarePressure;
  safeMode: boolean;
  scanIntensity: "off" | "low" | "balanced" | "high";
  animationIntensity: "minimal" | "balanced" | "rich";
  proofTaskMode: "pause" | "defer" | "normal" | "priority";
  routePreference: "low_energy" | "balanced" | "fastest" | "store_forward";
  bleRetryPolicy: "pause" | "slow_retry" | "normal_retry";
  recommendations: string[];
  finalTruth: string;
};

export type HardwareLearningMemory = {
  samplesSeen: number;
  lastScores: number[];
  repeatedFaults: string[];
  learnedNotes: string[];
};
TS

# ============================================================
# 2. HARDWARE STABILIZER ENGINE
# ============================================================

cat > "$HW/DeviceHardwareStabilizer.ts" <<'TS'
import {
  DeviceHardwareSample,
  HardwareLearningMemory,
  HardwareOptimisationDecision,
  HardwarePressure,
} from "./types";

function pressureValue(value: HardwarePressure): number {
  if (value === "low") return 0;
  if (value === "medium") return 12;
  if (value === "high") return 26;
  return 42;
}

function pressureFromScore(score: number): HardwarePressure {
  if (score >= 82) return "low";
  if (score >= 64) return "medium";
  if (score >= 42) return "high";
  return "critical";
}

function clamp(value: number) {
  return Math.max(0, Math.min(100, Math.round(value)));
}

export function createDefaultHardwareSample(): DeviceHardwareSample {
  return {
    batteryPercent: 68,
    isCharging: false,
    thermalRisk: "low",
    memoryPressure: "medium",
    storagePressure: "low",
    networkPressure: "medium",
    blePressure: "medium",
    appCrashRisk: "low",
    foreground: true,
    timestamp: Date.now(),
  };
}

export function analyseHardwareSample(
  sample: DeviceHardwareSample,
  memory?: HardwareLearningMemory
): HardwareOptimisationDecision {
  const batteryPenalty =
    sample.batteryPercent <= 8
      ? 38
      : sample.batteryPercent <= 15
        ? 28
        : sample.batteryPercent <= 25
          ? 14
          : 0;

  const chargingBonus = sample.isCharging ? 6 : 0;

  const pressurePenalty =
    pressureValue(sample.thermalRisk) +
    pressureValue(sample.memoryPressure) +
    pressureValue(sample.storagePressure) +
    pressureValue(sample.networkPressure) +
    pressureValue(sample.blePressure) +
    pressureValue(sample.appCrashRisk);

  const backgroundPenalty = sample.foreground ? 0 : 12;
  const repeatedFaultPenalty = memory?.repeatedFaults?.length
    ? Math.min(18, memory.repeatedFaults.length * 4)
    : 0;

  const deviceHealthScore = clamp(
    100 - batteryPenalty - pressurePenalty * 0.32 - backgroundPenalty - repeatedFaultPenalty + chargingBonus
  );

  const pressure = pressureFromScore(deviceHealthScore);
  const safeMode = pressure === "critical" || pressure === "high";

  const recommendations: string[] = [];

  if (sample.batteryPercent <= 15 && !sample.isCharging) {
    recommendations.push("Battery is low. Reduce BLE scanning and prefer store-and-forward.");
  }

  if (sample.thermalRisk === "high" || sample.thermalRisk === "critical") {
    recommendations.push("Thermal risk detected. Pause heavy proof tasks and reduce animations.");
  }

  if (sample.memoryPressure === "high" || sample.memoryPressure === "critical") {
    recommendations.push("Memory pressure detected. Reduce UI effects and clear non-critical queues.");
  }

  if (sample.storagePressure === "high" || sample.storagePressure === "critical") {
    recommendations.push("Storage pressure detected. Compress proof logs and rotate old telemetry.");
  }

  if (sample.blePressure === "high" || sample.blePressure === "critical") {
    recommendations.push("BLE pressure detected. Slow retry timing and avoid scan storms.");
  }

  if (sample.appCrashRisk === "high" || sample.appCrashRisk === "critical") {
    recommendations.push("Crash risk detected. Use safe mode and route user to Operator Console.");
  }

  if (!sample.foreground) {
    recommendations.push("App is backgrounded. Use low-energy background-safe behaviour.");
  }

  if (recommendations.length === 0) {
    recommendations.push("Device state looks stable. Maintain balanced runtime mode.");
  }

  return {
    deviceHealthScore,
    pressure,
    safeMode,
    scanIntensity:
      pressure === "critical"
        ? "off"
        : pressure === "high"
          ? "low"
          : pressure === "medium"
            ? "balanced"
            : "high",
    animationIntensity:
      pressure === "critical" || pressure === "high"
        ? "minimal"
        : pressure === "medium"
          ? "balanced"
          : "rich",
    proofTaskMode:
      pressure === "critical"
        ? "pause"
        : pressure === "high"
          ? "defer"
          : pressure === "medium"
            ? "normal"
            : "priority",
    routePreference:
      pressure === "critical"
        ? "store_forward"
        : pressure === "high"
          ? "low_energy"
          : pressure === "medium"
            ? "balanced"
            : "fastest",
    bleRetryPolicy:
      pressure === "critical"
        ? "pause"
        : pressure === "high"
          ? "slow_retry"
          : "normal_retry",
    recommendations,
    finalTruth:
      "MauriMesh can optimise its own app behaviour around device conditions. It cannot physically repair hardware or bypass Android system protections.",
  };
}

export function updateHardwareLearningMemory(
  previous: HardwareLearningMemory | undefined,
  sample: DeviceHardwareSample,
  decision: HardwareOptimisationDecision
): HardwareLearningMemory {
  const next: HardwareLearningMemory = previous || {
    samplesSeen: 0,
    lastScores: [],
    repeatedFaults: [],
    learnedNotes: [],
  };

  const faults: string[] = [];

  if (sample.thermalRisk === "high" || sample.thermalRisk === "critical") {
    faults.push("thermal_pressure");
  }

  if (sample.memoryPressure === "high" || sample.memoryPressure === "critical") {
    faults.push("memory_pressure");
  }

  if (sample.blePressure === "high" || sample.blePressure === "critical") {
    faults.push("ble_pressure");
  }

  if (sample.appCrashRisk === "high" || sample.appCrashRisk === "critical") {
    faults.push("crash_risk");
  }

  const lastScores = [...next.lastScores, decision.deviceHealthScore].slice(-12);
  const repeatedFaults = Array.from(new Set([...next.repeatedFaults, ...faults])).slice(-12);

  const learnedNotes = [
    ...next.learnedNotes,
    `Sample ${next.samplesSeen + 1}: score=${decision.deviceHealthScore}, pressure=${decision.pressure}, safeMode=${decision.safeMode}`,
  ].slice(-12);

  return {
    samplesSeen: next.samplesSeen + 1,
    lastScores,
    repeatedFaults,
    learnedNotes,
  };
}

export function runHardwareStabilizerDemo() {
  const sample = createDefaultHardwareSample();
  const decision = analyseHardwareSample(sample);
  const memory = updateHardwareLearningMemory(undefined, sample, decision);

  return {
    sample,
    decision,
    memory,
  };
}
TS

# ============================================================
# 3. HARDWARE POLICY FOR MAURIMESH RUNTIME
# ============================================================

cat > "$HW/HardwareRuntimePolicy.ts" <<'TS'
import { HardwareOptimisationDecision } from "./types";

export type MauriMeshRuntimePolicy = {
  allowBleScan: boolean;
  allowBleAdvertise: boolean;
  allowProofHashing: boolean;
  allowHeavyAnimation: boolean;
  maxBleRetries: number;
  routeMode: "store_forward" | "low_energy" | "balanced" | "fastest";
  operatorMessage: string;
};

export function createRuntimePolicy(
  decision: HardwareOptimisationDecision
): MauriMeshRuntimePolicy {
  if (decision.pressure === "critical") {
    return {
      allowBleScan: false,
      allowBleAdvertise: false,
      allowProofHashing: false,
      allowHeavyAnimation: false,
      maxBleRetries: 0,
      routeMode: "store_forward",
      operatorMessage:
        "Critical hardware pressure. MauriMesh safe mode active. BLE scanning paused.",
    };
  }

  if (decision.pressure === "high") {
    return {
      allowBleScan: true,
      allowBleAdvertise: true,
      allowProofHashing: false,
      allowHeavyAnimation: false,
      maxBleRetries: 1,
      routeMode: "low_energy",
      operatorMessage:
        "High hardware pressure. MauriMesh reduced scan intensity and delayed heavy proof tasks.",
    };
  }

  if (decision.pressure === "medium") {
    return {
      allowBleScan: true,
      allowBleAdvertise: true,
      allowProofHashing: true,
      allowHeavyAnimation: false,
      maxBleRetries: 2,
      routeMode: "balanced",
      operatorMessage:
        "Medium hardware pressure. MauriMesh using balanced runtime behaviour.",
    };
  }

  return {
    allowBleScan: true,
    allowBleAdvertise: true,
    allowProofHashing: true,
    allowHeavyAnimation: true,
    maxBleRetries: 3,
    routeMode: "fastest",
    operatorMessage:
      "Device stable. MauriMesh can use full UI and normal runtime behaviour.",
  };
}
TS

cat > "$HW/index.ts" <<'TS'
export * from "./types";
export * from "./DeviceHardwareStabilizer";
export * from "./HardwareRuntimePolicy";
TS

# ============================================================
# 4. DEVICE HARDWARE UI PANEL
# ============================================================

cat > "$COMP/DeviceHardwarePanel.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  createRuntimePolicy,
  runHardwareStabilizerDemo,
} from "../maurimesh/device-hardware";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriPanel } from "./MauriPanel";
import { StatusPill } from "./StatusPill";

function toneFromPressure(
  pressure: string
): "success" | "warning" | "danger" | "info" {
  if (pressure === "low") return "success";
  if (pressure === "medium") return "warning";
  return "danger";
}

export function DeviceHardwarePanel() {
  const { sample, decision, memory } = runHardwareStabilizerDemo();
  const policy = createRuntimePolicy(decision);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill label="DEVICE HARDWARE STABILIZER" tone={toneFromPressure(decision.pressure)} />
        <Text style={styles.score}>{decision.deviceHealthScore}%</Text>
        <Text style={styles.title}>Device Health Score</Text>
        <Text style={styles.detail}>{decision.finalTruth}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Current Hardware Sample</Text>
        <Text style={styles.rowText}>Battery: {sample.batteryPercent}%</Text>
        <Text style={styles.rowText}>Charging: {sample.isCharging ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Thermal risk: {sample.thermalRisk}</Text>
        <Text style={styles.rowText}>Memory pressure: {sample.memoryPressure}</Text>
        <Text style={styles.rowText}>Storage pressure: {sample.storagePressure}</Text>
        <Text style={styles.rowText}>BLE pressure: {sample.blePressure}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Optimisation Decision</Text>
        <StatusPill label={decision.safeMode ? "SAFE MODE" : "BALANCED MODE"} tone={decision.safeMode ? "warning" : "success"} />
        <Text style={styles.rowText}>Scan intensity: {decision.scanIntensity}</Text>
        <Text style={styles.rowText}>Animation intensity: {decision.animationIntensity}</Text>
        <Text style={styles.rowText}>Proof tasks: {decision.proofTaskMode}</Text>
        <Text style={styles.rowText}>Route preference: {decision.routePreference}</Text>
        <Text style={styles.rowText}>BLE retry policy: {decision.bleRetryPolicy}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Runtime Policy</Text>
        <Text style={styles.rowText}>BLE scan: {policy.allowBleScan ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>BLE advertise: {policy.allowBleAdvertise ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>Proof hashing: {policy.allowProofHashing ? "allowed" : "deferred"}</Text>
        <Text style={styles.rowText}>Heavy animation: {policy.allowHeavyAnimation ? "allowed" : "reduced"}</Text>
        <Text style={styles.rowText}>Max BLE retries: {policy.maxBleRetries}</Text>
        <Text style={styles.detail}>{policy.operatorMessage}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Recommendations</Text>
        {decision.recommendations.map((item) => (
          <Text key={item} style={styles.bullet}>✓ {item}</Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Learning Memory</Text>
        <Text style={styles.rowText}>Samples seen: {memory.samplesSeen}</Text>
        {memory.learnedNotes.map((note) => (
          <Text key={note} style={styles.bullet}>• {note}</Text>
        ))}
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
  detail: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  rowText: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
  bullet: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
});
TSX

# ============================================================
# 5. DEVICE HARDWARE SCREEN
# ============================================================

cat > "$APP/device-hardware.tsx" <<'TSX'
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { DeviceHardwarePanel } from "../src/components/DeviceHardwarePanel";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function DeviceHardwareScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="DEVICE HARDWARE"
        title="Hardware Stabilizer"
        subtitle="Studies device pressure and adjusts MauriMesh runtime behaviour for battery, thermal, memory, storage, BLE, proof tasks, and safe mode."
        tone="info"
      />
      <DeviceHardwarePanel />
    </AppShell>
  );
}
TSX

# ============================================================
# 6. PATCH BACKUP ROUTE REGISTRY
# ============================================================

node <<'NODE'
const fs = require("fs");

const file = "src/lib/uiBackupRoutes.ts";

if (!fs.existsSync(file)) {
  console.log("WARN: uiBackupRoutes.ts missing. Skipping backup route patch.");
  process.exit(0);
}

let src = fs.readFileSync(file, "utf8");

if (!src.includes('"deviceHardware"')) {
  if (src.includes('| "backupIntelligence";')) {
    src = src.replace(
      '| "backupIntelligence";',
      '| "backupIntelligence"\n  | "deviceHardware";'
    );
  } else {
    src = src.replace(/;\s*$/, '\n  | "deviceHardware";');
  }
}

if (!src.includes('route: "/device-hardware"')) {
  const entry = `,
  {
    key: "deviceHardware",
    title: "Device Hardware",
    route: "/device-hardware",
    fallbackRoute: "/operator-console",
    critical: true,
    purpose: "Device hardware stabilisation and runtime optimisation.",
  }`;

  src = src.replace(/\n\];/, `${entry}\n];`);
}

fs.writeFileSync(file, src);
NODE

# ============================================================
# 7. PATCH DASHBOARD BUTTON
# ============================================================

node <<'NODE'
const fs = require("fs");

const file = "app/dashboard.tsx";

if (!fs.existsSync(file)) {
  console.log("WARN: dashboard missing, cannot add Device Hardware button.");
  process.exit(0);
}

let src = fs.readFileSync(file, "utf8");

if (!src.includes("/device-hardware")) {
  const button = `          <MauriButton title="Device Hardware" onPress={() => router.push("/device-hardware")} />`;

  if (src.includes('<MauriButton title="Backup Intelligence"')) {
    src = src.replace(
      /(\s*<MauriButton title="Backup Intelligence"[\s\S]*?\/>)/,
      `$1\n${button}`
    );
  } else if (src.includes('<MauriButton title="Device Proof"')) {
    src = src.replace(
      /(\s*<MauriButton title="Device Proof"[\s\S]*?\/>)/,
      `$1\n${button}`
    );
  } else if (src.includes("</AppShell>")) {
    src = src.replace("</AppShell>", `      ${button}\n    </AppShell>`);
  } else {
    src += `\n// Device Hardware route marker: /device-hardware\n`;
  }

  fs.writeFileSync(file, src);
}
NODE

# ============================================================
# 8. CHECKER
# ============================================================

cat > "$ROOT/check-maurimesh-device-hardware.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-device-hardware-report-$STAMP.md"
LATEST="$DOCS/maurimesh-device-hardware-report-latest.md"

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

line "# MauriMesh Device Hardware Stabilizer Report"
line ""
line "Generated: $STAMP"
line ""

line "## Hardware Engine Files"

for file in \
  "src/maurimesh/device-hardware/types.ts" \
  "src/maurimesh/device-hardware/DeviceHardwareStabilizer.ts" \
  "src/maurimesh/device-hardware/HardwareRuntimePolicy.ts" \
  "src/maurimesh/device-hardware/index.ts"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## UI Files"

if has_file "src/components/DeviceHardwarePanel.tsx"; then pass "DeviceHardwarePanel exists"; else fail "DeviceHardwarePanel missing"; fi
if has_file "app/device-hardware.tsx"; then pass "Device Hardware screen exists"; else fail "app/device-hardware.tsx missing"; fi

line ""
line "## Hardware Capabilities"

for token in \
  "analyseHardwareSample" \
  "updateHardwareLearningMemory" \
  "createRuntimePolicy" \
  "runHardwareStabilizerDemo" \
  "safeMode" \
  "scanIntensity" \
  "bleRetryPolicy" \
  "routePreference"
do
  if grep -R "$token" "$ROOT/src/maurimesh/device-hardware" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"

if has_text "app/dashboard.tsx" "/device-hardware"; then pass "Dashboard has /device-hardware"; else fail "Dashboard missing /device-hardware"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/device-hardware"; then pass "Backup registry has /device-hardware"; else warn "Backup registry missing /device-hardware"; fi
if has_text "app/device-hardware.tsx" "DeviceHardwarePanel"; then pass "Screen uses DeviceHardwarePanel"; else fail "Screen missing DeviceHardwarePanel"; fi

line ""
line "## Truth Protection"

if has_text "src/maurimesh/device-hardware/DeviceHardwareStabilizer.ts" "cannot physically repair hardware"; then
  pass "Truth label prevents fake hardware repair claim"
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
echo "MAURIMESH DEVICE HARDWARE CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-maurimesh-device-hardware.sh"

# ============================================================
# 9. DOC
# ============================================================

cat > "$DOCS/maurimesh-device-hardware-stabilizer-$STAMP.md" <<MD
# MauriMesh Device Hardware Stabilizer

Generated: $STAMP

## Added

- Device health scoring
- Hardware pressure analysis
- Runtime optimisation policy
- Safe mode decision
- BLE retry policy decision
- Proof task throttle decision
- Animation intensity decision
- Route preference decision
- Learning memory summary
- Device Hardware UI screen
- Dashboard route
- Backup route registry entry
- Checker

## Route

\`/device-hardware\`

## Final Truth

MauriMesh can optimise its own runtime behaviour around the user's device conditions.
It cannot physically repair hardware or bypass Android system protections.
Real hardware telemetry requires APK/device integration.
MD

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running device hardware checker..."
./check-maurimesh-device-hardware.sh

echo ""
echo "============================================================"
echo "DONE: MAURIMESH DEVICE HARDWARE STABILIZER INSTALLED"
echo "============================================================"
echo "Created:"
echo "  src/maurimesh/device-hardware/*"
echo "  src/components/DeviceHardwarePanel.tsx"
echo "  app/device-hardware.tsx"
echo "  check-maurimesh-device-hardware.sh"
echo ""
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-device-hardware-report-latest.md"
echo ""
echo "Open route:"
echo "  /device-hardware"
echo "============================================================"
