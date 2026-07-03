#!/usr/bin/env bash
set -euo pipefail

SCREEN="app/native-ble-gatt-proof.tsx"
STAMP="$(date +%Y%m%d-%H%M%S)"
DOC_DIR="docs/native-ble-gatt"
ARCHIVE_DIR="archives/native-ble-gatt"
mkdir -p "$DOC_DIR" "$ARCHIVE_DIR"

cp "$SCREEN" "$ARCHIVE_DIR/native-ble-gatt-proof.tsx.before-v9-import-fix-${STAMP}.bak"

echo ""
echo "============================================================"
echo "MAURIMESH v9 IMPORT FIX"
echo "============================================================"

python3 - <<'PY'
from pathlib import Path
import re

p = Path("app/native-ble-gatt-proof.tsx")
t = p.read_text(errors="ignore")

# Fix accidental double commas in import block.
t = t.replace("View,,", "View,")
t = t.replace(",,", ",")

# Ensure TextInput appears only once in react-native import.
m = re.search(r'import\s*\{([\s\S]*?)\}\s*from\s*["\']react-native["\']\s*;', t)
if m:
    items = []
    seen = set()
    for raw in m.group(1).split(","):
        item = raw.strip()
        if not item:
            continue
        if item not in seen:
            seen.add(item)
            items.append(item)
    if "TextInput" not in seen:
        items.append("TextInput")
    new_import = "import {\n  " + ",\n  ".join(items) + ",\n} from \"react-native\";"
    t = t[:m.start()] + new_import + t[m.end():]

p.write_text(t)
print("PASS: import block repaired.")
PY

echo ""
echo "[1] Import head:"
sed -n '1,25p' "$SCREEN"

echo ""
echo "[2] Verify v9 markers:"
grep -n "MM_GATT_SHARED_PACKET_V9\|SHARED_PACKET_V9_APPLIED\|Shared Packet ID Chain Mode" "$SCREEN" || true

echo ""
echo "[3] TypeScript gate..."
npx tsc --noEmit

echo ""
echo "[4] Expo Android export gate..."
npx expo export --platform android

REPORT="$DOC_DIR/NATIVE_GATT_SHARED_PACKET_V9_IMPORT_FIX_${STAMP}.md"
cat > "$REPORT" <<EOF2
# MauriMesh Native GATT Shared Packet v9 Import Fix

Timestamp: $STAMP

Fixed bad react-native import syntax caused by duplicate comma after View.

Verdict: READY_FOR_EAS_BUILD_V9_SHARED_PACKET_MODE
EOF2

cp "$REPORT" "$DOC_DIR/NATIVE_GATT_SHARED_PACKET_V9_IMPORT_FIX_LATEST.md"

echo ""
echo "============================================================"
echo "v9 IMPORT FIX COMPLETE"
echo "============================================================"
echo "Report: $REPORT"
echo "FINAL VERDICT: READY_FOR_EAS_BUILD_V9_SHARED_PACKET_MODE"
echo "============================================================"
