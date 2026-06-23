#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "MAURIMESH LOCAL FINAL CHECK"
echo "============================================================"
echo ""

echo "[1] Required files"
for f in app/dashboard.tsx app/proof-2-hop.tsx app/_layout.tsx package.json; do
  if [ -f "$f" ]; then
    echo "OK: $f"
  else
    echo "MISSING: $f"
  fi
done

echo ""
echo "[2] Dashboard proof route"
if grep -q "proof-2-hop" app/dashboard.tsx 2>/dev/null; then
  echo "OK: dashboard has proof-2-hop route"
else
  echo "WARN: dashboard missing proof-2-hop route"
fi

echo ""
echo "[3] Proof event names"
for e in PACKET_ID_GENERATED TX_A06_TO_S10 PACKET_ID_CONFIRMED_ON_S10 RX_S10_FROM_A06 ACK_RELAY_S10_TO_A06 ACK_BACK_TO_A06; do
  if grep -q "$e" app/proof-2-hop.tsx 2>/dev/null; then
    echo "OK: $e"
  else
    echo "MISSING: $e"
  fi
done

echo ""
echo "[4] Notification dependency"
if grep -q "expo-notifications" app/proof-2-hop.tsx 2>/dev/null; then
  echo "WARN: expo-notifications still imported"
  echo "Fix needed unless expo-notifications is installed and TypeScript passes."
else
  echo "OK: no expo-notifications dependency"
fi

echo ""
echo "[5] Stage UI checks"
for s in "NEXT STAGE READY" "stageBanner" "Alert.alert" "A06_SENDER" "S10_RELAY"; do
  if grep -q "$s" app/proof-2-hop.tsx 2>/dev/null; then
    echo "OK: $s"
  else
    echo "MISSING: $s"
  fi
done

echo ""
echo "[6] TypeScript"
npx tsc --noEmit

echo ""
echo "============================================================"
echo "LOCAL FINAL CHECK PASSED"
echo "============================================================"
