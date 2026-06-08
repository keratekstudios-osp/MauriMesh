import { describe, it, expect } from "vitest";
import { LivingRouteMemory } from "../../src/maurimesh/invention-engine/livingRouteMemory";
import { DecentralisedTrustMemory } from "../../src/maurimesh/invention-engine/decentralisedTrustMemory";
import { SelfHealingRuntime } from "../../src/maurimesh/invention-engine/selfHealingRuntime";
import { KiaKahaEmergencyRouting } from "../../src/maurimesh/invention-engine/kiaKahaEmergencyRouting";
import { MauriAiRoutingConscience } from "../../src/maurimesh/invention-engine/mauriAiRoutingConscience";
import type {
  GovernanceDecision,
  MeshNode,
  MeshPacket,
  TransportKind,
} from "../../src/maurimesh/invention-engine/types";

// These tests exercise the MauriMesh "invention engine" layer: the self-learning
// route memory, decentralised trust, self-healing runtime, Kia Kaha emergency
// routing, and the Mauri AI routing conscience that selects routes. They are
// pure/deterministic and prove no live BLE — this is simulation logic only.

function node(id: string, over: Partial<MeshNode> = {}): MeshNode {
  return {
    id,
    role: "RELAY",
    trust: "VERIFIED",
    batteryPct: 90,
    signalPct: 90,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE"],
    ...over,
  };
}

function packet(over: Partial<MeshPacket> = {}): MeshPacket {
  return {
    id: "p1",
    from: "A",
    to: "B",
    body: "hi",
    createdAtMs: Date.now(),
    ttl: 8,
    priority: 5,
    culturalState: "NOA_OPEN",
    ...over,
  };
}

const approved: GovernanceDecision = {
  approved: true,
  reason: "ok",
  culturalState: "NOA_OPEN",
  restrictions: [],
};

describe("LivingRouteMemory — self-learning route scoring", () => {
  it("scores an unknown route at the neutral baseline", () => {
    const mem = new LivingRouteMemory();
    expect(mem.scoreRoute(["A", "B"])).toBe(0.5);
  });

  it("raises a route's score and averages latency after successes", () => {
    const mem = new LivingRouteMemory();
    mem.recordSuccess(["A", "B"], 100);
    const rec = mem.recordSuccess(["A", "B"], 200);
    expect(rec.successCount).toBe(2);
    expect(rec.averageLatencyMs).toBe(150);
    expect(mem.scoreRoute(["A", "B"])).toBeGreaterThan(0.5);
  });

  it("lowers a route's score after a failure", () => {
    const mem = new LivingRouteMemory();
    mem.recordFailure(["A", "B"]);
    expect(mem.scoreRoute(["A", "B"])).toBeLessThan(0.5);
  });

  it("exports every learned route", () => {
    const mem = new LivingRouteMemory();
    mem.recordSuccess(["A", "B"], 100);
    mem.recordFailure(["A", "C"]);
    expect(mem.exportMemory().map((m) => m.routeKey).sort()).toEqual([
      "A>B",
      "A>C",
    ]);
  });
});

describe("DecentralisedTrustMemory — trust convergence", () => {
  it("starts a new peer at the neutral score on first observation", () => {
    const trust = new DecentralisedTrustMemory();
    const rec = trust.observeSuccess("N1");
    expect(rec.successes).toBe(1);
    expect(rec.score).toBeCloseTo(0.54, 5);
  });

  it("drives a peer to BLOCKED after repeated failures", () => {
    const trust = new DecentralisedTrustMemory();
    for (let i = 0; i < 8; i += 1) trust.observeFailure("BAD");
    const [rec] = trust.exportTrust();
    expect(trust.scoreToTrust(rec.score)).toBe("BLOCKED");
  });

  it("maps scores to the expected qualitative trust levels", () => {
    const trust = new DecentralisedTrustMemory();
    expect(trust.scoreToTrust(0)).toBe("BLOCKED");
    expect(trust.scoreToTrust(0.2)).toBe("UNKNOWN");
    expect(trust.scoreToTrust(0.4)).toBe("OBSERVED");
    expect(trust.scoreToTrust(0.7)).toBe("TRUSTED");
    expect(trust.scoreToTrust(0.85)).toBe("VERIFIED");
    expect(trust.scoreToTrust(0.95)).toBe("GUARDIAN");
  });

  it("leaves an unobserved node untouched but applies trust to an observed one", () => {
    const trust = new DecentralisedTrustMemory();
    const fresh = node("X", { trust: "UNKNOWN" });
    expect(trust.applyToNode(fresh)).toBe(fresh);

    for (let i = 0; i < 8; i += 1) trust.observeFailure("X");
    expect(trust.applyToNode(fresh).trust).toBe("BLOCKED");
  });
});

describe("KiaKahaEmergencyRouting — emergency strengthening", () => {
  it("leaves a non-emergency packet unchanged", () => {
    const kk = new KiaKahaEmergencyRouting();
    const p = packet();
    expect(kk.strengthen(p)).toBe(p);
    expect(kk.isEmergency(p)).toBe(false);
  });

  it("strengthens an emergency packet's priority, ttl and metadata", () => {
    const kk = new KiaKahaEmergencyRouting();
    const p = packet({ culturalState: "KIA_KAHA_EMERGENCY", ttl: 4, priority: 1 });
    const strong = kk.strengthen(p);
    expect(strong.priority).toBe(10);
    expect(strong.ttl).toBe(12);
    expect(strong.metadata?.emergencyMode).toBe(true);
    expect(kk.isEmergency(strong)).toBe(true);
  });
});

describe("SelfHealingRuntime — autonomous recovery actions", () => {
  it("reports NO_ACTION when the mesh is healthy", () => {
    const heal = new SelfHealingRuntime();
    const actions = heal.findHealingActions([node("A")], [], []);
    expect(actions).toHaveLength(1);
    expect(actions[0].type).toBe("NO_ACTION");
  });

  it("removes a stale offline node", () => {
    const heal = new SelfHealingRuntime();
    const stale = node("DEAD", {
      online: false,
      lastSeenMs: Date.now() - 10 * 60 * 1000,
    });
    const actions = heal.findHealingActions([stale], [], []);
    expect(actions.some((a) => a.type === "REMOVE_STALE_NODE" && a.targetId === "DEAD")).toBe(true);
  });

  it("requeues a queued packet that failed without an ACK", () => {
    const heal = new SelfHealingRuntime();
    const queued = packet({ id: "stuck" });
    const ledger = [
      { packetId: "stuck", status: "FAILED" as const, atMs: Date.now() },
    ];
    const actions = heal.findHealingActions([node("A")], [queued], ledger);
    expect(actions.some((a) => a.type === "REQUEUE_PACKET" && a.targetId === "stuck")).toBe(true);
  });
});

describe("MauriAiRoutingConscience — route selection", () => {
  function conscience(): MauriAiRoutingConscience {
    return new MauriAiRoutingConscience(new LivingRouteMemory());
  }

  it("stores the packet when governance rejects it", () => {
    const plan = conscience().chooseRoute(packet(), [], {
      approved: false,
      reason: "blocked sender",
      culturalState: "TAPU_PROTECTED",
      restrictions: [],
    });
    expect(plan.transport).toBe("STORE_FORWARD");
    expect(plan.storeAndForward).toBe(true);
    expect(plan.governanceApproved).toBe(false);
  });

  it("chooses a direct route to an online recipient", () => {
    const nodes = [node("A", { role: "ENDPOINT" }), node("B", { role: "ENDPOINT" })];
    const plan = conscience().chooseRoute(packet(), nodes, approved);
    expect(plan.storeAndForward).toBe(false);
    expect(plan.hops).toHaveLength(1);
    expect(plan.hops[0].nodeId).toBe("B");
  });

  it("prefers WIFI_DIRECT over BLE on a direct route", () => {
    const transports: TransportKind[] = ["WIFI_DIRECT", "BLE"];
    const nodes = [
      node("A", { role: "ENDPOINT", transports }),
      node("B", { role: "ENDPOINT", transports }),
    ];
    const plan = conscience().chooseRoute(packet(), nodes, approved);
    expect(plan.transport).toBe("WIFI_DIRECT");
  });

  it("falls back to a trusted relay when the recipient is offline", () => {
    const nodes = [
      node("A", { role: "ENDPOINT" }),
      node("B", { role: "ENDPOINT", online: false }),
      node("R", { role: "RELAY", trust: "VERIFIED" }),
    ];
    const plan = conscience().chooseRoute(packet(), nodes, approved);
    expect(plan.hops[0]?.nodeId).toBe("R");
    expect(plan.storeAndForward).toBe(true);
  });

  it("stores the packet when no safe relay is available", () => {
    const nodes = [
      node("A", { role: "ENDPOINT" }),
      node("B", { role: "ENDPOINT", online: false }),
    ];
    const plan = conscience().chooseRoute(packet(), nodes, approved);
    expect(plan.transport).toBe("STORE_FORWARD");
    expect(plan.totalScore).toBeCloseTo(0.35, 5);
  });
});
