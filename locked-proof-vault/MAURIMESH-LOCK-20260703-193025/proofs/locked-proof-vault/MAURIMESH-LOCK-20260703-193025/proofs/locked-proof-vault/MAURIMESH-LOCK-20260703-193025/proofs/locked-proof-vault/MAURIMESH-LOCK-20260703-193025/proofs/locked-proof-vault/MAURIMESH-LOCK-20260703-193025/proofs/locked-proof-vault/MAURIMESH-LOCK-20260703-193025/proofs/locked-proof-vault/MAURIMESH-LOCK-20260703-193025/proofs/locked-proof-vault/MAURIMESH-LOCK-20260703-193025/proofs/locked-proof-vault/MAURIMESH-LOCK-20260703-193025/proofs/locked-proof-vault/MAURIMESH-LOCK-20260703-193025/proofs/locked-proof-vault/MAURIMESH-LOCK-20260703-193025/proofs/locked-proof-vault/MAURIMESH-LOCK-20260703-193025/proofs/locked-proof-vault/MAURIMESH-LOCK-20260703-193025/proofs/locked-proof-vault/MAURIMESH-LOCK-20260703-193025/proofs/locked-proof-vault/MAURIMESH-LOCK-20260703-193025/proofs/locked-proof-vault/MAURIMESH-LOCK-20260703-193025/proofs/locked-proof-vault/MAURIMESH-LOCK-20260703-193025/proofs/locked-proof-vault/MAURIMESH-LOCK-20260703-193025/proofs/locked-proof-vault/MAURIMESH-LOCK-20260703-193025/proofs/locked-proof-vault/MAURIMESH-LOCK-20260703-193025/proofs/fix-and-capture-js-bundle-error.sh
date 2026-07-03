#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH JS BUNDLE FAILURE FIX + CAPTURE"
echo "Target: EAS Bundle JavaScript failed"
echo "No APK build in this script."
echo "============================================================"
echo ""

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="maurimesh-js-bundle-check-$STAMP"
BACKUP="backup-before-js-bundle-fix-$STAMP"
mkdir -p "$OUT" "$BACKUP"

echo "[1] Backup app/src/package files"
cp -R app "$BACKUP/app" 2>/dev/null || true
cp -R src "$BACKUP/src" 2>/dev/null || true
cp package.json "$BACKUP/package.json" 2>/dev/null || true

echo ""
echo "[2] Ensure safe MauriPanel supports glow"
mkdir -p src/components

cat > src/components/MauriPanel.tsx <<'TSX'
import React from "react";
import {
  StyleProp,
  StyleSheet,
  Text,
  View,
  ViewStyle,
} from "react-native";

type MauriPanelProps = {
  title?: string;
  subtitle?: string;
  label?: string;
  glow?: boolean;
  children?: React.ReactNode;
  style?: StyleProp<ViewStyle>;
};

export function MauriPanel({
  title,
  subtitle,
  label,
  glow = false,
  children,
  style,
}: MauriPanelProps) {
  return (
    <View style={[styles.panel, glow && styles.glow, style]}>
      {label ? <Text style={styles.label}>{label}</Text> : null}
      {title ? <Text style={styles.title}>{title}</Text> : null}
      {subtitle ? <Text style={styles.subtitle}>{subtitle}</Text> : null}
      {children}
    </View>
  );
}

export default MauriPanel;

const styles = StyleSheet.create({
  panel: {
    width: "100%",
    borderRadius: 24,
    borderWidth: 1,
    borderColor: "rgba(34,197,94,0.28)",
    backgroundColor: "rgba(2,12,8,0.86)",
    padding: 18,
    marginVertical: 8,
  },
  glow: {
    borderColor: "rgba(0,208,132,0.72)",
    backgroundColor: "rgba(0,208,132,0.10)",
  },
  label: {
    color: "#00D084",
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 1,
    marginBottom: 8,
  },
  title: {
    color: "#FFFFFF",
    fontSize: 20,
    fontWeight: "900",
    marginBottom: 6,
  },
  subtitle: {
    color: "rgba(255,255,255,0.72)",
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 10,
  },
});
TSX

echo ""
echo "[3] Add missing MauriPanel imports everywhere"
python3 <<'PY'
from pathlib import Path

def has_mauripanel_import(text: str) -> bool:
    imports = "\n".join([l for l in text.splitlines() if l.startswith("import ")])
    return "MauriPanel" in imports

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

        if has_mauripanel_import(text):
            print(f"OK import exists: {path}")
            continue

        if path.as_posix().startswith("app/"):
            imp = 'import { MauriPanel } from "../src/components/MauriPanel";\n'
        elif path.as_posix().startswith("src/components/"):
            imp = 'import { MauriPanel } from "./MauriPanel";\n'
        else:
            imp = 'import { MauriPanel } from "../components/MauriPanel";\n'

        lines = text.splitlines(True)
        insert_at = 0
        while insert_at < len(lines) and lines[insert_at].startswith("import "):
            insert_at += 1
        lines.insert(insert_at, imp)
        path.write_text("".join(lines))
        print(f"ADDED import: {path}")
PY

echo ""
echo "[4] Verify no file uses MauriPanel without import"
python3 <<'PY'
from pathlib import Path
bad = []

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

        imports = "\n".join([l for l in text.splitlines() if l.startswith("import ")])
        if "MauriPanel" not in imports:
            bad.append(path.as_posix())

if bad:
    print("FAIL: Missing MauriPanel import in:")
    for b in bad:
        print("  " + b)
    raise SystemExit(1)

print("OK: every <MauriPanel> file imports MauriPanel")
PY

echo ""
echo "[5] Show login imports"
sed -n '1,40p' app/login.tsx | tee "$OUT/login-imports.txt"

echo ""
echo "[6] Show dashboard imports"
sed -n '1,45p' app/dashboard.tsx | tee "$OUT/dashboard-imports.txt"

echo ""
echo "[7] TypeScript check"
set +e
npx tsc --noEmit 2>&1 | tee "$OUT/typescript.log"
TS_STATUS=${PIPESTATUS[0]}
set -e

if [ "$TS_STATUS" -ne 0 ]; then
  echo ""
  echo "FAIL: TypeScript failed. Fix these before EAS."
  echo "Log: $OUT/typescript.log"
  exit 1
fi

echo ""
echo "[8] Local Expo export / JS bundle check"
set +e
npx expo export --platform android --clear 2>&1 | tee "$OUT/expo-export-android.log"
EXPORT_STATUS=${PIPESTATUS[0]}
set -e

if [ "$EXPORT_STATUS" -ne 0 ]; then
  echo ""
  echo "============================================================"
  echo "FAIL: LOCAL JS BUNDLE STILL FAILS"
  echo "============================================================"
  echo "Paste the last 120 lines below:"
  echo ""
  tail -120 "$OUT/expo-export-android.log"
  exit 1
fi

echo ""
echo "[9] Create ready marker"
mkdir -p docs
cat > docs/JS_BUNDLE_READY_FOR_EAS.md <<TXT
# MauriMesh JS Bundle Ready

Generated: $STAMP

Checks passed:
- MauriPanel safe component installed
- Missing MauriPanel imports repaired
- TypeScript passed
- Local Expo Android export passed

Next:
Run EAS build again.
TXT

echo ""
echo "============================================================"
echo "PASS: JS BUNDLE READY FOR EAS BUILD"
echo "============================================================"
echo "Now run:"
echo "npx eas-cli build --platform android --profile preview-apk --clear-cache"
echo ""
echo "Logs folder:"
echo "$OUT"
echo "Backup:"
echo "$BACKUP"
echo "============================================================"
