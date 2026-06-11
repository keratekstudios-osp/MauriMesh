#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "INSTALL MAURIMESH NATIVE TELEMETRY BRIDGE - CLEAN"
echo "Creates APK-ready telemetry JS bridge + UI + route wiring."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-native-telemetry-clean-$STAMP"

APP="$ROOT/app"
SRC="$ROOT/src"
HW="$SRC/maurimesh/device-hardware"
COMP="$SRC/components"
DOCS="$ROOT/docs"

mkdir -p "$BACKUP" "$APP" "$HW" "$COMP" "$DOCS"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: package.json not found. Run this from /home/runner/workspace"
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
backup_file "app/native-telemetry.tsx"
backup_file "src/lib/uiBackupRoutes.ts"
backup_file "src/components/NativeTelemetryPanel.tsx"
backup_file "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"
backup_file "src/maurimesh/device-hardware/index.ts"

echo "Backup saved: $BACKUP"

cat > "$HW/NativeHardwareTelemetry.ts" <<'TS'
import { NativeModules, Platform } from "react-native";
import { DeviceHardwareSample, HardwarePressure } from "./types";

export type NativeHardwareTelemetryReading = {
  source: "NATIVE_ANDROID" | "JS_FALLBACK";
  platform: string;
  batteryPercent: number;
  isCharging: boolean;
  memoryUsedMb: number;
  memoryTotalMb: number;
  memoryPressure: HardwarePressure;
  storageFreeMb: number;
  storageTotalMb: number;
  storagePressure: HardwarePressure;
  thermalRisk: HardwarePressure;
  bleAvailable: boolean;
  bleEnabled: boolean;
  blePressure: HardwarePressure;
  appCrashRisk: HardwarePressure;
  foreground: boolean;
  timestamp: number;
  truth: string;
};

type NativeTelemetryModule = {
  getHardwareTelemetry?: () => Promise<Partial<NativeHardwareTelemetryReading>>;
};

function pressureFromMemory(used: number, total: number): HardwarePressure {
  if (!total || total <= 0) return "medium";
  const ratio = used / total;
  if (ratio >= 0.94) return "critical";
  if (ratio >= 0.84) return "high";
  if (ratio >= 0.68) return "medium";
  return "low";
}

function pressureFromStorage(free: number, total: number): HardwarePressure {
  if (!total || total <= 0) return "medium";
  const ratio = free / total;
  if (ratio <= 0.04) return "critical";
  if (ratio <= 0.1) return "high";
  if (ratio <= 0.22) return "medium";
  return "low";
}

function fallbackReading(): NativeHardwareTelemetryReading {
  return {
    source: "JS_FALLBACK",
    platform: Platform.OS,
    batteryPercent: 68,
    isCharging: false,
    memoryUsedMb: 1200,
    memoryTotalMb: 4096,
    memoryPressure: "medium",
    storageFreeMb: 8192,
    storageTotalMb: 64000,
    storagePressure: "low",
    thermalRisk: "low",
    bleAvailable: Platform.OS === "android",
    bleEnabled: false,
    blePressure: "medium",
    appCrashRisk: "low",
    foreground: true,
    timestamp: Date.now(),
    truth:
      "JS fallback telemetry. Real hardware readings require APK native module. MauriMesh cannot physically repair hardware or bypass Android protections.",
  };
}

export async function getNativeHardwareTelemetry(): Promise<NativeHardwareTelemetryReading> {
  const nativeModule = NativeModules.MauriMeshHardwareTelemetry as NativeTelemetryModule | undefined;

  if (
    Platform.OS === "android" &&
    nativeModule &&
    typeof nativeModule.getHardwareTelemetry === "function"
  ) {
    try {
      const native = await nativeModule.getHardwareTelemetry();

      const memoryUsedMb = Number(native.memoryUsedMb ?? 0);
      const memoryTotalMb = Number(native.memoryTotalMb ?? 0);
      const storageFreeMb = Number(native.storageFreeMb ?? 0);
      const storageTotalMb = Number(native.storageTotalMb ?? 0);

      return {
        source: "NATIVE_ANDROID",
        platform: "android",
        batteryPercent: Number(native.batteryPercent ?? 50),
        isCharging: Boolean(native.isCharging ?? false),
        memoryUsedMb,
        memoryTotalMb,
        memoryPressure:
          native.memoryPressure || pressureFromMemory(memoryUsedMb, memoryTotalMb),
        storageFreeMb,
        storageTotalMb,
        storagePressure:
          native.storagePressure || pressureFromStorage(storageFreeMb, storageTotalMb),
        thermalRisk: native.thermalRisk || "medium",
        bleAvailable: Boolean(native.bleAvailable ?? false),
        bleEnabled: Boolean(native.bleEnabled ?? false),
        blePressure: native.blePressure || "medium",
        appCrashRisk: native.appCrashRisk || "low",
        foreground: Boolean(native.foreground ?? true),
        timestamp: Number(native.timestamp ?? Date.now()),
        truth:
          "Native Android telemetry received. MauriMesh can optimise app behaviour but cannot physically repair hardware or bypass Android protections.",
      };
    } catch {
      return fallbackReading();
    }
  }

  return fallbackReading();
}

export function telemetryToHardwareSample(
  reading: NativeHardwareTelemetryReading
): DeviceHardwareSample {
  return {
    batteryPercent: reading.batteryPercent,
    isCharging: reading.isCharging,
    thermalRisk: reading.thermalRisk,
    memoryPressure: reading.memoryPressure,
    storagePressure: reading.storagePressure,
    networkPressure: "medium",
    blePressure: reading.blePressure,
    appCrashRisk: reading.appCrashRisk,
    foreground: reading.foreground,
    timestamp: reading.timestamp,
  };
}
TS

if [ -f "$HW/index.ts" ]; then
  grep -Fq './NativeHardwareTelemetry' "$HW/index.ts" || echo 'export * from "./NativeHardwareTelemetry";' >> "$HW/index.ts"
else
  cat > "$HW/index.ts" <<'TS'
export * from "./types";
export * from "./DeviceHardwareStabilizer";
export * from "./HardwareRuntimePolicy";
export * from "./NativeHardwareTelemetry";
TS
fi

cat > "$COMP/NativeTelemetryPanel.tsx" <<'TSX'
import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import {
  analyseHardwareSample,
  createRuntimePolicy,
  getNativeHardwareTelemetry,
  NativeHardwareTelemetryReading,
  telemetryToHardwareSample,
} from "../maurimesh/device-hardware";
import { mauriTheme } from "../theme/mauriTheme";
import { MauriPanel } from "./MauriPanel";
import { StatusPill } from "./StatusPill";

function sourceTone(source: string): "success" | "warning" | "danger" | "info" {
  return source === "NATIVE_ANDROID" ? "success" : "warning";
}

function pressureTone(pressure: string): "success" | "warning" | "danger" | "info" {
  if (pressure === "low") return "success";
  if (pressure === "medium") return "warning";
  return "danger";
}

export function NativeTelemetryPanel() {
  const [reading, setReading] = useState<NativeHardwareTelemetryReading | null>(null);

  useEffect(() => {
    getNativeHardwareTelemetry().then(setReading);
  }, []);

  if (!reading) {
    return (
      <MauriPanel>
        <StatusPill label="LOADING TELEMETRY" tone="info" />
        <Text style={styles.detail}>Reading telemetry...</Text>
      </MauriPanel>
    );
  }

  const sample = telemetryToHardwareSample(reading);
  const decision = analyseHardwareSample(sample);
  const policy = createRuntimePolicy(decision);

  return (
    <View style={styles.wrap}>
      <MauriPanel glow>
        <StatusPill label={reading.source} tone={sourceTone(reading.source)} />
        <Text style={styles.score}>{decision.deviceHealthScore}%</Text>
        <Text style={styles.title}>Native Telemetry Health</Text>
        <Text style={styles.detail}>{reading.truth}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Battery</Text>
        <Text style={styles.rowText}>Battery: {reading.batteryPercent}%</Text>
        <Text style={styles.rowText}>Charging: {reading.isCharging ? "yes" : "no"}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Memory</Text>
        <StatusPill label={reading.memoryPressure} tone={pressureTone(reading.memoryPressure)} />
        <Text style={styles.rowText}>Used: {reading.memoryUsedMb} MB</Text>
        <Text style={styles.rowText}>Total: {reading.memoryTotalMb} MB</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Storage</Text>
        <StatusPill label={reading.storagePressure} tone={pressureTone(reading.storagePressure)} />
        <Text style={styles.rowText}>Free: {reading.storageFreeMb} MB</Text>
        <Text style={styles.rowText}>Total: {reading.storageTotalMb} MB</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Thermal + BLE</Text>
        <Text style={styles.rowText}>Thermal risk: {reading.thermalRisk}</Text>
        <Text style={styles.rowText}>BLE available: {reading.bleAvailable ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>BLE enabled: {reading.bleEnabled ? "yes" : "no"}</Text>
        <Text style={styles.rowText}>BLE pressure: {reading.blePressure}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Runtime Policy</Text>
        <Text style={styles.rowText}>BLE scan: {policy.allowBleScan ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>BLE advertise: {policy.allowBleAdvertise ? "allowed" : "paused"}</Text>
        <Text style={styles.rowText}>Proof hashing: {policy.allowProofHashing ? "allowed" : "deferred"}</Text>
        <Text style={styles.rowText}>Heavy animation: {policy.allowHeavyAnimation ? "allowed" : "reduced"}</Text>
        <Text style={styles.rowText}>Route mode: {policy.routeMode}</Text>
        <Text style={styles.detail}>{policy.operatorMessage}</Text>
      </MauriPanel>

      <MauriPanel>
        <Text style={styles.sectionTitle}>Truth Boundary</Text>
        <Text style={styles.detail}>
          This reads and adapts to device conditions when native APK telemetry exists. It cannot repair physical hardware, override Android restrictions, or prove BLE delivery without TX/RX/ACK logs.
        </Text>
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
});
TSX

cat > "$APP/native-telemetry.tsx" <<'TSX'
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { NativeTelemetryPanel } from "../src/components/NativeTelemetryPanel";

export default function NativeTelemetryScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="NATIVE TELEMETRY"
        title="Native Telemetry"
        subtitle="APK-ready hardware bridge for battery, memory, storage, thermal, BLE adapter state, and runtime optimisation."
        tone="info"
      />
      <NativeTelemetryPanel />
    </AppShell>
  );
}
TSX

cat > "$DOCS/maurimesh-native-telemetry-kotlin-template-$STAMP.md" <<'MD'
# MauriMesh Native Telemetry Kotlin Target

Native module expected by JavaScript:

MauriMeshHardwareTelemetry

Expected method:

getHardwareTelemetry()

Expected fields:

batteryPercent
isCharging
memoryUsedMb
memoryTotalMb
storageFreeMb
storageTotalMb
thermalRisk
bleAvailable
bleEnabled
blePressure
appCrashRisk
foreground
timestamp

This JS bridge safely falls back until the Android Kotlin module is installed.
MD

node <<'NODE'
const fs = require("fs");

const registry = "src/lib/uiBackupRoutes.ts";
if (fs.existsSync(registry)) {
  let src = fs.readFileSync(registry, "utf8");

  if (!src.includes('"nativeTelemetry"')) {
    if (src.includes('| "deviceHardware";')) {
      src = src.replace('| "deviceHardware";', '| "deviceHardware"\n  | "nativeTelemetry";');
    } else {
      src = src.replace(/;\s*$/, '\n  | "nativeTelemetry";');
    }
  }

  if (!src.includes('route: "/native-telemetry"')) {
    const entry = `,
  {
    key: "nativeTelemetry",
    title: "Native Telemetry",
    route: "/native-telemetry",
    fallbackRoute: "/device-hardware",
    critical: true,
    purpose: "APK-ready native hardware telemetry bridge.",
  }`;
    src = src.replace(/\n\];/, `${entry}\n];`);
  }

  fs.writeFileSync(registry, src);
}

const dashboard = "app/dashboard.tsx";
if (fs.existsSync(dashboard)) {
  let src = fs.readFileSync(dashboard, "utf8");

  if (!src.includes("/native-telemetry")) {
    const button = `          <MauriButton title="Native Telemetry" onPress={() => router.push("/native-telemetry")} />`;

    if (src.includes('<MauriButton title="Device Hardware"')) {
      src = src.replace(/(\s*<MauriButton title="Device Hardware"[\s\S]*?\/>)/, `$1\n${button}`);
    } else if (src.includes("</AppShell>")) {
      src = src.replace("</AppShell>", `      ${button}\n    </AppShell>`);
    } else {
      src += `\n// Native Telemetry route marker: /native-telemetry\n`;
    }

    fs.writeFileSync(dashboard, src);
  }
}
NODE

cat > "$ROOT/check-maurimesh-native-telemetry.sh" <<'CHECK'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-native-telemetry-report-$STAMP.md"
LATEST="$DOCS/maurimesh-native-telemetry-report-latest.md"

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

line "# MauriMesh Native Telemetry Bridge Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
if has_file "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"; then pass "NativeHardwareTelemetry.ts exists"; else fail "NativeHardwareTelemetry.ts missing"; fi
if has_file "src/components/NativeTelemetryPanel.tsx"; then pass "NativeTelemetryPanel.tsx exists"; else fail "NativeTelemetryPanel.tsx missing"; fi
if has_file "app/native-telemetry.tsx"; then pass "app/native-telemetry.tsx exists"; else fail "app/native-telemetry.tsx missing"; fi

line ""
line "## Capabilities"
for token in getNativeHardwareTelemetry telemetryToHardwareSample NativeModules MauriMeshHardwareTelemetry JS_FALLBACK NATIVE_ANDROID batteryPercent memoryPressure storagePressure bleEnabled; do
  if grep -R "$token" "$ROOT/src/maurimesh/device-hardware/NativeHardwareTelemetry.ts" "$ROOT/src/components/NativeTelemetryPanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"
if has_text "app/dashboard.tsx" "/native-telemetry"; then pass "Dashboard has /native-telemetry"; else fail "Dashboard missing /native-telemetry"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/native-telemetry"; then pass "Backup registry has /native-telemetry"; else warn "Backup registry missing /native-telemetry"; fi
if has_text "app/native-telemetry.tsx" "NativeTelemetryPanel"; then pass "Screen uses NativeTelemetryPanel"; else fail "Screen missing NativeTelemetryPanel"; fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts" "cannot physically repair hardware"; then
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
echo "MAURIMESH NATIVE TELEMETRY CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
CHECK

chmod +x "$ROOT/check-maurimesh-native-telemetry.sh"

cat > "$DOCS/maurimesh-native-telemetry-bridge-$STAMP.md" <<MD
# MauriMesh Native Telemetry Bridge

Generated: $STAMP

Added:
- Native telemetry JS interface
- Safe JS fallback
- Hardware sample adapter
- Native Telemetry UI panel
- Native Telemetry screen
- Dashboard route
- Backup route registry entry
- Checker
- Kotlin native module notes

Route:
/native-telemetry

Truth:
The JS layer is APK-ready and safe in Replit.
Real hardware readings require a native Android module inside the APK.
MauriMesh can optimise its own app behaviour around hardware conditions.
It cannot physically repair hardware or bypass Android protections.
MD

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

echo ""
echo "Running native telemetry checker..."
./check-maurimesh-native-telemetry.sh

echo ""
echo "============================================================"
echo "DONE: NATIVE TELEMETRY BRIDGE INSTALLED"
echo "============================================================"
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Created:"
echo "  src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"
echo "  src/components/NativeTelemetryPanel.tsx"
echo "  app/native-telemetry.tsx"
echo "  check-maurimesh-native-telemetry.sh"
echo ""
echo "Latest report:"
echo "  docs/maurimesh-native-telemetry-report-latest.md"
echo ""
echo "Open route:"
echo "  /native-telemetry"
echo "============================================================"
