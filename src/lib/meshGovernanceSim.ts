import { SelfGovernanceRoutingEngine } from "../../lib/mauri-mesh-engine/src/selfGovernanceRoutingEngine";

export type MeshGovernanceCounters = {
  rehabilitations: number;
  trafficShapedRoutes: number;
  quarantinedPeers: number;
};

// [SIMULATION] A local instance of the real lib routing engine, driven by a
// lightweight tick so the dashboard can show the self-healing and
// traffic-control layers actually moving. This is development/simulation only
// and does NOT prove live BLE — on a physical device the same counters reflect
// real packet flow over BLE radios instead of this simulated activity.
//
// A short quarantine cooldown and a sensitive block threshold are configured
// (via the tunable RoutingEngineConfig) so the quarantine -> self-heal cycle is
// visible within a few seconds rather than the production defaults.
const engine = new SelfGovernanceRoutingEngine("LOCAL_SIM", {
  peerBlockCooldownMs: 4000,
  trustBlockThreshold: 35,
});

let seeded = false;
// Tracks the rehabilitation count seen on the previous tick so we can detect
// the tick on which the self-heal pass just released the flaky peer, and hold
// off re-quarantining it for that tick — otherwise the quarantined count would
// never be observed dropping back to zero.
let lastRehabSeen = 0;

function seed(): void {
  if (seeded) return;
  seeded = true;
  engine.upsertPeer({ id: "RELAY_1", label: "Relay 1", transport: "simulation", signal: 88, trust: 80 });
  engine.upsertPeer({ id: "RELAY_2", label: "Relay 2", transport: "simulation", signal: 82, trust: 76 });
  engine.upsertPeer({ id: "FLAKY_X", label: "Flaky X", transport: "simulation", signal: 60, trust: 40 });
}

/**
 * Advance the simulated mesh by one step and return the current governance
 * counters. Each call:
 *  - keeps two relays fresh and routes simulated traffic toward an unreachable
 *    target twice, so a relay carries repeated load within the congestion
 *    window and the traffic-control layer shapes the route;
 *  - cycles a flaky peer through failure -> quarantine, letting the engine's
 *    self-heal pass rehabilitate it once the (short) cooldown elapses.
 */
export function tickMeshGovernanceSim(): MeshGovernanceCounters {
  seed();
  const now = Date.now();

  engine.upsertPeer({ id: "RELAY_1", transport: "simulation", signal: 88, trust: 80, lastSeen: now });
  engine.upsertPeer({ id: "RELAY_2", transport: "simulation", signal: 82, trust: 76, lastSeen: now });

  engine.decideRoute(engine.createPacket({ to: "UNREACHABLE", payload: { sim: true } }));
  engine.decideRoute(engine.createPacket({ to: "UNREACHABLE", payload: { sim: true } }));

  // Re-arm the quarantine demo only when the flaky peer is currently healthy,
  // so it visibly oscillates between quarantined and rehabilitated. Skip the
  // exact tick on which the self-heal pass just rehabilitated it, so the
  // dashboard observes quarantinedPeers genuinely returning to zero before the
  // next failure re-quarantines it.
  const afterRoute = engine.getGovernanceStats();
  const healedThisTick = afterRoute.rehabilitations > lastRehabSeen;
  lastRehabSeen = afterRoute.rehabilitations;

  if (afterRoute.quarantinedPeers === 0 && !healedThisTick) {
    engine.applyDeliveryOutcome({
      packetId: `sim_${now}`,
      peerId: "FLAKY_X",
      ok: false,
      latencyMs: 600,
      timestamp: now,
    });
  }

  const stats = engine.getGovernanceStats();
  return {
    rehabilitations: stats.rehabilitations,
    trafficShapedRoutes: stats.trafficShapedRoutes,
    quarantinedPeers: stats.quarantinedPeers,
  };
}
