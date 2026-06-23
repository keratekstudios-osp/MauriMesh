#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "PATCH VAULT DASHBOARD LABELS CLARITY v1"
echo "============================================================"
echo "Goal:"
echo "- Rename Raw Proof Vault dashboard button"
echo "- Make /locked-proof-vault clearly mean crash-safe guard"
echo "- Keep /proof-vault-health as real storage reader"
echo "- No proof logic changes"
echo "- No native BLE/GATT PASS claim"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/backup-before-vault-dashboard-labels-clarity-v1-$STAMP"
REPORT="$ROOT/docs/runtime-crash/vault-dashboard-labels-clarity-v1-$STAMP.md"
TARGET="$ROOT/app/dashboard.tsx"

mkdir -p "$BACKUP/app" "$ROOT/docs/runtime-crash"

if [ ! -f "$TARGET" ]; then
  echo "ERROR: app/dashboard.tsx not found."
  exit 1
fi

cp "$TARGET" "$BACKUP/app/dashboard.tsx"

python3 <<'PY'
from pathlib import Path

p = Path("app/dashboard.tsx")
s = p.read_text()

s = s.replace(
  'title: "Raw Proof Vault",\n    route: "/locked-proof-vault",\n    note: "Inspect stored AsyncStorage proof/vault keys",',
  'title: "Locked Proof Vault Guard",\n    route: "/locked-proof-vault",\n    note: "Crash-safe static guard route. Does not read storage.",'
)

s = s.replace(
  'title: "Proof Vault Health",\n    route: "/proof-vault-health",\n    note: "Count proof entries, bytes, packet IDs, checksum",',
  'title: "Proof Vault Health / Storage Reader",\n    route: "/proof-vault-health",\n    note: "Real local storage reader: proof entries, bytes, packet IDs, checksum.",'
)

# Add clear truth note if not present.
marker = "MAURIMESH_VAULT_LABEL_CLARITY_V1"
if marker not in s:
    s = s.replace(
      'Native BLE/GATT packet-bound PASS: not claimed</Text>',
      'Native BLE/GATT packet-bound PASS: not claimed</Text>\n        <Text style={styles.truthLine}>Vault guard: /locked-proof-vault</Text>\n        <Text style={styles.truthLine}>Storage reader: /proof-vault-health</Text>\n        {/* MAURIMESH_VAULT_LABEL_CLARITY_V1 */}'
    )

p.write_text(s)
print("Dashboard vault labels clarified.")
PY

echo ""
echo "============================================================"
echo "VERIFY LABELS"
echo "============================================================"

grep -n "Locked Proof Vault Guard\|Proof Vault Health / Storage Reader\|MAURIMESH_VAULT_LABEL_CLARITY_V1\|locked-proof-vault\|proof-vault-health" "$TARGET" || true

echo ""
echo "============================================================"
echo "VALIDATE EXPORT"
echo "============================================================"

npx expo export --platform android --clear

cat > "$REPORT" <<EOF2
# MauriMesh Vault Dashboard Labels Clarity v1

Generated: $STAMP

## Patch

Dashboard labels clarified:

- /locked-proof-vault is now labelled:
  Locked Proof Vault Guard

- /proof-vault-health is now labelled:
  Proof Vault Health / Storage Reader

## Truth

/locked-proof-vault is crash-safe static guard evidence.

/proof-vault-health is the real local AsyncStorage proof-vault reader.

Native BLE/GATT packet-bound PASS is not claimed.
EOF2

echo ""
echo "============================================================"
echo "VAULT DASHBOARD LABELS CLARITY PATCH COMPLETE"
echo "Backup: $BACKUP"
echo "Report: $REPORT"
echo "============================================================"
