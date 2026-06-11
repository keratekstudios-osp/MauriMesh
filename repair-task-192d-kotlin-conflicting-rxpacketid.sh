#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#192D — FIX KOTLIN CONFLICTING rxPacketId DECLARATIONS"
echo "Repairs EAS compileReleaseKotlin failure"
echo "Keeps exactly one rx_packet emit and one ack_sent emit"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-192d-kotlin-rxpacketid-$STAMP"

FILE="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"

mkdir -p "$BACKUP/android/app/src/main/java/com/maurimesh/messenger" "$ROOT/scripts" "$ROOT/docs"

if [ ! -f "$FILE" ]; then
  echo "ERROR: Missing $FILE"
  exit 1
fi

cp "$FILE" "$BACKUP/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"

echo "Backup: $BACKUP"

echo ""
echo "1. Current duplicate markers before repair"
grep -nE 'val rxPacketId|\"rx_packet\"|\"ack_sent\"|emitRawPacketProofEvent|MauriMeshRawPacketProofEvent' "$FILE" || true

echo ""
echo "2. Remove duplicate rxPacketId / rx_packet / ack_sent blocks"

python3 <<'PY'
from pathlib import Path
import re

path = Path("android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt")
text = path.read_text()

def keep_first_remove_rest(text: str, pattern: re.Pattern, label: str) -> str:
    matches = list(pattern.finditer(text))
    print(f"{label} blocks found:", len(matches))

    if len(matches) <= 1:
        return text

    keep = matches[0].group(0)
    rebuilt = []
    last = 0
    kept_once = False

    for m in matches:
        rebuilt.append(text[last:m.start()])
        if not kept_once:
            rebuilt.append(keep)
            kept_once = True
        else:
            print(f"Removing duplicate {label} block at char {m.start()}")
        last = m.end()

    rebuilt.append(text[last:])
    return "".join(rebuilt)

# Matches:
#   val rxPacketId = extractPacketIdFromBytes(event.bytes)
#   emitRawPacketProofEvent(
#     "rx_packet",
#     ...
#   )
rx_block = re.compile(
    r'\n\s*val rxPacketId = extractPacketIdFromBytes\(event\.bytes\)\s*\n'
    r'\s*emitRawPacketProofEvent\(\s*\n'
    r'\s*"rx_packet",\s*\n'
    r'(?:.*?\n)*?'
    r'\s*\)',
    re.MULTILINE,
)

# Matches:
#   emitRawPacketProofEvent(
#     "ack_sent",
#     ...
#   )
ack_block = re.compile(
    r'\n\s*emitRawPacketProofEvent\(\s*\n'
    r'\s*"ack_sent",\s*\n'
    r'(?:.*?\n)*?'
    r'\s*\)',
    re.MULTILINE,
)

text = keep_first_remove_rest(text, rx_block, "rx_packet")
text = keep_first_remove_rest(text, ack_block, "ack_sent")

# Safety cleanup: if any standalone duplicate rxPacketId declarations remain, keep first only.
lines = text.splitlines()
out = []
rx_seen = 0
for line in lines:
    if "val rxPacketId = extractPacketIdFromBytes(event.bytes)" in line:
        rx_seen += 1
        if rx_seen > 1:
            print("Removing standalone duplicate rxPacketId declaration:", line.strip())
            continue
    out.append(line)

text = "\n".join(out) + "\n"

path.write_text(text)
PY

echo ""
echo "3. Verify exact counts after repair"

RX_VAL_COUNT=$(grep -n 'val rxPacketId = extractPacketIdFromBytes(event.bytes)' "$FILE" | wc -l | tr -d ' ')
RX_EVENT_COUNT=$(grep -n '"rx_packet"' "$FILE" | wc -l | tr -d ' ')
ACK_EVENT_COUNT=$(grep -n '"ack_sent"' "$FILE" | wc -l | tr -d ' ')
EVENT_NAME_COUNT=$(grep -n 'MauriMeshRawPacketProofEvent' "$FILE" | wc -l | tr -d ' ')

echo "rxPacketId declaration count: $RX_VAL_COUNT"
echo "rx_packet emit count: $RX_EVENT_COUNT"
echo "ack_sent emit count: $ACK_EVENT_COUNT"
echo "native event name count: $EVENT_NAME_COUNT"

if [ "$RX_VAL_COUNT" -ne 1 ]; then
  echo "ERROR: Expected exactly one rxPacketId declaration."
  grep -nE 'val rxPacketId|\"rx_packet\"|\"ack_sent\"|emitRawPacketProofEvent' "$FILE" || true
  exit 1
fi

if [ "$RX_EVENT_COUNT" -ne 1 ]; then
  echo "ERROR: Expected exactly one rx_packet event."
  grep -nE 'val rxPacketId|\"rx_packet\"|\"ack_sent\"|emitRawPacketProofEvent' "$FILE" || true
  exit 1
fi

if [ "$ACK_EVENT_COUNT" -ne 1 ]; then
  echo "ERROR: Expected exactly one ack_sent event."
  grep -nE 'val rxPacketId|\"rx_packet\"|\"ack_sent\"|emitRawPacketProofEvent' "$FILE" || true
  exit 1
fi

echo "✅ Kotlin duplicate declarations cleaned"

echo ""
echo "4. Show repaired Kotlin proof-event area"
grep -nE 'val rxPacketId|\"rx_packet\"|\"ack_sent\"|emitRawPacketProofEvent|MauriMeshRawPacketProofEvent' "$FILE" || true

echo ""
echo "5. Run TypeScript check"
npx tsc --noEmit

echo ""
echo "6. Run Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

cat > "$ROOT/docs/task-192d-kotlin-rxpacketid-repair.md" <<'MD'
# Task #192D — Kotlin rxPacketId Conflict Repair

## Fixed

EAS release build failed at:

- `:app:compileReleaseKotlin`
- duplicate local declaration: `val rxPacketId: String`

Cause:
- #192 native proof event patch was applied more than once.
- This created duplicate RX/ACK emit blocks inside `MauriMeshBleModule.kt`.

Expected final native state:

- exactly one `val rxPacketId = extractPacketIdFromBytes(event.bytes)`
- exactly one `"rx_packet"` emit block
- exactly one `"ack_sent"` emit block
- native event name remains `MauriMeshRawPacketProofEvent`

## Truth boundary

This fixes native compilation. Physical proof still requires a two-phone RX/ACK run after the APK builds.
MD

echo ""
echo "============================================================"
echo "#192D KOTLIN rxPacketId REPAIR COMPLETE"
echo "Backup: $BACKUP"
echo ""
echo "Next build command:"
echo "npx --yes eas-cli@latest build --platform android --profile preview-apk --clear-cache"
echo "============================================================"
