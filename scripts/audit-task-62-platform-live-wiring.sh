#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "#62 PLATFORM LIVE WIRING AUDIT"
echo "============================================================"

TARGETS=(
  "artifacts/messenger-mobile/app/platform"
  "artifacts/maurimesh/src/pages/platform"
  "artifacts/maurimesh/src/pages/advanced"
)

echo ""
echo "1. Target screen counts"
for dir in "${TARGETS[@]}"; do
  if [ -d "$dir" ]; then
    count="$(find "$dir" -type f \( -name "*.tsx" -o -name "*.ts" -o -name "*.jsx" -o -name "*.js" \) | wc -l | tr -d ' ')"
    echo "$dir: $count files"
  else
    echo "$dir: MISSING"
  fi
done

echo ""
echo "2. Files with mock/static indicators"
grep -RniE "mock|Mock|MOCK|hardcoded|Hardcoded|sample|Sample|dummy|Dummy|fake|Fake|simulation|Simulation" "${TARGETS[@]}" 2>/dev/null || true

echo ""
echo "3. Files already wired to live panel"
grep -RniE "PlatformLiveMeshPanel|platformLiveMeshBridge|PLATFORM_LIVE_BLE_MESH_BRIDGE_20260608_A" "${TARGETS[@]}" artifacts/messenger-mobile/src/store artifacts/maurimesh/src 2>/dev/null || true

echo ""
echo "4. Required bridge files"
test -f artifacts/messenger-mobile/src/store/platformLiveMeshBridge.ts && echo "mobile bridge OK"
test -f artifacts/messenger-mobile/src/store/PlatformLiveMeshPanel.tsx && echo "mobile panel OK"
test -f artifacts/maurimesh/src/lib/platformLiveMeshBridge.ts && echo "web bridge OK"
test -f artifacts/maurimesh/src/components/live/PlatformLiveMeshPanel.tsx && echo "web panel OK"
test -f artifacts/api-server/platform-live-mesh-endpoint.ts && echo "api endpoint contract OK"

echo ""
echo "============================================================"
echo "#62 AUDIT COMPLETE"
echo "============================================================"
