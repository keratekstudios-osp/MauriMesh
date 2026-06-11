#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX MAURIMESH JS BUNDLE DUPLICATE IMPORT"
echo "Fixes duplicate OneRealDeviceApkProofPlan import that breaks"
echo "Expo/EAS Bundle JavaScript phase."
echo "============================================================"
echo ""

ROOT="$(pwd)"
FILE="$ROOT/src/maurimesh/test-layer/MauriMeshFullTestEngine.ts"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-js-bundle-duplicate-import-fix-$STAMP"
REPORT="$ROOT/docs/maurimesh-js-bundle-fix-report-$STAMP.md"
LATEST="$ROOT/docs/maurimesh-js-bundle-fix-report-latest.md"

mkdir -p "$BACKUP" "$ROOT/docs"

if [ ! -f "$FILE" ]; then
  echo "ERROR: Missing file:"
  echo "$FILE"
  exit 1
fi

cp "$FILE" "$BACKUP/MauriMeshFullTestEngine.ts"

cat > "$ROOT/fix-duplicate-import.py" <<'PY'
from pathlib import Path

p = Path("src/maurimesh/test-layer/MauriMeshFullTestEngine.ts")
src = p.read_text()

# Fix the exact duplicate import line caused by running upgrade script twice.
src = src.replace(
    "  ThreeHopBleProofPlan,\n  OneRealDeviceApkProofPlan,\n  OneRealDeviceApkProofPlan,\n} from \"./MauriMeshTestTypes\";",
    "  ThreeHopBleProofPlan,\n  OneRealDeviceApkProofPlan,\n} from \"./MauriMeshTestTypes\";",
)

# More defensive cleanup: inside the import block from MauriMeshTestTypes,
# keep each imported symbol once.
start = src.find("import {\n")
end_marker = "} from \"./MauriMeshTestTypes\";"
end = src.find(end_marker)

if start != -1 and end != -1:
    block = src[start:end + len(end_marker)]
    if "from \"./MauriMeshTestTypes\"" in block:
        lines = block.splitlines()
        names = []
        for line in lines[1:-1]:
            name = line.strip().rstrip(",")
            if name and name not in names:
                names.append(name)
        rebuilt = "import {\n" + "\n".join(f"  {name}," for name in names) + "\n} from \"./MauriMeshTestTypes\";"
        src = src[:start] + rebuilt + src[end + len(end_marker):]

p.write_text(src)
PY

python3 "$ROOT/fix-duplicate-import.py"
rm -f "$ROOT/fix-duplicate-import.py"

echo "# MauriMesh JS Bundle Duplicate Import Fix" > "$REPORT"
echo "" >> "$REPORT"
echo "Generated: $STAMP" >> "$REPORT"
echo "" >> "$REPORT"

echo "## Import Header" >> "$REPORT"
sed -n '1,16p' "$FILE" >> "$REPORT"

echo "" >> "$REPORT"
echo "## Duplicate Count" >> "$REPORT"
COUNT="$(grep -n "OneRealDeviceApkProofPlan" "$FILE" | wc -l | tr -d ' ')"
echo "- OneRealDeviceApkProofPlan line count: $COUNT" >> "$REPORT"

echo ""
echo "Running TypeScript..."
if npx tsc --noEmit >> "$REPORT" 2>&1; then
  echo "- [x] TypeScript passed" >> "$REPORT"
else
  echo "- [ ] TypeScript failed" >> "$REPORT"
  cat "$REPORT"
  exit 1
fi

echo ""
echo "Running test-layer checker..."
if ./check-maurimesh-test-layer.sh >> "$REPORT" 2>&1; then
  echo "- [x] Test layer checker passed" >> "$REPORT"
else
  echo "- [ ] Test layer checker failed" >> "$REPORT"
  cat "$REPORT"
  exit 1
fi

echo ""
echo "Running Expo Android export to reproduce EAS bundle phase..."
EXPORT_DIR="$ROOT/.maurimesh-export-after-js-fix-$STAMP"
rm -rf "$EXPORT_DIR"

if NODE_ENV=production npx expo export --platform android --output-dir "$EXPORT_DIR" >> "$REPORT" 2>&1; then
  echo "- [x] Expo Android JS bundle export passed" >> "$REPORT"
  STATUS="READY_FOR_EAS_BUILD"
else
  echo "- [ ] Expo Android JS bundle export failed" >> "$REPORT"
  echo "" >> "$REPORT"
  echo "## Last 160 export lines" >> "$REPORT"
  NODE_ENV=production npx expo export --platform android --output-dir "$EXPORT_DIR" 2>&1 | tail -160 >> "$REPORT" || true
  STATUS="STILL_BLOCKED"
fi

echo "" >> "$REPORT"
echo "## Status" >> "$REPORT"
echo "$STATUS" >> "$REPORT"

cp "$REPORT" "$LATEST"

cat "$REPORT"

echo ""
echo "============================================================"
echo "JS BUNDLE FIX COMPLETE"
echo "Status: $STATUS"
echo "Backup:"
echo "  $BACKUP"
echo "Report:"
echo "  $LATEST"
echo "============================================================"

if [ "$STATUS" != "READY_FOR_EAS_BUILD" ]; then
  exit 1
fi
