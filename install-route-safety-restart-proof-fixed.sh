#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "ROUTE SAFETY RESTART PROOF — FIXED INSTALLER"
echo "Proves blacklist survives restart"
echo "Proves seen-packet cache remains memory-only"
echo "============================================================"
echo ""

ROOT="$(pwd)"
DOCS="$ROOT/docs"
SCRIPTS="$ROOT/scripts"
TESTS="$ROOT/scripts/route-safety-proof"

mkdir -p "$DOCS" "$SCRIPTS" "$TESTS"

cat > "$TESTS/route-safety-restart-proof.ts" <<'TS'
import { RouteSafetyEngine } from "../../artifacts/api-server/src/runtime/RouteSafetyEngine";

const PROOF_MARKER = "ROUTE_SAFETY_RESTART_PROOF_20260608_A";

async function main() {
  const routeKey = `proof-route-${Date.now()}`;
  const packetId = `proof-packet-${Date.now()}`;

  console.log("============================================================");
  console.log(PROOF_MARKER);
  console.log("Route Safety Restart Proof");
  console.log("============================================================");

  const engineA = new RouteSafetyEngine({
    failureThreshold: 3,
    cooldownMs: 10 * 60 * 1000,
    seenCacheLimit: 100,
  });

  await engineA.init();

  console.log("");
  console.log("1. Force failures to cross blacklist threshold");

  await engineA.recordFailure(routeKey, "malformed");
  await engineA.recordFailure(routeKey, "ttl_expired");
  await engineA.recordFailure(routeKey, "duplicate");

  const blockedA = engineA.isBlacklisted(routeKey);
  console.log("Blacklisted before restart:", blockedA);

  if (!blockedA) {
    throw new Error("FAIL: route was not blacklisted before restart");
  }

  console.log("");
  console.log("2. Simulate restart with a new RouteSafetyEngine instance");

  const engineB = new RouteSafetyEngine({
    failureThreshold: 3,
    cooldownMs: 10 * 60 * 1000,
    seenCacheLimit: 100,
  });

  await engineB.init();

  const blockedB = engineB.isBlacklisted(routeKey);
  console.log("Blacklisted after restart:", blockedB);

  if (!blockedB) {
    throw new Error("FAIL: persisted blacklist did not reload after restart");
  }

  console.log("");
  console.log("3. Prove seen-packet cache is memory-only");

  const routeKeyForSeenCache = `seen-cache-proof-${Date.now()}`;

  const firstPacketDecision = await engineB.checkPacket({
    packetId,
    routeKey: routeKeyForSeenCache,
    ttl: 8,
    raw: { ok: true },
  });

  const duplicateDecisionSameProcess = await engineB.checkPacket({
    packetId,
    routeKey: routeKeyForSeenCache,
    ttl: 8,
    raw: { ok: true },
  });

  console.log("First packet decision:", firstPacketDecision);
  console.log("Duplicate same-process decision:", duplicateDecisionSameProcess);

  if (firstPacketDecision.ok !== true) {
    throw new Error("FAIL: first packet should be accepted");
  }

  if (
    duplicateDecisionSameProcess.ok !== false ||
    duplicateDecisionSameProcess.reason !== "duplicate"
  ) {
    throw new Error("FAIL: duplicate was not detected inside same process");
  }

  const engineC = new RouteSafetyEngine({
    failureThreshold: 3,
    cooldownMs: 10 * 60 * 1000,
    seenCacheLimit: 100,
  });

  await engineC.init();

  const duplicateDecisionAfterRestart = await engineC.checkPacket({
    packetId,
    routeKey: `seen-cache-proof-after-restart-${Date.now()}`,
    ttl: 8,
    raw: { ok: true },
  });

  console.log("Same packet after restart decision:", duplicateDecisionAfterRestart);

  if (duplicateDecisionAfterRestart.ok !== true) {
    throw new Error(
      "FAIL: seen-packet cache persisted across restart, but it must remain memory-only"
    );
  }

  console.log("");
  console.log("============================================================");
  console.log("PASS:", PROOF_MARKER);
  console.log("Durable blacklist survived restart.");
  console.log("Seen-packet cache remained memory-only.");
  console.log("============================================================");
}

main().catch((error) => {
  console.error("");
  console.error("============================================================");
  console.error("FAIL:", PROOF_MARKER);
  console.error(error);
  console.error("============================================================");
  process.exit(1);
});
TS

cat > "$SCRIPTS/run-route-safety-restart-proof.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "RUN ROUTE SAFETY RESTART PROOF"
echo "============================================================"

if command -v tsx >/dev/null 2>&1; then
  tsx scripts/route-safety-proof/route-safety-restart-proof.ts
else
  npx tsx scripts/route-safety-proof/route-safety-restart-proof.ts
fi
SH

chmod +x "$SCRIPTS/run-route-safety-restart-proof.sh"

cat > "$DOCS/route-safety-restart-proof-20260608.md" <<'DOC'
# Route Safety Restart Proof

Marker: `ROUTE_SAFETY_RESTART_PROOF_20260608_A`

## Proves

- Route blacklist persists after restart.
- Blacklisted route remains blocked after new engine instance loads persistence.
- Seen-packet duplicate cache is memory-only.
- Duplicate packet detection works inside one process.
- Same packet is accepted after restart because seen-cache is not persisted.

## Command

```bash
bash scripts/run-route-safety-restart-proof.sh

