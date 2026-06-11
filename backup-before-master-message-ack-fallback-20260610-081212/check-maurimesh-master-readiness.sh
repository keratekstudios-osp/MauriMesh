#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"

mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-master-readiness-report-$STAMP.md"
LATEST="$DOCS/maurimesh-master-readiness-report-latest.md"
JSON="$DOCS/maurimesh-master-readiness-report-$STAMP.json"

PASS=0
FAIL=0
WARN=0

line(){ echo "$1" | tee -a "$REPORT"; }
pass(){ PASS=$((PASS+1)); line "- [x] $1"; }
fail(){ FAIL=$((FAIL+1)); line "- [ ] MISSING: $1"; }
warn(){ WARN=$((WARN+1)); line "- [!] PARTIAL: $1"; }

has_file(){ [ -f "$ROOT/$1" ]; }
has_dir(){ [ -d "$ROOT/$1" ]; }
has_text(){ [ -f "$ROOT/$1" ] && grep -Fq "$2" "$ROOT/$1"; }

run_checker() {
  local script="$1"
  local label="$2"

  line ""
  line "### $label"
  line ""

  if [ ! -f "$ROOT/$script" ]; then
    warn "$label checker missing: $script"
    return
  fi

  if "$ROOT/$script" >> "$REPORT" 2>&1; then
    pass "$label checker passed"
  else
    fail "$label checker failed"
  fi
}

: > "$REPORT"

line "# MauriMesh Master Readiness Report"
line ""
line "Generated: $STAMP"
line ""

line "## 1. Root Project"
if has_file "package.json"; then pass "package.json exists"; else fail "package.json missing"; fi
if has_dir "app"; then pass "app/ exists"; else fail "app/ missing"; fi
if has_dir "src"; then pass "src/ exists"; else fail "src/ missing"; fi
if has_dir "docs"; then pass "docs/ exists"; else fail "docs/ missing"; fi

line ""
line "## 2. Core Routes"

ROUTES=(
  "/login:app/login.tsx"
  "/dashboard:app/dashboard.tsx"
  "/chat:app/chat.tsx"
  "/settings:app/settings.tsx"
  "/add-friend:app/add-friend.tsx"
  "/living-mesh:app/living-mesh.tsx"
  "/mesh-status:app/mesh-status.tsx"
  "/pixel-calling:app/pixel-calling.tsx"
  "/ui-roadmap:app/ui-roadmap.tsx"
  "/proof-ledger:app/proof-ledger.tsx"
  "/route-lab:app/route-lab.tsx"
  "/tikanga-engine:app/tikanga-engine.tsx"
  "/self-healing:app/self-healing.tsx"
  "/device-proof:app/device-proof.tsx"
  "/operator-console:app/operator-console.tsx"
  "/mauricore-governance:app/mauricore-governance.tsx"
  "/mauricore-ble-runtime:app/mauricore-ble-runtime.tsx"
  "/intelligence:app/intelligence.tsx"
  "/backup-intelligence:app/backup-intelligence.tsx"
  "/device-hardware:app/device-hardware.tsx"
  "/native-telemetry:app/native-telemetry.tsx"
  "/hardware-runtime:app/hardware-runtime.tsx"
  "/ble-hardware-runtime:app/ble-hardware-runtime.tsx"
  "/hybrid-wifi-ble-mesh:app/hybrid-wifi-ble-mesh.tsx"
)

for item in "${ROUTES[@]}"; do
  route="${item%%:*}"
  file="${item#*:}"

  if has_file "$file"; then
    pass "Route file exists: $file"
  else
    fail "Route file missing: $file"
  fi

  if [ "$route" != "/dashboard" ] && [ "$route" != "/login" ]; then
    if has_text "app/dashboard.tsx" "$route"; then
      pass "Dashboard route wired: $route"
    else
      warn "Dashboard route not confirmed: $route"
    fi
  fi

  if has_text "src/lib/uiBackupRoutes.ts" "$route"; then
    pass "Backup route registry contains: $route"
  else
    warn "Backup route registry missing/not checked: $route"
  fi
done

line ""
line "## 3. Layer Files"

FILES=(
  "src/lib/uiBackupRoutes.ts"
  "src/components/SafeNavButton.tsx"

  "src/maurimesh/intelligence/types.ts"
  "src/maurimesh/intelligence/RouteIntelligence.ts"
  "src/maurimesh/intelligence/ProofIntelligence.ts"
  "src/maurimesh/intelligence/TikangaIntelligence.ts"
  "src/maurimesh/intelligence/SelfHealingIntelligence.ts"
  "src/maurimesh/intelligence/DeviceReadinessIntelligence.ts"
  "src/maurimesh/intelligence/IntelligenceOrchestrator.ts"
  "src/maurimesh/intelligence/BackupIntelligence.ts"

  "src/maurimesh/device-hardware/types.ts"
  "src/maurimesh/device-hardware/DeviceHardwareStabilizer.ts"
  "src/maurimesh/device-hardware/HardwareRuntimePolicy.ts"
  "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts"
  "src/maurimesh/device-hardware/HardwareRuntimeController.ts"

  "src/hooks/useHardwareRuntimeController.ts"

  "src/maurimesh/ble-runtime/BleHardwareBackupPolicy.ts"
  "src/maurimesh/ble-runtime/BleHardwareRuntimeAdapter.ts"
  "src/maurimesh/ble-runtime/index.ts"

  "src/components/IntelligencePanel.tsx"
  "src/components/BackupIntelligencePanel.tsx"
  "src/components/DeviceHardwarePanel.tsx"
  "src/components/NativeTelemetryPanel.tsx"
  "src/components/HardwareRuntimeControllerPanel.tsx"
  "src/components/BleHardwareRuntimePanel.tsx"
  "src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts"
)

for file in "${FILES[@]}"; do
  if has_file "$file"; then
    pass "Layer file exists: $file"
  else
    fail "Layer file missing: $file"
  fi
done

line ""
line "## 4. Android Native Telemetry"

MODULE_FILE="$(find "$ROOT/android/app/src/main" -name "MauriMeshHardwareTelemetryModule.kt" 2>/dev/null | head -1 || true)"
PACKAGE_FILE="$(find "$ROOT/android/app/src/main" -name "MauriMeshHardwareTelemetryPackage.kt" 2>/dev/null | head -1 || true)"
MAIN_FILE="$(find "$ROOT/android/app/src/main" \( -name "MainApplication.kt" -o -name "MainApplication.java" \) 2>/dev/null | head -1 || true)"

if [ -n "$MODULE_FILE" ]; then pass "Android telemetry module exists: ${MODULE_FILE#$ROOT/}"; else fail "Android telemetry module missing"; fi
if [ -n "$PACKAGE_FILE" ]; then pass "Android telemetry package exists: ${PACKAGE_FILE#$ROOT/}"; else fail "Android telemetry package missing"; fi
if [ -n "$MAIN_FILE" ]; then pass "MainApplication exists: ${MAIN_FILE#$ROOT/}"; else fail "MainApplication missing"; fi

if [ -n "$MAIN_FILE" ] && grep -Fq "MauriMeshHardwareTelemetryPackage" "$MAIN_FILE"; then
  pass "MainApplication registers telemetry package"
else
  fail "MainApplication telemetry registration missing"
fi

if [ -n "$MODULE_FILE" ]; then
  for token in BatteryManager ActivityManager StatFs PowerManager BluetoothManager getHardwareTelemetry memoryUsedMb storageFreeMb bleEnabled thermalRisk; do
    if grep -Fq "$token" "$MODULE_FILE"; then
      pass "Native telemetry capability found: $token"
    else
      fail "Native telemetry capability missing: $token"
    fi
  done
fi

line ""
line "## 5. Critical Capability Markers"

MARKERS=(
  "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts:MauriMeshHardwareTelemetry"
  "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts:NATIVE_ANDROID"
  "src/maurimesh/device-hardware/HardwareRuntimeController.ts:evaluateHardwareRuntimeController"
  "src/maurimesh/device-hardware/HardwareRuntimeController.ts:createBleRuntimeTuning"
  "src/maurimesh/device-hardware/HardwareRuntimeController.ts:createProofRuntimeTuning"
  "src/maurimesh/ble-runtime/BleHardwareRuntimeAdapter.ts:evaluateBleHardwareRuntime"
  "src/maurimesh/ble-runtime/BleHardwareRuntimeAdapter.ts:BACKUP_CONTROLLED"
  "src/maurimesh/ble-runtime/BleHardwareBackupPolicy.ts:createBleHardwareBackupPolicy"
  "src/maurimesh/intelligence/BackupIntelligence.ts:generateProtectedIntelligenceReport"
  "src/maurimesh/intelligence/BackupIntelligence.ts:forceBackupIntelligence"
  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:createHybridFallbackOrder"
)

for item in "${MARKERS[@]}"; do
  file="${item%%:*}"
  token="${item#*:}"
  if has_text "$file" "$token"; then
    pass "Marker found: $token in $file"
  else
    fail "Marker missing: $token in $file"
  fi
done

line ""
line "## 6. Truth Boundaries"

TRUTH_MARKERS=(
  "app/device-proof.tsx:APK"
  "app/native-telemetry.tsx:NativeTelemetryPanel"
  "src/maurimesh/device-hardware/NativeHardwareTelemetry.ts:cannot physically repair hardware"
  "src/maurimesh/device-hardware/HardwareRuntimeController.ts:cannot repair physical hardware"
  "src/maurimesh/ble-runtime/BleHardwareRuntimeAdapter.ts:Real BLE delivery still requires APK TX/RX/ACK logcat proof"
  "src/maurimesh/ble-runtime/BleHardwareBackupPolicy.ts:does not prove BLE delivery"
  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts:does not prove real radio delivery"
)

for item in "${TRUTH_MARKERS[@]}"; do
  file="${item%%:*}"
  token="${item#*:}"
  if has_text "$file" "$token"; then
    pass "Truth boundary found in $file"
  else
    warn "Truth boundary not confirmed in $file"
  fi
done

line ""
line "## 7. Existing Checkers"

run_checker "check-ui-available-complete.sh" "UI Available Complete"
run_checker "check-ui-backup-wiring.sh" "UI Backup Wiring"

if [ -f "$ROOT/check-ui-visual-polish.sh" ]; then
  run_checker "check-ui-visual-polish.sh" "UI Visual Polish"
else
  warn "Visual polish checker missing"
fi

run_checker "check-maurimesh-intelligence.sh" "Intelligence"
run_checker "check-maurimesh-backup-intelligence.sh" "Backup Intelligence"
run_checker "check-maurimesh-device-hardware.sh" "Device Hardware Stabilizer"
run_checker "check-maurimesh-native-telemetry.sh" "Native Telemetry JS Bridge"
run_checker "check-maurimesh-android-kotlin-telemetry.sh" "Android Kotlin Telemetry"
run_checker "check-maurimesh-hardware-runtime-controller.sh" "Hardware Runtime Controller"
run_checker "check-maurimesh-ble-hardware-runtime-backup.sh" "BLE Hardware Runtime Backup"
run_checker "check-maurimesh-hybrid-wifi-ble-mesh.sh" "Hybrid Wi-Fi BLE Mesh"

line ""
line "## 8. TypeScript Final Gate"

if npx tsc --noEmit >> "$REPORT" 2>&1; then
  pass "Final TypeScript gate passed"
else
  fail "Final TypeScript gate failed"
fi

line ""
line "## 9. Optional Android Compile Gate"

if [ -d "$ROOT/android" ] && [ -f "$ROOT/android/gradlew" ]; then
  pass "Android Gradle wrapper exists"
else
  warn "Android Gradle wrapper not found or android/ missing"
fi

line ""
line "## Final Summary"

TOTAL=$((PASS + FAIL + WARN))
if [ "$TOTAL" -gt 0 ]; then SCORE=$((PASS * 100 / TOTAL)); else SCORE=0; fi

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
  STATUS="READY_FOR_APK_BUILD"
elif [ "$FAIL" -eq 0 ]; then
  STATUS="READY_WITH_WARNINGS"
else
  STATUS="NOT_READY"
fi

line ""
line "- Total checks: $TOTAL"
line "- Complete: $PASS"
line "- Partial/warnings: $WARN"
line "- Missing/failed: $FAIL"
line "- Score: $SCORE%"
line "- Master status: **$STATUS**"
line ""

if [ "$STATUS" = "READY_FOR_APK_BUILD" ]; then
  line "✅ MauriMesh is ready for the next APK build gate."
elif [ "$STATUS" = "READY_WITH_WARNINGS" ]; then
  line "⚠️ MauriMesh has no hard failures, but warnings should be reviewed before APK proof."
else
  line "❌ MauriMesh is not ready. Fix all MISSING/failed lines first."
fi

line ""
line "## Final Truth"
line ""
line "This master checker proves Replit project wiring, TypeScript, route coverage, fallback UI, intelligence, hardware stabilisation, native telemetry module files, and BLE hardware runtime backup wiring."
line ""
line "It does not prove real BLE message delivery. Real BLE delivery requires installed APK device testing with TX/RX/ACK logcat evidence."
line ""
line "It does not prove native telemetry is active on a phone until /native-telemetry shows NATIVE_ANDROID inside the installed APK."

cp "$REPORT" "$LATEST"

cat > "$JSON" <<JSON
{
  "project": "MauriMesh Messenger",
  "timestamp": "$STAMP",
  "total_checks": $TOTAL,
  "complete": $PASS,
  "warnings": $WARN,
  "missing_or_failed": $FAIL,
  "score_percent": $SCORE,
  "master_status": "$STATUS",
  "latest_report": "$LATEST"
}
JSON

echo ""
echo "============================================================"
echo "MAURIMESH MASTER READINESS CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "JSON:   $JSON"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
