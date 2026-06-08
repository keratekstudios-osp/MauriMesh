#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "#192C — CLEAN DUPLICATE KOTLIN RX/ACK EVENT BLOCKS"
echo "Removes duplicate rx_packet / ack_sent native emit calls"
echo "Keeps one RX event and one ACK event only"
echo "============================================================"
echo ""

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/maurimesh-router-backups/task-192c-clean-duplicate-kotlin-$STAMP"

FILE="$ROOT/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"

mkdir -p "$BACKUP/android/app/src/main/java/com/maurimesh/messenger" "$ROOT/scripts" "$ROOT/docs"

if [ ! -f "$FILE" ]; then
  echo "ERROR: Missing $FILE"
  exit 1
fi

cp "$FILE" "$BACKUP/android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt"

echo "Backup: $BACKUP"

echo ""
echo "1. Clean duplicate emitRawPacketProofEvent blocks"

python3 <<'PY'
from pathlib import Path

path = Path("android/app/src/main/java/com/maurimesh/messenger/MauriMeshBleModule.kt")
text = path.read_text()

def remove_duplicate_blocks(text: str, event_name: str) -> str:
    needle = f'emitRawPacketProofEvent(\n            "{event_name}"'
    first = text.find(needle)
    if first == -1:
        return text

    search_from = first + len(needle)
    while True:
        dup = text.find(needle, search_from)
        if dup == -1:
            break

        # Find end of function call block: closing line containing only "          )"
        end = text.find("\n          )", dup)
        if end == -1:
            break
        end = end + len("\n          )")

        # Remove surrounding blank lines too
        while end < len(text) and text[end] in "\n\r":
            end += 1

        text = text[:dup] + text[end:]
        search_from = first + len(needle)

    return text

text = remove_duplicate_blocks(text, "rx_packet")
text = remove_duplicate_blocks(text, "ack_sent")

path.write_text(text)
print("Duplicate Kotlin event blocks cleaned")
PY

echo ""
echo "2. Verify duplicate count"

RX_COUNT=$(grep -n '"rx_packet"' "$FILE" | wc -l | tr -d ' ')
ACK_COUNT=$(grep -n '"ack_sent"' "$FILE" | wc -l | tr -d ' ')

echo "rx_packet marker count: $RX_COUNT"
echo "ack_sent marker count: $ACK_COUNT"

if [ "$RX_COUNT" -ne 1 ] || [ "$ACK_COUNT" -ne 1 ]; then
  echo "ERROR: Expected exactly one rx_packet and one ack_sent marker."
  grep -nE 'emitRawPacketProofEvent|"rx_packet"|"ack_sent"|MauriMeshRawPacketProofEvent' "$FILE" || true
  exit 1
fi

echo "✅ Duplicate native RX/ACK emit blocks cleaned"

echo ""
echo "3. Run #192 audit"
bash scripts/audit-task-192-native-proof-event-bridge.sh

echo ""
echo "4. Run duplicate detector"
bash scripts/audit-task-192b-duplicate-native-events.sh

echo ""
echo "5. TypeScript check"
npx tsc --noEmit

echo ""
echo "6. Expo export check"
rm -rf dist .expo
npx expo export --platform android --clear

cat > "$ROOT/docs/task-192c-clean-duplicate-kotlin-events.md" <<'MD'
# Task #192C — Clean Duplicate Kotlin Native Proof Events

## Fixed

Removed duplicate native proof metric emit blocks from:

- `MauriMeshBleModule.kt`

Expected final state:

- one `rx_packet` native event emit block
- one `ack_sent` native event emit block
- one `MauriMeshRawPacketProofEvent` JS event name

## Why

Rerunning #192 created duplicate RX/ACK event calls. That could double-count proof metrics after real hardware packet receipt.

## Truth boundary

This cleanup prevents double counting. It still requires physical two-phone proof to confirm real RX/ACK delivery.
MD

echo ""
echo "============================================================"
echo "#192C DUPLICATE KOTLIN EVENT CLEANUP COMPLETE"
echo "Backup: $BACKUP"
echo "Next: build APK after this export passes."
echo "============================================================"
