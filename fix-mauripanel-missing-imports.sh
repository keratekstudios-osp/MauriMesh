#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX MAURIPANEL MISSING IMPORTS"
echo "Crash: ReferenceError Property 'MauriPanel' doesn't exist"
echo "Target: app/login.tsx + every file using <MauriPanel>"
echo "============================================================"
echo ""

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="backup-before-mauripanel-import-fix-$STAMP"
mkdir -p "$BACKUP"

echo "[1] Backup app/src"
mkdir -p "$BACKUP/app" "$BACKUP/src"
cp -R app "$BACKUP/" 2>/dev/null || true
cp -R src "$BACKUP/" 2>/dev/null || true

echo ""
echo "[2] Upgrade MauriPanel props to accept glow safely"
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
echo "[3] Add missing MauriPanel imports to every TSX file using <MauriPanel>"
python3 <<'PY'
from pathlib import Path

def rel_import(from_file: Path, target: Path) -> str:
    # Make simple project-safe imports for known roots
    p = from_file.as_posix()
    if p.startswith("app/"):
        return "../src/components/MauriPanel"
    if p.startswith("src/components/"):
        return "./MauriPanel"
    if p.startswith("src/"):
        return "../components/MauriPanel"
    return "../src/components/MauriPanel"

target = Path("src/components/MauriPanel.tsx")

for root in ["app", "src"]:
    base = Path(root)
    if not base.exists():
        continue

    for path in base.rglob("*.tsx"):
        text = path.read_text(errors="ignore")

        if "<MauriPanel" not in text:
            continue

        if path == target:
            continue

        if "MauriPanel" in text and "components/MauriPanel" in text:
            print(f"OK import exists: {path}")
            continue

        if "from \"./MauriPanel\"" in text or "from '../components/MauriPanel'" in text or "from \"../components/MauriPanel\"" in text or "from '../src/components/MauriPanel'" in text or "from \"../src/components/MauriPanel\"" in text:
            print(f"OK import exists: {path}")
            continue

        imp = f'import {{ MauriPanel }} from "{rel_import(path, target)}";\n'

        lines = text.splitlines(True)
        insert_at = 0
        while insert_at < len(lines) and lines[insert_at].startswith("import "):
            insert_at += 1
        lines.insert(insert_at, imp)

        path.write_text("".join(lines))
        print(f"ADDED import: {path}")

PY

echo ""
echo "[4] Show Login imports"
sed -n '1,50p' app/login.tsx

echo ""
echo "[5] Show Dashboard imports"
sed -n '1,35p' app/dashboard.tsx

echo ""
echo "[6] Verify all files using MauriPanel have an import"
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
        if "<MauriPanel" in text and "MauriPanel" not in "\n".join([l for l in text.splitlines() if l.startswith("import ")]):
            bad.append(path.as_posix())

if bad:
    print("FAIL: these files use <MauriPanel> but have no import:")
    for b in bad:
        print(b)
    raise SystemExit(1)

print("OK: every file using <MauriPanel> has an import")
PY

echo ""
echo "[7] TypeScript check"
npx tsc --noEmit

echo ""
echo "============================================================"
echo "PASS: MAURIPANEL IMPORT CRASH FIXED IN SOURCE"
echo "============================================================"
echo "Backup:"
echo "$BACKUP"
echo ""
echo "Next:"
echo "Build a fresh APK again, then install/test A06."
echo "============================================================"
