#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "PATCH DASHBOARD NATIVE BLE/GATT CARD v1"
echo "============================================================"
echo "Goal:"
echo "- Add Native BLE/GATT Proof card to Safe Dashboard"
echo "- Route: /native-ble-gatt-proof"
echo "- No proof logic changes"
echo "- No native BLE/GATT PASS claim"
echo "============================================================"

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DASH="$ROOT/app/dashboard.tsx"
BACKUP="$ROOT/backup-before-dashboard-native-ble-gatt-card-v1-$STAMP"
REPORT="$ROOT/docs/native-ble-gatt/DASHBOARD_NATIVE_BLE_GATT_CARD_V1_$STAMP.md"

mkdir -p "$BACKUP/app" "$ROOT/docs/native-ble-gatt" "$ROOT/archives"

if [ ! -f "$DASH" ]; then
  echo "FAIL: app/dashboard.tsx not found"
  exit 1
fi

cp "$DASH" "$BACKUP/app/dashboard.tsx"

if grep -q "/native-ble-gatt-proof" "$DASH"; then
  echo "PASS: dashboard already references /native-ble-gatt-proof"
else
  python3 - <<'PY'
from pathlib import Path

path = Path("app/dashboard.tsx")
text = path.read_text()

card = '''
        <RouteCard
          title="Native BLE/GATT Proof"
          href="/native-ble-gatt-proof"
          subtitle="Native callback capture gate. Does not claim packet-bound PASS."
        />
'''

# Pattern 1: insert before Learner Core card
if 'title="Learner Core"' in text:
    text = text.replace(
        '        <RouteCard\n          title="Learner Core"',
        card + '\n        <RouteCard\n          title="Learner Core"',
        1
    )
# Pattern 2: insert after Proof Vault Health card if Learner Core pattern not found
elif 'Proof Vault Health' in text:
    idx = text.find('Proof Vault Health')
    # safer fallback: insert before bottom warning if present
    marker = 'If a route crashes'
    if marker in text:
        text = text.replace(marker, card + '\n' + marker, 1)
    else:
        raise SystemExit("Could not find safe dashboard insertion point.")
# Pattern 3: array-style route list
elif 'routes' in text and '/locked-proof-vault' in text:
    marker = '/locked-proof-vault'
    insert = '''
  {
    title: "Native BLE/GATT Proof",
    href: "/native-ble-gatt-proof",
    subtitle: "Native callback capture gate. Does not claim packet-bound PASS.",
  },
'''
    pos = text.find(marker)
    # insert before locked vault block by finding previous "{"
    start = text.rfind("{", 0, pos)
    if start == -1:
        raise SystemExit("Could not patch array-style dashboard.")
    text = text[:start] + insert + text[start:]
else:
    raise SystemExit("Could not find a known dashboard card pattern. Manual patch needed.")

path.write_text(text)
print("PASS: dashboard patched with Native BLE/GATT Proof card.")
PY
fi

echo ""
echo "Running TypeScript..."
npx tsc --noEmit

cat > "$REPORT" <<MD
# Dashboard Native BLE/GATT Card v1

Generated: $STAMP

## Added

Dashboard card:

- Native BLE/GATT Proof
- /native-ble-gatt-proof

## Truth

This patch only adds dashboard navigation.

It does not claim native BLE/GATT packet-bound PASS.

Native BLE/GATT packet-bound PASS remains pending until the same packetId appears inside native BLE/GATT transport logs.

## Backup

$BACKUP
MD

tar -czf "$ROOT/archives/dashboard-native-ble-gatt-card-v1-$STAMP.tar.gz" \
  "$REPORT" "$BACKUP" "$DASH" 2>/dev/null || true

echo ""
echo "============================================================"
echo "PATCH COMPLETE"
echo "============================================================"
echo "Now rebuild APK or refresh preview, then open dashboard."
echo "Look for: Native BLE/GATT Proof"
echo "Route: /native-ble-gatt-proof"
echo "Report: $REPORT"
echo "============================================================"
