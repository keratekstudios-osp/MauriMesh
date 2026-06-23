#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH UNIFIED SPINE VERIFY GATE v1"
echo "============================================================"
echo "Goal:"
echo "- Verify Unified Intelligence Spine files"
echo "- Verify dashboard route exists"
echo "- Run TypeScript"
echo "- Check false native BLE/GATT PASS claims"
echo "- Write final verification report"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/docs/intelligence"
ARCHIVE="$ROOT/archives"
REPORT="$OUT/UNIFIED_SPINE_VERIFY_GATE_$STAMP.md"
RAW="$OUT/UNIFIED_SPINE_VERIFY_RAW_$STAMP.txt"

mkdir -p "$OUT" "$ARCHIVE"
: > "$RAW"

PASS=0
FAIL=0
WARN=0
PENDING=0

log(){ echo "$*" | tee -a "$RAW"; }

pass(){ PASS=$((PASS+1)); log "PASS: $1"; }
fail(){ FAIL=$((FAIL+1)); log "FAIL: $1"; }
warn(){ WARN=$((WARN+1)); log "WARN: $1"; }
pending(){ PENDING=$((PENDING+1)); log "PENDING: $1"; }

check_file(){
  if [ -f "$ROOT/$1" ]; then
    pass "$1 exists"
  else
    fail "$1 missing"
  fi
}

echo "" | tee -a "$RAW"
log "Generated: $STAMP"
log "Root: $ROOT"
echo "" | tee -a "$RAW"

log "============================================================"
log "1. REQUIRED SPINE FILES"
log "============================================================"

check_file "src/maurimesh/intelligence/types.ts"
check_file "src/maurimesh/intelligence/routing/routeScoring.ts"
check_file "src/maurimesh/intelligence/resilience/selfHealing.ts"
check_file "src/maurimesh/intelligence/governance/tikangaGovernance.ts"
check_file "src/maurimesh/intelligence/proof/proofVerdict.ts"
check_file "src/maurimesh/intelligence/exam/examEngine.ts"
check_file "src/maurimesh/intelligence/spine/unifiedSpine.ts"
check_file "src/maurimesh/intelligence/audit/sourceAudit.ts"
check_file "app/maurimesh-spine-exam.tsx"
check_file "docs/intelligence/MAURIMESH_UNIFIED_INTELLIGENCE_SPINE_ARCHITECTURE.md"

echo "" | tee -a "$RAW"
log "============================================================"
log "2. DASHBOARD ROUTE CHECK"
log "============================================================"

if grep -R "/maurimesh-spine-exam" "$ROOT/app/dashboard.tsx" >/dev/null 2>&1; then
  pass "Dashboard references /maurimesh-spine-exam"
else
  warn "Dashboard route reference not found. Route file may exist, but dashboard button may be missing."
fi

echo "" | tee -a "$RAW"
log "============================================================"
log "3. SPINE LOGIC MARKER CHECK"
log "============================================================"

grep -R "route\|score\|routing" "$ROOT/src/maurimesh/intelligence/routing" >/dev/null 2>&1 \
  && pass "Routing score markers found" \
  || warn "Routing score markers not confirmed"

grep -R "heal\|recover\|resilience" "$ROOT/src/maurimesh/intelligence/resilience" >/dev/null 2>&1 \
  && pass "Self-healing/resilience markers found" \
  || warn "Self-healing markers not confirmed"

grep -R "tikanga\|manaakitanga\|kaitiakitanga\|rangatiratanga\|tapu\|noa" "$ROOT/src/maurimesh/intelligence/governance" >/dev/null 2>&1 \
  && pass "Tikanga governance markers found" \
  || warn "Tikanga governance markers not confirmed"

grep -R "proof\|verdict\|PASS\|PENDING" "$ROOT/src/maurimesh/intelligence/proof" >/dev/null 2>&1 \
  && pass "Proof verdict markers found" \
  || warn "Proof verdict markers not confirmed"

grep -R "exam\|gate\|approved\|score" "$ROOT/src/maurimesh/intelligence/exam" >/dev/null 2>&1 \
  && pass "Exam engine markers found" \
  || warn "Exam engine markers not confirmed"

grep -R "unified\|spine\|decision\|audit" "$ROOT/src/maurimesh/intelligence/spine" >/dev/null 2>&1 \
  && pass "Unified spine markers found" \
  || warn "Unified spine markers not confirmed"

echo "" | tee -a "$RAW"
log "============================================================"
log "4. NATIVE BLE/GATT TRUTH CHECK"
log "============================================================"

if grep -R "nativeBleGattPacketBoundPass.*true" "$ROOT/app" "$ROOT/src" "$ROOT/docs" "$ROOT/tools" >/dev/null 2>&1; then
  warn "Found nativeBleGattPacketBoundPass=true. Human review required before any claim."
else
  pass "No nativeBleGattPacketBoundPass=true claim found"
fi

if grep -R "Native BLE/GATT.*not claimed\|No BLE/GATT packet-bound PASS\|native.*PASS.*not claimed" "$ROOT/app" "$ROOT/docs" >/dev/null 2>&1; then
  pass "Native BLE/GATT not-claimed truth wording found"
else
  warn "Native BLE/GATT not-claimed wording not confirmed"
fi

pending "Native BLE/GATT packet-bound PASS still requires physical phone logcat evidence"

echo "" | tee -a "$RAW"
log "============================================================"
log "5. TYPESCRIPT CHECK"
log "============================================================"

TSC_LOG="$OUT/UNIFIED_SPINE_TSC_$STAMP.log"

if npx tsc --noEmit > "$TSC_LOG" 2>&1; then
  pass "TypeScript check passed"
else
  fail "TypeScript check failed. See $TSC_LOG"
fi

echo "" | tee -a "$RAW"
log "============================================================"
log "6. OPTIONAL EXPORT CHECK"
log "============================================================"

EXPORT_DIR="$ROOT/dist-spine-verify-$STAMP"
EXPORT_LOG="$OUT/UNIFIED_SPINE_EXPORT_$STAMP.log"

if npx expo export --platform android --output-dir "$EXPORT_DIR" > "$EXPORT_LOG" 2>&1; then
  pass "Expo Android export passed"
else
  warn "Expo Android export failed or warning-level issue. See $EXPORT_LOG"
fi

echo "" | tee -a "$RAW"
log "============================================================"
log "SUMMARY"
log "============================================================"
log "PASS: $PASS"
log "WARN: $WARN"
log "FAIL: $FAIL"
log "PENDING: $PENDING"

if [ "$FAIL" -eq 0 ]; then
  RESULT="PASS_READY_FOR_FRESH_APK_BUILD"
else
  RESULT="FAIL_REPAIR_BEFORE_APK_BUILD"
fi

log "RESULT: $RESULT"

cat > "$REPORT" <<MD
# MauriMesh Unified Spine Verify Gate v1

Generated: $STAMP

## Result

**$RESULT**

## Counts

| Status | Count |
|---|---:|
| PASS | $PASS |
| WARN | $WARN |
| FAIL | $FAIL |
| PENDING | $PENDING |

## Truth

Native BLE/GATT packet-bound PASS is **not claimed**.

Final native BLE/GATT PASS requires the same packetId inside native BLE/GATT transport logs from physical devices.

## Next Checklist

- [ ] Open /maurimesh-spine-exam in APK or preview
- [ ] Confirm route does not crash
- [ ] Confirm route shows routing, resilience, governance, proof, learner/exam result
- [ ] Build fresh APK only if this report says PASS_READY_FOR_FRESH_APK_BUILD
- [ ] Install fresh APK on A06, S10, and A16
- [ ] Open /native-ble-gatt-proof on phones
- [ ] Run Mac logcat capture helper
- [ ] Lock final archive with screenshots, logs, packet IDs, checksum, and vault export

## Files

- Raw verification: $RAW
- TypeScript log: $TSC_LOG
- Export log: $EXPORT_LOG
MD

tar -czf "$ARCHIVE/maurimesh-unified-spine-verify-$STAMP.tar.gz" \
  "$REPORT" "$RAW" "$TSC_LOG" "$EXPORT_LOG" 2>/dev/null || true

echo ""
echo "============================================================"
echo "VERIFY COMPLETE"
echo "============================================================"
echo "Result: $RESULT"
echo "Report: $REPORT"
echo "Archive: $ARCHIVE/maurimesh-unified-spine-verify-$STAMP.tar.gz"
echo "============================================================"

if [ "$RESULT" = "PASS_READY_FOR_FRESH_APK_BUILD" ]; then
  exit 0
else
  exit 1
fi
