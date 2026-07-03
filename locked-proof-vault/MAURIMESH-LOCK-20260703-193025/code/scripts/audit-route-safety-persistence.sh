#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "ROUTE SAFETY PERSISTENCE AUDIT"
echo "============================================================"

echo ""
echo "1. Required mobile files"
test -f artifacts/messenger-mobile/lib/mesh/MeshRouteSafetyGuard.ts && echo "Mobile guard OK"
test -f artifacts/messenger-mobile/lib/mesh/MeshRouteSafetyBlacklistStore.ts && echo "Mobile blacklist store OK"

echo ""
echo "2. Required server files"
test -f artifacts/api-server/src/runtime/RouteSafetyEngine.ts && echo "Server engine OK"
test -f artifacts/api-server/src/runtime/RouteSafetyBlacklistStore.ts && echo "Server blacklist store OK"

echo ""
echo "3. Mobile persistence markers"
grep -RniE "ROUTE_SAFETY_PERSISTENCE_MOBILE|loadActiveRouteBlacklistEntries|saveRouteBlacklistEntry|hydratePersistentBlacklist|persistRouteBlacklistEntry" \
  artifacts/messenger-mobile/lib/mesh 2>/dev/null || true

echo ""
echo "4. Server persistence markers"
grep -RniE "ROUTE_SAFETY_PERSISTENCE_SERVER|loadActiveRouteBlacklistEntries|saveRouteBlacklistEntry|hydratePersistentBlacklist|persistRouteBlacklistEntry" \
  artifacts/api-server/src/runtime 2>/dev/null || true

echo ""
echo "5. DB schema"
grep -RniE "routeSafetyBlacklist|route_safety_blacklist" lib/db/src/schema 2>/dev/null || true

echo ""
echo "6. Seen-cache persistence check"
grep -RniE "seenPackets|seenCache|duplicate" artifacts/messenger-mobile/lib/mesh artifacts/api-server/src/runtime 2>/dev/null || true
echo ""
echo "PASS condition: seen cache may exist in memory, but no separate persisted seen-packet table/store should exist."

echo ""
echo "============================================================"
echo "AUDIT COMPLETE"
echo "============================================================"
