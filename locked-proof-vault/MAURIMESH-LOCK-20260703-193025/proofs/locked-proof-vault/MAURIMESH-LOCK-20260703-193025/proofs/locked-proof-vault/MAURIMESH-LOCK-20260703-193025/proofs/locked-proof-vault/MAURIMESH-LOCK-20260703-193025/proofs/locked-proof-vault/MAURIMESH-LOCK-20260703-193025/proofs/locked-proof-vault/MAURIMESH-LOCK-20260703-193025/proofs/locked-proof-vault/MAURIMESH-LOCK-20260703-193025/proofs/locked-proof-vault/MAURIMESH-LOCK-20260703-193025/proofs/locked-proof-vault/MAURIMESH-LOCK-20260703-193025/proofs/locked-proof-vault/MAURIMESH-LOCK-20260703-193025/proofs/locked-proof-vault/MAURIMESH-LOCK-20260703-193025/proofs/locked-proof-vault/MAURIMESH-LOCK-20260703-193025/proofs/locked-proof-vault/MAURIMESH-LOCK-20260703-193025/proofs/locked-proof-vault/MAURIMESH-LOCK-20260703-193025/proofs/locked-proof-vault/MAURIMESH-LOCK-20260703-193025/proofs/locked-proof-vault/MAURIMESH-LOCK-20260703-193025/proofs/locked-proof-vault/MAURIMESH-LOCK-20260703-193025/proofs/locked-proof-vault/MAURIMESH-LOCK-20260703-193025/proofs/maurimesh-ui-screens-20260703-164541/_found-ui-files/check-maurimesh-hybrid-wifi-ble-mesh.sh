#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOCS="$ROOT/docs"
mkdir -p "$DOCS"

REPORT="$DOCS/maurimesh-hybrid-wifi-ble-mesh-report-$STAMP.md"
LATEST="$DOCS/maurimesh-hybrid-wifi-ble-mesh-report-latest.md"

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

line "# MauriMesh Hybrid Wi-Fi BLE Mesh Report"
line ""
line "Generated: $STAMP"
line ""

line "## Files"
for file in \
  "src/maurimesh/hybrid-wifi-ble-mesh/HybridWifiBleMeshTypes.ts" \
  "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts" \
  "src/maurimesh/hybrid-wifi-ble-mesh/index.ts" \
  "src/components/HybridWifiBleMeshPanel.tsx" \
  "app/hybrid-wifi-ble-mesh.tsx"
do
  if has_file "$file"; then pass "$file exists"; else fail "$file missing"; fi
done

line ""
line "## Transport Capabilities"
for token in \
  "BLE_DIRECT" \
  "BLE_RELAY" \
  "STORE_FORWARD" \
  "WIFI_LOCAL" \
  "WIFI_DIRECT_READY" \
  "INTERNET_GATEWAY" \
  "OFFLINE_HOLD" \
  "createHybridFallbackOrder" \
  "decideBackupHybridWifiBleRoute" \
  "HYBRID_ROUTE_DECISION" \
  "HYBRID_FAILOVER" \
  "HYBRID_STORE_FORWARD" \
  "HYBRID_GATEWAY_READY"
do
  if grep -R "$token" "$ROOT/src/maurimesh/hybrid-wifi-ble-mesh" "$ROOT/src/components/HybridWifiBleMeshPanel.tsx" >/dev/null 2>&1; then
    pass "Capability found: $token"
  else
    fail "Capability missing: $token"
  fi
done

line ""
line "## Route Wiring"
if has_text "app/dashboard.tsx" "/hybrid-wifi-ble-mesh"; then pass "Dashboard has /hybrid-wifi-ble-mesh"; else fail "Dashboard missing /hybrid-wifi-ble-mesh"; fi
if has_text "src/lib/uiBackupRoutes.ts" "/hybrid-wifi-ble-mesh"; then pass "Backup registry has /hybrid-wifi-ble-mesh"; else fail "Backup registry missing /hybrid-wifi-ble-mesh"; fi
if has_text "app/hybrid-wifi-ble-mesh.tsx" "HybridWifiBleMeshPanel"; then pass "Screen uses HybridWifiBleMeshPanel"; else fail "Screen missing panel"; fi

line ""
line "## Embedded Wiring"
if has_file "app/mauricore-ble-runtime.tsx" && has_text "app/mauricore-ble-runtime.tsx" "HybridWifiBleMeshPanel"; then
  pass "MauriCore BLE Runtime includes HybridWifiBleMeshPanel"
else
  warn "MauriCore BLE Runtime embed not confirmed"
fi

if has_file "app/ble-hardware-runtime.tsx" && has_text "app/ble-hardware-runtime.tsx" "HybridWifiBleMeshPanel"; then
  pass "BLE Hardware Runtime includes HybridWifiBleMeshPanel"
else
  warn "BLE Hardware Runtime embed not confirmed"
fi

if has_file "app/device-proof.tsx" && has_text "app/device-proof.tsx" "HybridWifiBleMeshPanel"; then
  pass "Device Proof includes HybridWifiBleMeshPanel"
else
  warn "Device Proof embed not confirmed"
fi

line ""
line "## Truth Protection"
if has_text "src/maurimesh/hybrid-wifi-ble-mesh/BackupHybridWifiBleMeshEngine.ts" "does not prove real radio delivery"; then
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
echo "HYBRID WIFI BLE MESH CHECK COMPLETE"
echo "Status: $STATUS"
echo "Score:  $SCORE%"
echo "Report: $LATEST"
echo "============================================================"
echo ""

if [ "$FAIL" -gt 0 ]; then exit 1; fi
