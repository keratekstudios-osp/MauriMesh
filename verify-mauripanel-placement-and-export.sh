#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "VERIFY MAURIPANEL IMPORT PLACEMENT + EXPORT"
echo "No EAS build yet."
echo "============================================================"
echo ""

echo "[1] Python structural scan for bad MauriPanel import placement"
python3 <<'PY'
from pathlib import Path

bad = []

for root in ["app", "src"]:
    base = Path(root)
    if not base.exists():
        continue

    for path in base.rglob("*.tsx"):
        text = path.read_text(errors="ignore")
        lines = text.splitlines()

        inside_multiline_import = False
        multiline_start = None

        for i, line in enumerate(lines, start=1):
            stripped = line.strip()

            # Start of a multiline import block
            if stripped.startswith("import {") and not stripped.endswith(";"):
                inside_multiline_import = True
                multiline_start = i

            # MauriPanel import must NOT appear inside another import block
            if "import { MauriPanel }" in stripped and inside_multiline_import and i != multiline_start:
                bad.append((path.as_posix(), i, stripped))

            # End of multiline import block
            if inside_multiline_import and stripped.endswith(";"):
                inside_multiline_import = False
                multiline_start = None

if bad:
    print("FAIL: MauriPanel import is still inside another multiline import:")
    for path, line, text in bad:
        print(f"{path}:{line}: {text}")
    raise SystemExit(1)

print("OK: no MauriPanel import is inside another multiline import")
PY

echo ""
echo "[2] Show important headers"
echo "--- app/dashboard.tsx ---"
sed -n '1,25p' app/dashboard.tsx

echo ""
echo "--- src/components/AiPixelReconstructionPanel.tsx ---"
sed -n '1,25p' src/components/AiPixelReconstructionPanel.tsx

echo ""
echo "[3] TypeScript check"
npx tsc --noEmit

echo ""
echo "[4] Local Android JS bundle/export check"
npx expo export --platform android --clear

echo ""
echo "============================================================"
echo "PASS: LOCAL JS BUNDLE EXPORT PASSED"
echo "============================================================"
echo "Now safe to run:"
echo "npx eas-cli build --platform android --profile preview-apk --clear-cache"
echo "============================================================"
