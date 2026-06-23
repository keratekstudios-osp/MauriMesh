#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX ALL MAURIPANEL IMPORT PLACEMENT ERRORS"
echo "Cause: import inserted inside multiline import block"
echo "Target: app/ and src/"
echo "============================================================"
echo ""

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="backup-before-all-mauripanel-import-placement-$STAMP"
mkdir -p "$BACKUP"
cp -R app "$BACKUP/app" 2>/dev/null || true
cp -R src "$BACKUP/src" 2>/dev/null || true

python3 <<'PY'
from pathlib import Path

MAURI_IMPORT_PATTERNS = [
    'import { MauriPanel } from "../src/components/MauriPanel";',
    'import { MauriPanel } from "./MauriPanel";',
    'import { MauriPanel } from "../components/MauriPanel";',
    "import { MauriPanel } from '../src/components/MauriPanel';",
    "import { MauriPanel } from './MauriPanel';",
    "import { MauriPanel } from '../components/MauriPanel';",
]

def correct_import(path: Path) -> str:
    s = path.as_posix()
    if s.startswith("app/"):
        return 'import { MauriPanel } from "../src/components/MauriPanel";'
    if s.startswith("src/components/"):
        return 'import { MauriPanel } from "./MauriPanel";'
    if s.startswith("src/"):
        return 'import { MauriPanel } from "../components/MauriPanel";'
    return 'import { MauriPanel } from "../src/components/MauriPanel";'

def insert_after_import_block(lines, import_line):
    insert_at = 0
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()

        if stripped.startswith("import "):
            insert_at = i + 1

            # Handle multiline import:
            # import {
            #   A,
            # } from "...";
            if stripped.startswith("import {") and not stripped.endswith(";"):
                j = i + 1
                while j < len(lines):
                    insert_at = j + 1
                    if lines[j].strip().endswith(";"):
                        break
                    j += 1
                i = insert_at
                continue

            i += 1
            continue

        # Skip blank lines between imports.
        if stripped == "":
            insert_at = i + 1
            i += 1
            continue

        break

    return lines[:insert_at] + [import_line] + lines[insert_at:]

changed = []

for root in ["app", "src"]:
    base = Path(root)
    if not base.exists():
        continue

    for path in base.rglob("*.tsx"):
        if path.as_posix() == "src/components/MauriPanel.tsx":
            continue

        text = path.read_text(errors="ignore")
        if "<MauriPanel" not in text:
            continue

        lines = text.splitlines()

        # Remove every MauriPanel import wherever it was placed,
        # including inside a broken multiline import.
        cleaned = [
            line for line in lines
            if line.strip() not in MAURI_IMPORT_PATTERNS
        ]

        cleaned = insert_after_import_block(cleaned, correct_import(path))

        new_text = "\n".join(cleaned) + "\n"

        if new_text != text:
            path.write_text(new_text)
            changed.append(path.as_posix())

print("Changed files:")
for c in changed:
    print("  " + c)
PY

echo ""
echo "[1] Check for broken import-inside-import pattern"
if grep -RIn $'import {\nimport { MauriPanel' app src 2>/dev/null; then
  echo "FAIL: broken MauriPanel import still exists"
  exit 1
else
  echo "OK: no direct broken multiline MauriPanel pattern found"
fi

echo ""
echo "[2] Show AiPixelReconstructionPanel header"
sed -n '1,35p' src/components/AiPixelReconstructionPanel.tsx

echo ""
echo "[3] Show Dashboard header"
sed -n '1,25p' app/dashboard.tsx

echo ""
echo "[4] TypeScript check"
npx tsc --noEmit

echo ""
echo "[5] Local Android JS bundle/export check"
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "PASS: ALL MAURIPANEL IMPORT PLACEMENT FIXED"
echo "============================================================"
echo "Backup:"
echo "$BACKUP"
echo ""
echo "Now safe to run:"
echo "npx eas-cli build --platform android --profile preview-apk --clear-cache"
echo "============================================================"
