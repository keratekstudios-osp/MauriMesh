#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FINISH BLEMODULE ACK REPAIR + INSPECT KOTLIN SHAPE"
echo "============================================================"
echo "Goal:"
echo "- Finish report after previous repair"
echo "- Inspect emitRawPacketProofEvent shape"
echo "- Confirm bad ACK logger lines are gone"
echo "- Do NOT start EAS build"
echo "- Do NOT claim native BLE/GATT pass"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
TARGET="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"
OUT_DIR="$ROOT/docs/native-proof"
mkdir -p "$OUT_DIR" "$ROOT/archives"

REPORT="$OUT_DIR/FINISH_BLEMODULE_ACK_REPAIR_AND_SHAPE_INSPECT_$STAMP.md"
SHAPE_OUT="$OUT_DIR/blemodule-emitRawPacketProofEvent-shape-$STAMP.txt"
COVERAGE_OUT="$OUT_DIR/native-ble-gatt-coverage-after-ack-repair-finish-$STAMP.txt"

if [ ! -f "$TARGET" ]; then
  echo "ERROR: missing target:"
  echo "$TARGET"
  exit 1
fi

echo "[1/4] Inspecting function/call shape..."

python3 - <<PY > "$SHAPE_OUT"
from pathlib import Path

p = Path("$TARGET")
lines = p.read_text().splitlines()

print("File:", p)
print("Generated shape inspection")
print()

print("All emitRawPacketProofEvent references:")
for i, line in enumerate(lines, start=1):
    if "emitRawPacketProofEvent" in line:
        print(f"{i}: {line}")

print()
print("Context around function declaration/reference zone 240-420:")
for i in range(240, min(420, len(lines)) + 1):
    print(f"{i}: {lines[i-1]}")

print()
print("Bad ACK logger lines remaining:")
found = False
for i, line in enumerate(lines, start=1):
    if "MauriMeshNativeBlePacketLogger.ack" in line:
        found = True
        print(f"{i}: {line}")
if not found:
    print("NONE")

print()
print("Other native logger lines in this file:")
found = False
for i, line in enumerate(lines, start=1):
    if "MauriMeshNativeBlePacketLogger" in line:
        found = True
        print(f"{i}: {line}")
if not found:
    print("NONE")
PY

cat "$SHAPE_OUT"

echo ""
echo "[2/4] Checking static native logger coverage..."

{
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Actual logger calls excluding helper:"
  grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null \
    | grep -v "MauriMeshNativeBlePacketLogger.kt" || true
  echo ""
  echo "Stage coverage:"
} > "$COVERAGE_OUT"

check_stage() {
  local label="$1"
  local pattern="$2"

  if grep -RIn "$pattern" "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" >/dev/null 2>&1; then
    echo "$label: WIRED" >> "$COVERAGE_OUT"
  else
    echo "$label: MISSING_ACTUAL_USAGE" >> "$COVERAGE_OUT"
  fi
}

check_stage "advertise_start_packetId" "MauriMeshNativeBlePacketLogger\.advertiseStart"
check_stage "scan_result_packetId" "MauriMeshNativeBlePacketLogger\.scanResult"
check_stage "gatt_write_packetId" "MauriMeshNativeBlePacketLogger\.gattWrite"
check_stage "gatt_read_packetId" "MauriMeshNativeBlePacketLogger\.gattRead"
check_stage "characteristic_changed_packetId" "MauriMeshNativeBlePacketLogger\.characteristicChanged"
check_stage "relay_packetId" "MauriMeshNativeBlePacketLogger\.relay"
check_stage "ack_packetId" "MauriMeshNativeBlePacketLogger\.ack"

cat "$COVERAGE_OUT"

echo ""
echo "[3/4] Checking obvious broken Kotlin tokens near function..."

BAD_ACK_LINES="$(grep -n "MauriMeshNativeBlePacketLogger.ack" "$TARGET" 2>/dev/null || true)"
BAD_FUNCTION_NO_BODY="$(grep -n "private fun emitRawPacketProofEvent" "$TARGET" 2>/dev/null || true)"
LOGGER_CALLS_AFTER="$(grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" || true)"

if [ -z "$BAD_ACK_LINES" ]; then
  ACK_REPAIR_STATUS="BAD_ACK_LINES_REMOVED"
else
  ACK_REPAIR_STATUS="BAD_ACK_LINES_STILL_PRESENT"
fi

echo "ACK repair status:"
echo "$ACK_REPAIR_STATUS"

echo ""
echo "[4/4] Writing report..."

cat > "$REPORT" <<MD
# Finish BLE Module ACK Repair + Shape Inspect

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Target

\`\`\`txt
$TARGET
\`\`\`

## ACK Repair Status

\`\`\`txt
$ACK_REPAIR_STATUS
\`\`\`

## Function Shape Inspection

\`\`\`txt
$SHAPE_OUT
\`\`\`

## Static Coverage

\`\`\`txt
$COVERAGE_OUT
\`\`\`

## Current Truth

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.

The malformed ACK logger lines were removed from \`MauriMeshBleModule.kt\`.

Current known actual native logger coverage is reduced to the safe existing \`gattWrite\` logger in \`MeshCentralClient.kt\`.

ACK logging must be re-added later only inside a valid Kotlin function body, not inside a function declaration/signature.

## Next Correct Step

If the shape inspection shows \`emitRawPacketProofEvent\` has a normal function body again, run an EAS compile check.

If it still looks malformed, patch the exact function declaration manually before another EAS build.
MD

ARCHIVE="$ROOT/archives/finish-blemodule-ack-repair-shape-inspect-$STAMP.tar.gz"
tar -czf "$ARCHIVE" -C "$ROOT" "docs/native-proof" >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "FINISH BLEMODULE ACK REPAIR + SHAPE INSPECT COMPLETE"
echo "============================================================"
echo "ACK repair status:"
echo "$ACK_REPAIR_STATUS"
echo ""
echo "Shape:"
echo "$SHAPE_OUT"
echo ""
echo "Coverage:"
echo "$COVERAGE_OUT"
echo ""
echo "Report:"
echo "$REPORT"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "No EAS build was started."
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"
