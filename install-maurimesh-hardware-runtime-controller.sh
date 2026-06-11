#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH HARDWARE RUNTIME CONTROLLER"
echo "Connects native telemetry -> hardware stabilizer -> runtime policy."
echo "Adds controller, hook, UI screen, dashboard route, backup route,"
echo "and checker."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-hardware-runtime-controller-$STAMP"

APP="$ROOT/app"
SRC="$ROOT/src"
HW="$SRC/maurimesh/device-hardware"
COMP="$SRC/components"
HOOKS="$SRC/hooks"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$APP" "$HW" "$COMP" "$HOOKS" "$DOCS"

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
backup_file "app/hardware-runtime.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "src/maurimesh/device-hardware/HardwareRuntimeController.ts"
backup_file "src/maurimesh/device-hardware/index.ts"
backup_file "src/hooks/useHardwareRuntimeController.ts"
backup_file "src/components/HardwareRuntimeControllerPanel.tsx"

echo "Backup saved: $BACKUP"

# ============================================================
# 1. Hardware Runtime Controller
# ============================================================

cat > "$HW/HardwareRuntimeController.ts" <<'TS'
import {
  analyseHardwareSample,
  getNativeHardwareTelemetry,
  telemetryToHardwareSample,
  updateHardwareLearningMemory,
} from ".";
import { createRuntimePolicy, MauriMeshRuntimePolicy } from "./HardwareRuntimePolicy";
import {
  DeviceHardwareSample,
  HardwareLearningMemory,
  HardwareOptimisationDecision,
} from "./types";

export type HardwareRuntimeControllerState = {
  source: "NATIVE_ANDROID" | "JS_FALLBACK" | "CONTROLLER_FALLBACK";
  sample: DeviceHardwareSample;
  decision: HardwareOptimisationDecision;
  policy: MauriMeshRuntimePolicy;
  memory: HardwareLearningMemory;
  runtimeMode: "full" | "balanced" | "reduced" | "safe_mode";
  shouldThrottleBle: boolean;
  shouldThrottleProof: boolean;
  shouldReduceAnimations: boolean;
  shouldUseStoreForward: boolean;
  operatorAlert: string;
  finalTruth: string;
};

let controllerMemory: HardwareLearningMemory | undefined;

function modeFromDecision(
  decision: HardwareOptimisationDecision
): HardwareRuntimeControllerState["runtimeMode"] {
  if (decision.pressure === "critical") return "safe_mode";
  if (decision.pressure === "high") return "reduced";
  if (decision.pressure === "medium") return "balanced";
  return "full";
}

function fallbackSample(): DeviceHardwareSample {
  return {
    batteryPercent: 50,
    isCharging: false,
    thermalRisk: "medium",
    memoryPressure: "medium",
    storagePressure: "medium",
    networkPressure: "medium",
    blePressure: "medium",
    appCrashRisk: "low",
    foreground: true,
    timestamp: Date.now(),
  };
}

export async function evaluateHardwareRuntimeController(): Promise<HardwareRuntimeControllerState> {
  try {
    const reading = await getNativeHardwareTelemetry();
    const sample = telemetryToHardwareSample(reading);
    const decision = analyseHardwareSample(sample, controllerMemory);
    const policy = createRuntimePolicy(decision);

    controllerMemory = updateHardwareLearningMemory(
      controllerMemory,
      sample,
      decision
    );

    return {
      source: reading.source,
      sample,
      decision,
      policy,
      memory: controllerMemory,
      runtimeMode: modeFromDecision(decision),
      shouldThrottleBle:
        !policy.allowBleScan ||
        policy.maxBleRetries <= 1 ||
        decision.bleRetryPolicy !== "normal_retry",
      shouldThrottleProof: !policy.allowProofHashing,
      shouldReduceAnimations: !policy.allowHeavyAnimation,
      shouldUseStoreForward: policy.routeMode === "store_forward",
      operatorAlert: policy.operatorMessage,
      finalTruth:
        "Hardware Runtime Controller adapts MauriMesh app behaviour using telemetry. It cannot repair physical hardware, bypass Android protections, or prove BLE delivery without TX/RX/ACK logs.",
    };
  } catch {
    const sample = fallbackSample();
    const decision = analyseHardwareSample(sample, controllerMemory);
    const policy = createRuntimePolicy(decision);

    controllerMemory = updateHardwareLearningMemory(
      controllerMemory,
      sample,
      decision
    );

    return {
      source: "CONTROLLER_FALLBACK",
      sample,
      decision,
      policy,
      memory: controllerMemory,
      runtimeMode: modeFromDecision(decision),
      shouldThrottleBle: true,
      shouldThrottleProof: false,
      shouldReduceAnimations: true,
      shouldUseStoreForward: false,
      operatorAlert:
        "Controller fallback active. Hardware telemetry was unavailable, so MauriMesh is using balanced-safe behaviour.",
      finalTruth:
        "Controller fallback protects the app when telemetry fails. It does not prove native readings.",
    };
  }
}

export function resetHardwareRuntimeMemory() {
  controllerMemory = undefined;
}

export function getHardwareRuntimeMemory() {
  return controllerMemory;
}

export type BleRuntimeTuning = {
  scanWindowMs: number;
  scanCooldownMs: number;
  maxRetries: number;
  allowAdvertise: boolean;
  allowScan: boolean;
  reason: string;
};

export function createBleRuntimeTuning(
  state: HardwareRuntimeControllerState
): BleRuntimeTuning {
  if (state.runtimeMode === "safe_mode") {
    return {
      scanWindowMs: 0,
      scanCooldownMs: 30000,
      maxRetries: 0,
      allowAdvertise: false,
      allowScan: false,
      reason: "Safe mode: BLE paused to protect device stability.",
    };
  }

  if (state.runtimeMode === "reduced") {
    return {
      scanWindowMs: 2500,
      scanCooldownMs: 15000,
      maxRetries: 1,
      allowAdvertise: state.policy.allowBleAdvertise,
      allowScan: state.policy.allowBleScan,
      reason: "Reduced mode: BLE scan storms prevented.",
    };
  }

  if (state.runtimeMode === "balanced") {
    return {
      scanWindowMs: 5000,
      scanCooldownMs: 8000,
      maxRetries: 2,
      allowAdvertise: state.policy.allowBleAdvertise,
      allowScan: state.policy.allowBleScan,
      reason: "Balanced mode: normal low-risk BLE cadence.",
    };
  }

  return {
    scanWindowMs: 8000,
    scanCooldownMs: 4000,
    maxRetries: 3,
    allowAdvertise: true,
    allowScan: true,
    reason: "Full mode: device is stable enough for normal BLE cadence.",
  };
}

export type ProofRuntimeTuning = {
  allowProofHashing: boolean;
  allowLedgerWrite: boolean;
  proofBatchSize: number;
  reason: string;
};

export function createProofRuntimeTuning(
  state: HardwareRuntimeControllerState
): ProofRuntimeTuning {
  if (state.runtimeMode === "safe_mode") {
    return {
      allowProofHashing: false,
      allowLedgerWrite: true,
      proofBatchSize: 1,
      reason: "Safe mode: proof hashing paused, lightweight ledger writes allowed.",
    };
  }

  if (state.runtimeMode === "reduced") {
    return {
      allowProofHashing: false,
      allowLedgerWrite: true,
      proofBatchSize: 2,
      reason: "Reduced mode: proof hashing deferred until device pressure drops.",
    };
  }

  if (state.runtimeMode === "balanced") {
    return {
      allowProofHashing: true,
      allowLedgerWrite: true,
      proofBatchSize: 5,
      reason: "Balanced mode: proof tasks allowed at moderate batch size.",
    };
  }

  return {
    allowProofHashing: true,
    allowLedgerWrite: true,
    proofBatchSize: 10,
    reason: "Full mode: device stable for normal proof throughput.",
  };
}
TS

# ============================================================
# 2. Export controller
# ============================================================

if [ -f "$HW/index.ts" ]; then
  grep -Fq './HardwareRuntimeController' "$HW/index.ts" || echo 'export * from "./HardwareRuntimeController";' >> "$HW/index.ts"
else
  cat > "$HW/index.ts" <<'TS'
export * from "./types";
export * from "./DeviceHardwareStabilizer";
export * from "./HardwareRuntimePolicy";
export * from "./NativeHardwareTelemetry";
export * from "./HardwareRuntimeController";
TS
fi

# ============================================================
# 3. React hook
# ============================================================

cat > "$HOOKS/useHardwareRuntimeController.ts" <<'TS'
import { useEffect, useState } from "react";
import {
  BleRuntimeTuning,
  createBleRuntimeTuning,
  createProofRuntimeTuning,
  evaluateHardwareRuntimeController,
  HardwareRuntimeControllerState,
  ProofRuntimeTuning,
} from "../maurimesh/device-hardware";

export type HardwareRuntimeHookState = {
  loading: boolean;
  state: HardwareRuntimeControllerState | null;
  ble: BleRuntimeTuning | null;
  proof: ProofRuntimeTuning | null;
  refresh: () => Promise<void>;
};

export function useHardwareRuntimeController(): HardwareRuntimeHookState {
  const [loading, setLoading] = useState(true);
  const [state, setState] = useState<HardwareRuntimeControllerState | null>(null);
  const [ble, setBle] = useState<BleRuntimeTuning | null>(null);
  const [proof, setProof] = useState<ProofRuntimeTuning | null>(null);

  async function refresh() {
    setLoading(true);
    const next = await evaluateHardwareRuntimeController();
    setState(next);
    setBle(createBleRuntimeTuning(next));
    setProof(createProofRuntimeTuning(next));
    setLoading(false);
  }

  useEffect(() => {
    refresh();
  }, []);

  return {
    loading,
    state,
    ble,
    proof,
    refresh,
  };
}
TS

# ============================================================
# 4. UI Panel
# ============================================================

cat > "$COMP/HardwareRuntimeControllerPanel.tsx" <<'TSX'
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { useHardwareRuntimeController } from "../hooks/useHardwareRuntimeController";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriButton } from "./MauriButton";
import { MauriPanel } from "./MauriPanel";
import { StatusPill } from "./StatusPill";

function modeTone(
  mode: string
): "success" | "warning" | "danger" | "info" {
  if (mode === "full") return "success";
  if (mode === "balanced") return "info";
  if (mode === "reduced") return "warning";
  return "danger";
}

export function HardwareRuntimeControllerPanel() {
  const runtime = useHardwareRuntimeController();

  if (runtime.loading || !runtime.state || !runtime.ble || !runtime.proof) {
    return (
      <MauriPanel>
        <StatusPill label="LOADING CONTROLLER" tone="info" />
        <Text style={styles.detail}>Evaluating hardware runtime policy...</Text>
      </MauriPanel>
    );
  }

  const state = runtime.state;

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill label={state.source} tone={state.source === "NATIVE_ANDROID" ? "success" : "warning"} />
        <Text style={styles.score}>{state.decision.deviceHealthScore}%</Text>
        <Text style={styles.title}>Hardware Runtime Controller</Text>
        <StatusPill label={state.runtimeMode.toUpperCase()} tone={modeTone(state.runtimeMode)} />
        <Text style={styles.detail}>{state.operatorAlert}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Runtime Flags</Text>
        <Text style={styles.rowText}>Throttle BLE: {state.shouldThrottleBle ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Throttle proof: {state.shouldThrottleProof ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Reduce animations: {state.shouldReduceAnimations ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Use store-forward: {state.shouldUseStoreForward ? "yes" : "no"}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>BLE Runtime Tuning</Text>
        <Text style={styles.rowText}>Allow scan: {runtime.ble.allowScan ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Allow advertise: {runtime.ble.allowAdvertise ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>Scan window: {runtime.ble.scanWindowMs} ms</Text>
        <Text style={styles.rowText}>Scan cooldown: {runtime.ble.scanCooldownMs} ms</Text>
        <Text style={styles.rowText}>Max retries: {runtime.ble.maxRetries}</Text>
        <Text style={styles.detail}>{runtime.ble.reason}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Proof Runtime Tuning</Text>
        <Text style={styles.rowText}>Proof hashing: {runtime.proof.allowProofHashing ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>Ledger write: {runtime.proof.allowLedgerWrite ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>Batch size: {runtime.proof.proofBatchSize}</Text>
        <Text style={styles.detail}>{runtime.proof.reason}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Learning Memory</Text>
        <Text style={styles.rowText}>Samples seen: {state.memory.samplesSeen}</Text>
        <Text style={styles.rowText}>Repeated faults: {state.memory.repeatedFaults.join(", ") || "none"}</Text>
        {state.memory.learnedNotes.map((note) => (
          <Text key={note} style={styles.bullet}>• {note}</Text>
        ))}
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Truth Boundary</Text>
        <Text style={styles.detail}>{state.finalTruth}</Text>
      </MauriPanel>

      <MauriButton title="Refresh Runtime Policy" onPress={runtime.refresh} />
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
# 5. Screen
# ============================================================

cat > "$APP/hardware-runtime.tsx" <<'TSX'
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { HardwareRuntimeControllerPanel } from "../src/components/HardwareRuntimeControllerPanel";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function HardwareRuntimeScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="HARDWARE RUNTIME"
        title="Runtime Controller"
        subtitle="Connects native telemetry to BLE tuning, proof throttling, animation reduction, safe mode, and store-forward routing."
        tone="info"
      />
      <HardwareRuntimeControllerPanel />
    </AppShell>
  );
}
TSX

# ============================================================
# 6. Patch route registry + dashboard
# ============================================================

node <<'NODE'
const fs = require("fs");

const registry = "src/lib/uiBackupRoutes.ts";
if (fs.existsSync(registry)) {
  let src = fs.readFileSync(registry, "utf8");

  if (!src.includes('"hardwareRuntime"')) {
    if (src.includes('| "nativeTelemetry";')) {
      src = src.replace(
        '| "nativeTelemetry";',
        '| "nativeTelemetry"\n  | "hardwareRuntime";'
      );
    } else {
      src = src.replace(/;\s*$/, '\n  | "hardwareRuntime";');
    }
  }

  if (!src.includes('route: "/hardware-runtime"')) {
    const entry = `,
  {
    key: "hardwareRuntime",
    title: "Hardware Runtime",
    route: "/hardware-runtime",
    fallbackRoute: "/native-telemetry",
    critical: true,
    purpose: "Hardware-aware runtime optimisation controller.",
  }`;
    src = src.replace(/\n\];/, `${entry}\n];`);
  }

  fs.writeFileSync(registry, src);
}

const dashboard = "app/dashboard.tsx";
if (fs.existsSync(dashboard)) {
  let src = fs.readFileSync(dashboard, "utf8");

  if (!src.includes("/hardware-runtime")) {
    const button = `          <MauriButton title="Hardware Runtime" onPress={() => router.push("/hardware-runtime")} />`;

    if (src.includes('<MauriButton title="Native Telemetry"')) {
      src = src.replace(
        /(\s*<MauriButton title="Native Telemetry"[\s\S]*?\/>)/,
        `$1\n${button}`
      );
    } else if (src.includes("</AppShell>")) {
      src = src.replace("</AppShell>", `      ${button}\n    </AppShell>`);
    } else {
      src += `\n// Hardware Runtime route marker: /hardware-runtime\n`;
    }

    fs.writeFileSync(dashboard, src);
  }
}
NODE

# ============================================================
# 7. Checker
# ============================================================

cat > "$ROOT/check-maurimesh-hardware-runtime-controller.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-hardware-runtime-controller-report-$STAMP.md"
LATEST="$DOCS/maurimesh-hardware-runtime-controller-report-latest.md"

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

line "# MauriMesh Hardware Runtime Controller Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/device-hardware/HardwareRuntimeController.ts" \
  "src/hooks/useHardwareRuntimeController.ts" \
  "src/components/HardwareRuntimeControllerPanel.tsx" \
  "app/hardware-runtime.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Capabilities"
for token in \
  "evaluateHardwareRuntimeController" \
  "createBleRuntimeTuning" \
  "createProofRuntimeTuning" \
  "shouldThrottleBle" \
  "shouldThrottleProof" \
  "shouldReduceAnimations" \
  "shouldUseStoreForward" \
  "runtimeMode" \
  "NATIVE_ANDROID" \
  "JS_FALLBACK"
do
  if grep -R "$token" "$ROOT/src/maurimesh/device-hardware/HardwareRuntimeController.ts" "$ROOT/src/components/HardwareRuntimeControllerPanel.tsx" "$ROOT/src/hooks/useHardwareRuntimeController.ts" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"
if has_text "app/dashboard.tsx" "/hardware-runtime"; then pass "Dashboard has /hardware-runtime"; else fail "Dashboard missing /hardware-runtime"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/hardware-runtime"; then pass "Backup registry has /hardware-runtime"; else warn "Backup registry missing /hardware-runtime"; fi
if has_text "app/hardware-runtime.tsx" "HardwareRuntimeControllerPanel"; then pass "Screen uses HardwareRuntimeControllerPanel"; else fail "Screen missing panel"; fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/device-hardware/HardwareRuntimeController.ts" "cannot repair physical hardware"; then
  pass "Truth boundary present"
else
  warn "Truth boundary not confirmed"
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
echo "HARDWARE RUNTIME CONTROLLER CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-maurimesh-hardware-runtime-controller.sh"

# ============================================================
# 8. Docs
# ============================================================

cat > "$DOCS/maurimesh-hardware-runtime-controller-$STAMP.md" <<MD
# MauriMesh Hardware Runtime Controller

Generated: $STAMP

## Added

- HardwareRuntimeController.ts
- useHardwareRuntimeController hook
- HardwareRuntimeControllerPanel
- /hardware-runtime route
- Dashboard button
- Backup route registry entry
- Checker

## Controls

- BLE scan window
- BLE cooldown
- BLE retry count
- BLE advertise permission
- Proof hashing permission
- Proof ledger batch size
- Animation reduction flag
- Store-forward routing flag
- Safe mode state
- Operator alert

## Final Truth

This layer lets MauriMesh adapt its own runtime behaviour from native telemetry.
It does not repair physical hardware.
It does not bypass Android restrictions.
It does not prove BLE delivery without device TX/RX/ACK logs.
MD

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running hardware runtime controller checker..."
./check-maurimesh-hardware-runtime-controller.sh

echo ""
echo "============================================================"
echo "DONE: HARDWARE RUNTIME CONTROLLER INSTALLED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Created:"
echo "  src/maurimesh/device-hardware/HardwareRuntimeController.ts"
echo "  src/hooks/useHardwareRuntimeController.ts"
echo "  src/components/HardwareRuntimeControllerPanel.tsx"
echo "  app/hardware-runtime.tsx"
echo "  check-maurimesh-hardware-runtime-controller.sh"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-hardware-runtime-controller-report-latest.md"
echo ""
echo "Open route:"
echo "  /hardware-runtime"
echo "============================================================"
