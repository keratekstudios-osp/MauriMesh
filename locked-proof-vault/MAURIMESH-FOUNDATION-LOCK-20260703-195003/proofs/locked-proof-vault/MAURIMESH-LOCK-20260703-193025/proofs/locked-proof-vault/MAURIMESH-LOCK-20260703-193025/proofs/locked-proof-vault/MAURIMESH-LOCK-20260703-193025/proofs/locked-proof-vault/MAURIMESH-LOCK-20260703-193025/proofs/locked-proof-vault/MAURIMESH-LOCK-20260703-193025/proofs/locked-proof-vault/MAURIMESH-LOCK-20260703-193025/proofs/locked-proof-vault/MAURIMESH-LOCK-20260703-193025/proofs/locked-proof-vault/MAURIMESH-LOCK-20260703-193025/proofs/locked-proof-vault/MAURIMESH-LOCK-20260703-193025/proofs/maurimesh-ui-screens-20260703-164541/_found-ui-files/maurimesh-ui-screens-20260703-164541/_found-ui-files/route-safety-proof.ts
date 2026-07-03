import { RouteSafetyEngine } from "./artifacts/api-server/src/runtime/RouteSafetyEngine";

const MARKER = "ROUTE_SAFETY_RESTART_PROOF_20260608_A";

async function run() {
  const routeKey = "restart-proof-route-" + Date.now();
  const packetId = "restart-proof-packet-" + Date.now();

  console.log("START:", MARKER);

  const engineA = new RouteSafetyEngine({ failureThreshold: 3, cooldownMs: 600000, seenCacheLimit: 100 });
  await engineA.init();
  await engineA.recordFailure(routeKey, "malformed");
  await engineA.recordFailure(routeKey, "ttl_expired");
  await engineA.recordFailure(routeKey, "duplicate");

  console.log("Blacklisted before restart:", engineA.isBlacklisted(routeKey));
  if (!engineA.isBlacklisted(routeKey)) throw new Error("Route was not blacklisted before restart");

  const engineB = new RouteSafetyEngine({ failureThreshold: 3, cooldownMs: 600000, seenCacheLimit: 100 });
  await engineB.init();

  console.log("Blacklisted after restart:", engineB.isBlacklisted(routeKey));
  if (!engineB.isBlacklisted(routeKey)) throw new Error("Blacklist did not survive restart");

  const seenRoute = "seen-cache-route-" + Date.now();

  const first = await engineB.checkPacket({ packetId, routeKey: seenRoute, ttl: 8, raw: { ok: true } });
  const duplicate = await engineB.checkPacket({ packetId, routeKey: seenRoute, ttl: 8, raw: { ok: true } });

  console.log("First packet:", first);
  console.log("Duplicate same process:", duplicate);

  if (!first.ok) throw new Error("First packet should be accepted");
  if (duplicate.ok || duplicate.reason !== "duplicate") throw new Error("Duplicate was not blocked inside same process");

  const engineC = new RouteSafetyEngine({ failureThreshold: 3, cooldownMs: 600000, seenCacheLimit: 100 });
  await engineC.init();

  const afterRestartSeen = await engineC.checkPacket({
    packetId,
    routeKey: "seen-cache-after-restart-" + Date.now(),
    ttl: 8,
    raw: { ok: true },
  });

  console.log("Same packet after restart:", afterRestartSeen);

  if (!afterRestartSeen.ok) throw new Error("Seen-packet cache persisted, but it must remain memory-only");

  console.log("PASS:", MARKER);
}

run().catch((error) => {
  console.error("FAIL:", MARKER);
  console.error(error);
  process.exit(1);
});
