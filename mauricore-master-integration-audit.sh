#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURICORE MASTER INTEGRATION AUDIT"
echo "Checks Core + Android BLE + Proof + UI + Build readiness"
echo "No code deletion. No fake proof."
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
REPORT_DIR="$ROOT/reports/mauricore"
REPORT="$REPORT_DIR/master-integration-audit-$STAMP.md"

mkdir -p "$REPORT_DIR"

if [ ! -f "$ROOT/package.json" ]; then
  echo "ERROR: Run from /home/runner/workspace"
  exit 1
fi

PASS=0
WARN=0
FAIL=0

check_file() {
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then
    echo "PASS: $label -> ${file#$ROOT/}"
    PASS=$((PASS+1))
  else
    echo "FAIL: $label missing -> ${file#$ROOT/}"
    FAIL=$((FAIL+1))
  fi
}

check_dir() {
  local label="$1"
  local dir="$2"
  if [ -d "$dir" ]; then
    echo "PASS: $label -> ${dir#$ROOT/}"
    PASS=$((PASS+1))
  else
    echo "FAIL: $label missing -> ${dir#$ROOT/}"
    FAIL=$((FAIL+1))
  fi
}

check_optional() {
  local label="$1"
  local file="$2"
  if [ -f "$file" ]; then
    echo "PASS: $label -> ${file#$ROOT/}"
    PASS=$((PASS+1))
  else
    echo "WARN: $label missing -> ${file#$ROOT/}"
    WARN=$((WARN+1))
  fi
}

echo ""
echo "1. Core folders"
check_dir "MauriCore root" "$ROOT/src/mauricore"
check_dir "MauriCore dashboard" "$ROOT/src/mauricore/dashboard"
check_dir "MauriCore proof" "$ROOT/src/mauricore/proof"
check_dir "MauriCore routing" "$ROOT/src/mauricore/routing"
check_dir "MauriCore packet" "$ROOT/src/mauricore/packet"
check_dir "MauriCore healing" "$ROOT/src/mauricore/healing"
check_dir "MauriCore culture" "$ROOT/src/mauricore/culture"
check_dir "MauriCore builder" "$ROOT/src/mauricore/builder"

echo ""
echo "2. Core files"
check_file "Core index" "$ROOT/src/mauricore/index.ts"
check_file "Governance dashboard data" "$ROOT/src/mauricore/dashboard/governanceDashboard.ts"
check_file "Governance UI screen" "$ROOT/src/mauricore/dashboard/MauriCoreGovernanceScreen.tsx"
check_file "Governance route" "$ROOT/app/mauricore-governance.tsx"
check_file "Proof ledger" "$ROOT/src/mauricore/proof/proofLedger.ts"
check_file "Routing engine" "$ROOT/src/mauricore/routing/routingEngine.ts"
check_file "Packet engine" "$ROOT/src/mauricore/packet/packetEngine.ts"
check_file "Self-healing" "$ROOT/src/mauricore/healing/selfHealing.ts"
check_file "Homeostasis" "$ROOT/src/mauricore/healing/homeostasis.ts"
check_file "Tikanga engine" "$ROOT/src/mauricore/culture/tikangaEngine.ts"
check_file "Verification gate" "$ROOT/src/mauricore/builder/verificationGate.ts"
check_file "Adapter registry" "$ROOT/src/mauricore/builder/adapterRegistry.ts"
check_file "Acceptance proof" "$ROOT/src/mauricore/acceptance/acceptanceProof.ts"
check_file "Deployment readiness" "$ROOT/src/mauricore/deployment/deploymentReadiness.ts"

echo ""
echo "3. Android native BLE files"
BLE_KT="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"
check_file "Android BLE module" "$BLE_KT"
check_optional "Android MainActivity" "$ROOT/android/app/src/main/java/com/maurimesh/messenger/MainActivity.kt"
check_optional "Android MainApplication" "$ROOT/android/app/src/main/java/com/maurimesh/messenger/MainApplication.kt"

echo ""
echo "4. Existing integration scripts"
check_optional "Task 165 active raw packet" "$ROOT/install-task-165-active-android-raw-packet.sh"
check_optional "Task 165 adaptive raw packet transport" "$ROOT/install-task-165-adaptive-raw-packet-transport.sh"
check_optional "Task 165B receiver proof" "$ROOT/install-task-165b-raw-packet-receiver-proof.sh"
check_optional "Task 182 foreground service" "$ROOT/install-task-182-maurimesh-foreground-service.sh"
check_optional "Task 189 hardware proof evidence ledger" "$ROOT/install-task-189-hardware-proof-evidence-ledger.sh"
check_optional "Task 189B real proof ledger wire" "$ROOT/install-task-189b-final-real-proof-ledger-wire.sh"
check_optional "Task 190 proof events to live metrics" "$ROOT/install-task-190-proof-events-to-live-metrics.sh"
check_optional "Task 191 all integrations bridge" "$ROOT/install-task-191-all-integrations-bridge.sh"
check_optional "Task 192 native proof event bridge" "$ROOT/install-task-192-native-proof-event-bridge.sh"
check_optional "Task 223 native attestation" "$ROOT/install-task-223-auto-proof-scope-native-attestation.sh"
check_optional "Task 62 platform live BLE bridge" "$ROOT/install-task-62-platform-live-ble-mesh-bridge.sh"

echo ""
echo "5. Dashboard and route wiring"
check_file "Dashboard" "$ROOT/app/dashboard.tsx"

if grep -q "mauricore-governance" "$ROOT/app/dashboard.tsx"; then
  echo "PASS: Dashboard routes to MauriCore Governance"
  PASS=$((PASS+1))
else
  echo "FAIL: Dashboard missing MauriCore Governance route"
  FAIL=$((FAIL+1))
fi

if grep -q "MauriCore Governance" "$ROOT/app/dashboard.tsx"; then
  echo "PASS: Dashboard label exists"
  PASS=$((PASS+1))
else
  echo "FAIL: Dashboard label missing"
  FAIL=$((FAIL+1))
fi

echo ""
echo "6. Native event checks"
if [ -f "$BLE_KT" ]; then
  RX_COUNT=$(grep -c '"rx_packet"' "$BLE_KT" || true)
  ACK_COUNT=$(grep -c '"ack_sent"' "$BLE_KT" || true)
  EVENT_COUNT=$(grep -c 'MauriMeshRawPacketProofEvent' "$BLE_KT" || true)

  echo "rx_packet count: $RX_COUNT"
  echo "ack_sent count: $ACK_COUNT"
  echo "MauriMeshRawPacketProofEvent count: $EVENT_COUNT"

  if [ "$RX_COUNT" -eq 1 ]; then PASS=$((PASS+1)); else WARN=$((WARN+1)); fi
  if [ "$ACK_COUNT" -eq 1 ]; then PASS=$((PASS+1)); else WARN=$((WARN+1)); fi
  if [ "$EVENT_COUNT" -ge 1 ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
fi

echo ""
echo "7. Rust status"
if [ -d "$ROOT/rust/mauricore" ]; then
  echo "PASS: Rust scaffold exists"
  PASS=$((PASS+1))
else
  echo "WARN: Rust scaffold missing"
  WARN=$((WARN+1))
fi

if command -v cargo >/dev/null 2>&1; then
  echo "PASS: Cargo installed"
  PASS=$((PASS+1))
else
  echo "WARN: Cargo not installed. Rust remains scaffold-only."
  WARN=$((WARN+1))
fi

echo ""
echo "8. TypeScript check"
set +e
npm run mauricore:check > "$REPORT_DIR/typescript-audit-$STAMP.log" 2>&1
TS_EXIT=$?
set -e
cat "$REPORT_DIR/typescript-audit-$STAMP.log"
if [ "$TS_EXIT" -eq 0 ]; then
  echo "PASS: TypeScript check"
  PASS=$((PASS+1))
else
  echo "FAIL: TypeScript check"
  FAIL=$((FAIL+1))
fi

echo ""
echo "9. MauriCore smoke test"
set +e
npm run mauricore:test > "$REPORT_DIR/smoke-audit-$STAMP.log" 2>&1
SMOKE_EXIT=$?
set -e
cat "$REPORT_DIR/smoke-audit-$STAMP.log"
if [ "$SMOKE_EXIT" -eq 0 ]; then
  echo "PASS: MauriCore smoke test"
  PASS=$((PASS+1))
else
  echo "FAIL: MauriCore smoke test"
  FAIL=$((FAIL+1))
fi

echo ""
echo "10. Expo Android export check"
set +e
npx expo export --platform android --output-dir dist-master-integration-audit > "$REPORT_DIR/expo-export-audit-$STAMP.log" 2>&1
EXPORT_EXIT=$?
set -e
cat "$REPORT_DIR/expo-export-audit-$STAMP.log"
if [ "$EXPORT_EXIT" -eq 0 ]; then
  echo "PASS: Expo Android export"
  PASS=$((PASS+1))
else
  echo "FAIL: Expo Android export"
  FAIL=$((FAIL+1))
fi

cat > "$REPORT" <<MD
# MauriCore Master Integration Audit

Timestamp: $STAMP

## Results

- PASS: $PASS
- WARN: $WARN
- FAIL: $FAIL

## Key Rules

- Do not delete existing BLE/router/ACK/store-forward systems.
- Do not claim Replit simulation as live BLE.
- Real BLE proof requires APK on physical phones.
- Rust remains scaffold-only until Cargo and bridge proof pass.

## Next Integration Target

MauriCore Android BLE Runtime Bridge:

MauriCore routing decision
→ Android MauriMeshBleModule
→ RX/TX packet event
→ ACK event
→ Proof ledger
→ Living memory
→ Governance dashboard

## Report Logs

- TypeScript: reports/mauricore/typescript-audit-$STAMP.log
- Smoke: reports/mauricore/smoke-audit-$STAMP.log
- Expo export: reports/mauricore/expo-export-audit-$STAMP.log
MD

echo ""
cat "$REPORT"

echo ""
echo "============================================================"
echo "MASTER INTEGRATION AUDIT COMPLETE"
echo "Report: ${REPORT#$ROOT/}"
echo "============================================================"

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: BLOCKED — fix FAIL items before deeper integration."
  exit 1
else
  echo "RESULT: READY — safe to proceed to integration bridge."
fi
