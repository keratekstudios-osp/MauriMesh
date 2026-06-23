#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH FIX: MAURIPANEL DASHBOARD CRASH"
echo "Cause: React element undefined inside MauriPanel"
echo "Target: replace MauriPanel with safe React Native-only component"
echo "No BLE changes. No proof deletion."
echo "============================================================"
echo ""

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="backup-before-mauripanel-fix-$STAMP"
mkdir -p "$BACKUP"

echo "[1] Find MauriPanel references"
grep -RIl "MauriPanel" app src 2>/dev/null | tee "$BACKUP/mauripanel-files.txt" || true

echo ""
echo "[2] Backup matched files"
while IFS= read -r f; do
  [ -f "$f" ] || continue
  mkdir -p "$BACKUP/$(dirname "$f")"
  cp "$f" "$BACKUP/$f"
done < "$BACKUP/mauripanel-files.txt"

echo ""
echo "[3] Create safe MauriPanel component"
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
  children?: React.ReactNode;
  style?: StyleProp<ViewStyle>;
};

export function MauriPanel({
  title,
  subtitle,
  label,
  children,
  style,
}: MauriPanelProps) {
  return (
    <View style={[styles.panel, style]}>
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
echo "[4] Repair bad local MauriPanel definitions if present"
python3 <<'PY'
from pathlib import Path
import re

targets = []
for root in ["app", "src"]:
    p = Path(root)
    if p.exists():
        targets += list(p.rglob("*.tsx"))

safe_import = 'import { MauriPanel } from "../src/components/MauriPanel";\n'

for path in targets:
    text = path.read_text(errors="ignore")
    if "MauriPanel" not in text:
        continue

    original = text

    # If dashboard uses MauriPanel but does not import it from safe file, add safe import.
    if path.as_posix() == "app/dashboard.tsx":
        if "src/components/MauriPanel" not in text and "../src/components/MauriPanel" not in text:
            lines = text.splitlines(True)
            insert_at = 0
            while insert_at < len(lines) and lines[insert_at].startswith("import "):
                insert_at += 1
            lines.insert(insert_at, safe_import)
            text = "".join(lines)

    # Remove common broken imports from icon libraries only if they include MauriPanel-related symbols.
    # This avoids deleting route/proof logic.
    text = re.sub(
        r'import\s+\{([^}]*MauriPanel[^}]*)\}\s+from\s+["\'][^"\']+["\'];?\n',
        '',
        text,
    )

    if text != original:
        path.write_text(text)
        print(f"patched import: {path}")

PY

echo ""
echo "[5] Check for undefined/icon imports likely causing this"
echo "These are only warnings:"
grep -RIn "from ['\"]lucide-react-native['\"]\|from ['\"]@expo/vector-icons['\"]\|LinearGradient\|BlurView\|MauriPanel" app src 2>/dev/null | head -120 || true

echo ""
echo "[6] TypeScript check"
if command -v npx >/dev/null 2>&1; then
  npx tsc --noEmit || true
else
  echo "npx not found; skipping TypeScript check"
fi

echo ""
echo "============================================================"
echo "FIX INSTALLED"
echo "============================================================"
echo "Changed:"
echo "  src/components/MauriPanel.tsx"
echo ""
echo "Backup:"
echo "  $BACKUP"
echo ""
echo "Next:"
echo "  1. Build/install next APK"
echo "  2. Open Dashboard"
echo "  3. Crash should be gone if MauriPanel was the only undefined element"
echo "============================================================"
