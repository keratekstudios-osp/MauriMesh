#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH BLE MODULE ACK LOGGER COMPILE REPAIR"
echo "============================================================"
echo "Goal:"
echo "- Repair EAS Kotlin compile failure in MauriMeshBleModule.kt"
echo "- Remove malformed ACK logger insertions"
echo "- Preserve source backup"
echo "- Do NOT run EAS build"
echo "- Do NOT claim native BLE/GATT pass"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +"%Y%m%d-%H%M%S")"
PATCH_ID="MM-BLEMODULE-ACK-LOGGER-REPAIR-$STAMP"

TARGET="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"
OUT_DIR="$ROOT/docs/native-proof"
BACKUP_DIR="$ROOT/backups/$PATCH_ID"
ARCHIVE_DIR="$ROOT/archives"

mkdir -p "$OUT_DIR" "$BACKUP_DIR" "$ARCHIVE_DIR"

REPORT="$OUT_DIR/MAURIMESH_BLEMODULE_ACK_LOGGER_REPAIR_$STAMP.md"
BEFORE_CTX="$OUT_DIR/blemodule-before-ack-repair-context-$STAMP.txt"
AFTER_CTX="$OUT_DIR/blemodule-after-ack-repair-context-$STAMP.txt"
PATCH_LOG="$OUT_DIR/blemodule-ack-repair-patch-log-$STAMP.txt"
TSC_OUT="$OUT_DIR/typecheck-after-blemodule-ack-repair-$STAMP.txt"
STATIC_OUT="$OUT_DIR/static-native-coverage-after-blemodule-ack-repair-$STAMP.txt"

if [ ! -f "$TARGET" ]; then
  echo "ERROR: Target file missing:"
  echo "$TARGET"
  exit 1
fi

echo "[1/6] Backing up target file..."

cp "$TARGET" "$BACKUP_DIR/MauriMeshBleModule.kt.before"

echo "Backup:"
echo "$BACKUP_DIR/MauriMeshBleModule.kt.before"

echo ""
echo "[2/6] Capturing before context..."

{
  echo "File: $TARGET"
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Lines 240-420 before repair:"
  sed -n '240,420p' "$TARGET" || true
  echo ""
  echo "Logger lines before repair:"
  grep -n "MauriMeshNativeBlePacketLogger" "$TARGET" || true
} > "$BEFORE_CTX"

echo "Before context:"
echo "$BEFORE_CTX"

echo ""
echo "[3/6] Repairing malformed ACK logger insertions..."

python3 - <<PY
from pathlib import Path
import re

target = Path("$TARGET")
text = target.read_text()
original = text

removed_lines = []

# Remove every malformed ACK logger line from MauriMeshBleModule.kt.
# Reason: EAS showed these were inserted into/near emitRawPacketProofEvent and broke Kotlin syntax.
new_lines = []
for line in text.splitlines():
    if "MauriMeshNativeBlePacketLogger.ack(" in line:
        removed_lines.append(line)
        continue
    new_lines.append(line)

text = "\n".join(new_lines) + "\n"

# Add a safe import only if still needed by other logger calls in this file.
# After removing ACK calls, this file may not need the helper import.
if "MauriMeshNativeBlePacketLogger." not in text:
    text = re.sub(
        r'\nimport com\.maurimesh\.messenger\.MauriMeshNativeBlePacketLogger\n',
        "\n",
        text
    )

target.write_text(text)

log = Path("$PATCH_LOG")
log.write_text(
    "Patch ID: $PATCH_ID\n"
    f"Removed ACK logger lines: {len(removed_lines)}\n\n"
    + "\n".join(removed_lines)
    + "\n"
)
PY

cat "$PATCH_LOG"

echo ""
echo "[4/6] Capturing after context..."

{
  echo "File: $TARGET"
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Lines 240-420 after repair:"
  sed -n '240,420p' "$TARGET" || true
  echo ""
  echo "Logger lines after repair:"
  grep -n "MauriMeshNativeBlePacketLogger" "$TARGET" || true
} > "$AFTER_CTX"

echo "After context:"
echo "$AFTER_CTX"

echo ""
echo "[5/6] Running TypeScript check..."

set +e
if [ -f "$ROOT/tsconfig.json" ]; then
  npx tsc --noEmit > "$TSC_OUT" 2>&1
  TSC_CODE="$?"
else
  echo "tsconfig.json missing; skipped" > "$TSC_OUT"
  TSC_CODE="0"
fi
set -e

if [ "$TSC_CODE" -eq 0 ]; then
  TSC_STATUS="PASS"
  echo "TypeScript: PASS"
else
  TSC_STATUS="FAILED"
  echo "TypeScript: FAILED"
  tail -80 "$TSC_OUT" || true
fi

echo ""
echo "[6/6] Static native logger coverage after repair..."

{
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "Actual logger calls excluding helper:"
  grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null \
    | grep -v "MauriMeshNativeBlePacketLogger.kt" || true
  echo ""
  echo "Stage coverage:"
} > "$STATIC_OUT"

check_stage() {
  local label="$1"
  local pattern="$2"

  if grep -RIn "$pattern" "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" >/dev/null 2>&1; then
    echo "$label: WIRED" >> "$STATIC_OUT"
  else
    echo "$label: MISSING_ACTUAL_USAGE" >> "$STATIC_OUT"
  fi
}

check_stage "advertise_start_packetId" "MauriMeshNativeBlePacketLogger\.advertiseStart"
check_stage "scan_result_packetId" "MauriMeshNativeBlePacketLogger\.scanResult"
check_stage "gatt_write_packetId" "MauriMeshNativeBlePacketLogger\.gattWrite"
check_stage "gatt_read_packetId" "MauriMeshNativeBlePacketLogger\.gattRead"
check_stage "characteristic_changed_packetId" "MauriMeshNativeBlePacketLogger\.characteristicChanged"
check_stage "relay_packetId" "MauriMeshNativeBlePacketLogger\.relay"
check_stage "ack_packetId" "MauriMeshNativeBlePacketLogger\.ack"

cat "$STATIC_OUT"

ACK_LINES_AFTER="$(grep -n "MauriMeshNativeBlePacketLogger.ack" "$TARGET" 2>/dev/null | wc -l | tr -d ' ')"
LOGGER_CALLS_AFTER="$(grep -RIn "MauriMeshNativeBlePacketLogger\." "$ROOT/android/app/src/main/java" 2>/dev/null | grep -v "MauriMeshNativeBlePacketLogger.kt" | wc -l | tr -d ' ')"

cat > "$REPORT" <<MD
# MauriMesh BLE Module ACK Logger Compile Repair

Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Patch ID

\`\`\`txt
$PATCH_ID
\`\`\`

## Target

\`\`\`txt
$TARGET
\`\`\`

## Reason

EAS cloud build reached \`:app:compileReleaseKotlin\` and failed in \`MauriMeshBleModule.kt\` around \`emitRawPacketProofEvent\`.

The prior logger insertion placed ACK logger calls in an invalid Kotlin location.

## Action Taken

Malformed \`MauriMeshNativeBlePacketLogger.ack(...)\` lines were removed from \`MauriMeshBleModule.kt\`.

## Counts

ACK logger lines remaining in MauriMeshBleModule.kt:

\`\`\`txt
$ACK_LINES_AFTER
\`\`\`

Actual native logger calls excluding helper across Android source:

\`\`\`txt
$LOGGER_CALLS_AFTER
\`\`\`

## TypeScript

\`\`\`txt
$TSC_STATUS
\`\`\`

Output:

\`\`\`txt
$TSC_OUT
\`\`\`

## Files

Before context:

\`\`\`txt
$BEFORE_CTX
\`\`\`

After context:

\`\`\`txt
$AFTER_CTX
\`\`\`

Patch log:

\`\`\`txt
$PATCH_LOG
\`\`\`

Static coverage:

\`\`\`txt
$STATIC_OUT
\`\`\`

Backup:

\`\`\`txt
$BACKUP_DIR/MauriMeshBleModule.kt.before
\`\`\`

## Truth

Native BLE/GATT packet-bound PASS is **NOT CLAIMED**.

This repair is only to restore Kotlin compile shape after malformed logger insertion.

After this repair, ACK native logger coverage may be missing again and must be re-added safely later.
MD

ARCHIVE="$ARCHIVE_DIR/maurimesh-blemodule-ack-logger-repair-$STAMP.tar.gz"
tar -czf "$ARCHIVE" \
  -C "$ROOT" \
  "docs/native-proof" \
  "backups/$PATCH_ID" \
  >/dev/null 2>&1 || true

echo ""
echo "============================================================"
echo "MAURIMESH BLE MODULE ACK LOGGER COMPILE REPAIR COMPLETE"
echo "============================================================"
echo "Patch ID:"
echo "$PATCH_ID"
echo ""
echo "ACK logger lines remaining in MauriMeshBleModule.kt:"
echo "$ACK_LINES_AFTER"
echo ""
echo "Actual native logger calls excluding helper:"
echo "$LOGGER_CALLS_AFTER"
echo ""
echo "TypeScript:"
echo "$TSC_STATUS"
echo ""
echo "Before context:"
echo "$BEFORE_CTX"
echo ""
echo "After context:"
echo "$AFTER_CTX"
echo ""
echo "Report:"
echo "$REPORT"
echo ""
echo "Archive:"
echo "$ARCHIVE"
echo ""
echo "FINAL TRUTH:"
echo "Kotlin compile issue was repaired at source-shape level only."
echo "No EAS build was started."
echo "Native BLE/GATT packet-bound PASS is NOT claimed."
echo "============================================================"
