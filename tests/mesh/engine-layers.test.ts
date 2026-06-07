import { describe, it, expect, beforeEach } from "vitest";

import { SelfGovernanceRoutingEngine } from "../../lib/mauri-mesh-engine/src/selfGovernanceRoutingEngine";
import { MauriMeshP2PEngine } from "../../lib/mauri-mesh-engine/src/mauriMeshP2PEngine";
import {
  createJumpCode,
  explainJumpCode,
  scoreJumpCompatibility,
} from "../../lib/mauri-mesh-engine/src/jumpCodeEngine";
import type { MeshPacket, MeshPeer } from "../../lib/mauri-mesh-engine/src/types";

import { TikangaGovernance } from "../../src/maurimesh/invention-engine/tikangaGovernance";
import type {
  MeshNode as TikangaNode,
  MeshPacket as TikangaPacket,
} from "../../src/maurimesh/invention-engine/types";

import { HybridAiRoutingLogic } from "../../src/routing/hybridAiRoutingLogic";
import { MauriAiRoutingIntelligence } from "../../src/routing/mauriAiRoutingIntelligence";
import type {
  MauriAiRouteCandidate,
  MauriAiSignal,
} from "../../src/ai/mauriAiTypes";

// ── Helpers ───────────────────────────────────────────────────────────────────

function strongPeer(id: string, over: Partial<MeshPeer> = {}) {
  return {
    id,
    label: id,
    transport: "ble" as const,
    signal: 90,
    trust: 90,
    latencyMs: 100,
    batteryPressure: 10,
    lastSeen: Date.now(),
    ...over,
  };
}

function aiCandidate(over: Partial<MauriAiRouteCandidate> = {}): MauriAiRouteCandidate {
  return {
    peerId: "peer-1",
    routeId: "route-1",
    hops: 1,
    rssi: -50,
    latencyMs: 100,
    ackRate: 0.98,
    trustScore: 0.95,
    queuePressure: 5,
    lastSeenAgeMs: 2000,
    ...over,
  };
}

// ── Layer 1: Self-governance routing engine ────────────────────────────────────

describe("SelfGovernanceRoutingEngine — route governance", () => {
  let engine: SelfGovernanceRoutingEngine;

  beforeEach(() => {
    engine = new SelfGovernanceRoutingEngine("A");
  });

  it("approves a direct route to a strong visible target peer", () => {
    engine.upsertPeer(strongPeer("D"));
    const packet = engine.createPacket({ to: "D", payload: "hi" });
    const decision = engine.decideRoute(packet);
    expect(decision.decision).toBe("ALLOW_DIRECT");
    expect(decision.selected?.peerId).toBe("D");
  });

  it("chooses relay when the target is not directly visible", () => {
    engine.upsertPeer(strongPeer("B"));
    const packet = engine.createPacket({ to: "D", payload: "relay-me" });
    const decision = engine.decideRoute(packet);
    expect(decision.decision).toBe("ALLOW_RELAY");
    expect(decision.selected?.peerId).toBe("B");
  });

  it("falls back to store-forward when no peers are visible", () => {
    const packet = engine.createPacket({ to: "D", payload: "alone" });
    const decision = engine.decideRoute(packet);
    expect(decision.decision).toBe("STORE_FORWARD");
    expect(decision.candidates).toHaveLength(0);
  });

  it("blocks a packet that has already been seen (loop suppression)", () => {
    engine.upsertPeer(strongPeer("D"));
    const packet = engine.createPacket({ to: "D", payload: "loop" });
    engine.markPacketSeen(packet.id);
    const decision = engine.decideRoute(packet);
    expect(decision.decision).toBe("BLOCK_LOOP");
  });

  it("drops an expired packet (TTL exceeded)", () => {
    engine.upsertPeer(strongPeer("D"));
    const packet = engine.createPacket({ to: "D", payload: "stale", ttlMs: 1000 });
    packet.createdAt = Date.now() - 5000;
    const decision = engine.decideRoute(packet);
    expect(decision.decision).toBe("DROP_EXPIRED");
  });

  it("drops a packet that exceeded its max hop count", () => {
    engine.upsertPeer(strongPeer("D"));
    const packet = engine.createPacket({ to: "D", payload: "looped", maxHops: 3 });
    packet.hopCount = 3;
    const decision = engine.decideRoute(packet);
    expect(decision.decision).toBe("DROP_EXPIRED");
  });

  it("never selects a peer already present in the packet path", () => {
    engine.upsertPeer(strongPeer("B"));
    const packet = engine.createPacket({ to: "D", payload: "no-back" });
    packet.path = ["A", "B"];
    const decision = engine.decideRoute(packet);
    expect(decision.candidates.some((c) => c.peerId === "B")).toBe(false);
  });
});

describe("SelfGovernanceRoutingEngine — self-learning", () => {
  let engine: SelfGovernanceRoutingEngine;

  beforeEach(() => {
    engine = new SelfGovernanceRoutingEngine("A");
  });

  it("raises trust and route score after a successful delivery", () => {
    const peer = engine.upsertPeer(strongPeer("B", { trust: 60 }));
    const before = peer.trust;
    engine.applyDeliveryOutcome({
      packetId: "p1",
      peerId: "B",
      ok: true,
      latencyMs: 80,
      timestamp: Date.now(),
    });
    const after = engine.getPeers().find((p) => p.id === "B")!;
    expect(after.trust).toBeGreaterThan(before);
    expect(after.successCount).toBe(1);
  });

  it("blocks a peer whose trust collapses after repeated failures", () => {
    engine.upsertPeer(strongPeer("B", { trust: 30 }));
    for (let i = 0; i < 3; i++) {
      engine.applyDeliveryOutcome({
        packetId: `f${i}`,
        peerId: "B",
        ok: false,
        latencyMs: 0,
        timestamp: Date.now(),
      });
    }
    const after = engine.getPeers().find((p) => p.id === "B")!;
    expect(after.status).toBe("blocked");
    expect(after.failureCount).toBe(3);
  });

  it("tracks governance statistics across decisions", () => {
    engine.upsertPeer(strongPeer("D"));
    const packet = engine.createPacket({ to: "D", payload: "x" });
    engine.decideRoute(packet);
    engine.markPacketSeen(packet.id);
    engine.decideRoute(packet);
    const stats = engine.getGovernanceStats();
    expect(stats.routeDecisions).toBe(2);
    expect(stats.packetsDropped).toBe(1);
    expect(stats.packetsSeen).toBe(1);
  });
});

describe("MauriMeshP2PEngine — A→B→C→D relay + reverse ACK", () => {
  it("relays a packet hop-by-hop from A to D and returns a strict reverse ACK", async () => {
    const A = new MauriMeshP2PEngine("A");
    const B = new MauriMeshP2PEngine("B");
    const C = new MauriMeshP2PEngine("C");
    const D = new MauriMeshP2PEngine("D");

    // Each node only sees its next neighbour — forces a multi-hop relay chain.
    A.ingestPeer(strongPeer("B"));
    B.ingestPeer(strongPeer("C"));
    C.ingestPeer(strongPeer("D"));

    // Hop 1: A decides toward B (relay, D not directly visible).
    const sent = await A.sendMessage("D", { text: "kia ora D" }, "A");
    expect(sent.decision).toBe("ALLOW_RELAY");

    // Build the in-flight packet as it walks the chain (path accumulates).
    const relay: MeshPacket = { ...sent.packet, to: "D", from: "A" };

    // Hop 2: B forwards toward C.
    relay.path = ["A", "B"];
    relay.hopCount = 1;
    const atB = B.receivePacket(relay);
    expect(atB.accepted).toBe(true);

    // Hop 3: C forwards toward D.
    relay.path = ["A", "B", "C"];
    relay.hopCount = 2;
    const atC = C.receivePacket(relay);
    expect(atC.accepted).toBe(true);

    // Final hop: D is the target — packet delivered, strict reverse ACK created.
    relay.path = ["A", "B", "C", "D"];
    relay.hopCount = 3;
    const atD = D.receivePacket(relay);
    expect(atD.accepted).toBe(true);
    expect(atD.ack).toBeDefined();
    expect(atD.ack!.type).toBe("ack");
    expect(atD.ack!.to).toBe("A");
    expect(atD.ack!.reversePath).toEqual(["D", "C", "B", "A"]);
  });

  it("stores a packet when the engine has no visible peers", async () => {
    const lonely = new MauriMeshP2PEngine("solo");
    const result = await lonely.sendMessage("ghost", { text: "anybody?" });
    expect(result.delivered).toBe(false);
    expect(result.decision).toBe("STORE_FORWARD");
    expect(lonely.getSnapshot().queue).toHaveLength(1);
  });

  it("delivers over the simulation transport to a directly visible peer", async () => {
    const node = new MauriMeshP2PEngine("A");
    node.ingestPeer(strongPeer("D"));
    const result = await node.sendMessage("D", { text: "direct" }, "A");
    expect(result.decision).toBe("ALLOW_DIRECT");
    expect(result.delivered).toBe(true);
  });
});

describe("JumpCode engine", () => {
  it("produces deterministic codes for identical inputs in the same epoch", () => {
    const args = { from: "A", to: "B", transport: "ble" as const, epochBucket: 42 };
    expect(createJumpCode(args)).toBe(createJumpCode(args));
  });

  it("encodes the transport into the code prefix", () => {
    const code = createJumpCode({ from: "A", to: "B", transport: "wifi-lan", epochBucket: 1 });
    expect(code).toContain("WIFI_LAN");
  });

  it("scores a direct online target higher than a weak relay", () => {
    const packet = { to: "B", path: ["A"], jumpCode: "JM-BLE-0000-0000" } as unknown as MeshPacket;
    const direct = scoreJumpCompatibility(packet, strongPeer("B", { status: "online" }) as MeshPeer);
    const weak = scoreJumpCompatibility(
      { ...packet, to: "Z" } as MeshPacket,
      strongPeer("Q", { status: "weak" }) as MeshPeer,
    );
    expect(direct).toBeGreaterThan(weak);
  });

  it("explains a well-formed jump code", () => {
    expect(explainJumpCode("JM-BLE-1A2B-3C4D")).toContain("JumpCode");
    expect(explainJumpCode("bad")).toBe("Invalid JumpCode format.");
  });
});

// ── Layer 2: Tikanga governance ────────────────────────────────────────────────

describe("TikangaGovernance — cultural classification", () => {
  const t = new TikangaGovernance();

  it("classifies emergency language as KIA_KAHA_EMERGENCY", () => {
    expect(t.classifyMessage("Please help, this is an emergency")).toBe("KIA_KAHA_EMERGENCY");
    expect(t.classifyMessage("kia kaha everyone")).toBe("KIA_KAHA_EMERGENCY");
  });

  it("classifies private/tapu language as TAPU_PROTECTED", () => {
    expect(t.classifyMessage("this is confidential")).toBe("TAPU_PROTECTED");
    expect(t.classifyMessage("tapu material")).toBe("TAPU_PROTECTED");
  });

  it("classifies whānau language as WHANAUNGATANGA_TRUSTED", () => {
    expect(t.classifyMessage("message for my whānau")).toBe("WHANAUNGATANGA_TRUSTED");
    expect(t.classifyMessage("family update")).toBe("WHANAUNGATANGA_TRUSTED");
  });

  it("defaults to NOA_OPEN for ordinary messages", () => {
    expect(t.classifyMessage("hello there")).toBe("NOA_OPEN");
  });
});

describe("TikangaGovernance — routing decisions", () => {
  const t = new TikangaGovernance();

  function node(id: string, over: Partial<TikangaNode> = {}): TikangaNode {
    return {
      id,
      role: "ENDPOINT",
      trust: "TRUSTED",
      batteryPct: 80,
      signalPct: 80,
      online: true,
      lastSeenMs: Date.now(),
      transports: ["BLE"],
      ...over,
    };
  }

  function packet(over: Partial<TikangaPacket> = {}): TikangaPacket {
    return {
      id: "pkt-1",
      from: "A",
      to: "B",
      body: "kia ora",
      createdAtMs: Date.now(),
      ttl: 6,
      priority: 1,
      culturalState: "NOA_OPEN",
      ...over,
    };
  }

  it("approves a normal packet between trusted nodes", () => {
    const decision = t.decide(packet(), node("A"), node("B"));
    expect(decision.approved).toBe(true);
  });

  it("rejects a packet from a blocked sender", () => {
    const decision = t.decide(packet(), node("A", { trust: "BLOCKED" }), node("B"));
    expect(decision.approved).toBe(false);
    expect(decision.culturalState).toBe("TAPU_PROTECTED");
  });

  it("rejects a packet to a blocked recipient", () => {
    const decision = t.decide(packet(), node("A"), node("B", { trust: "BLOCKED" }));
    expect(decision.approved).toBe(false);
  });

  it("flags missing sender identity but still allows the packet", () => {
    const decision = t.decide(packet(), undefined, node("B"));
    expect(decision.approved).toBe(true);
    expect(decision.restrictions).toContain("Sender identity not observed.");
  });

  it("adds a restriction for tapu-protected packets", () => {
    const decision = t.decide(packet({ culturalState: "TAPU_PROTECTED" }), node("A"), node("B"));
    expect(decision.approved).toBe(true);
    expect(decision.restrictions.length).toBeGreaterThan(0);
  });

  it("allows emergency packets while preserving delivery proof", () => {
    const decision = t.decide(packet({ culturalState: "KIA_KAHA_EMERGENCY" }), node("A"), node("B"));
    expect(decision.approved).toBe(true);
    expect(decision.restrictions.join(" ")).toMatch(/delivery proof/i);
  });
});

// ── Layer 3: AI routing relay ──────────────────────────────────────────────────

describe("MauriAiRoutingIntelligence — route scoring", () => {
  const ai = new MauriAiRoutingIntelligence();

  it("scores a strong route higher than a degraded one", () => {
    const strong = ai.scoreRoute(aiCandidate());
    const weak = ai.scoreRoute(
      aiCandidate({ rssi: -95, ackRate: 0.2, trustScore: 0.2, latencyMs: 2800, hops: 7 }),
    );
    expect(strong.score).toBeGreaterThan(weak.score);
    expect(strong.score).toBeLessThanOrEqual(1);
  });

  it("chooses the best route from a candidate set", () => {
    const best = ai.chooseBestRoute([
      aiCandidate({ peerId: "weak", ackRate: 0.3, trustScore: 0.3 }),
      aiCandidate({ peerId: "best", ackRate: 0.99, trustScore: 0.99 }),
    ]);
    expect(best?.peerId).toBe("best");
  });

  it("learns directional lessons from delivery signals", () => {
    expect(ai.learnFromSignal({ ackSuccess: true })).toMatch(/strengthens/i);
    expect(ai.learnFromSignal({ routeFailure: true })).toMatch(/lowers/i);
    expect(ai.learnFromSignal({ peerStale: true })).toMatch(/deprioritized/i);
  });
});

describe("HybridAiRoutingLogic — relay decisions", () => {
  const logic = new HybridAiRoutingLogic();

  function signal(over: Partial<MauriAiSignal> = {}): MauriAiSignal {
    return { physicalBleProven: true, tikangaSafe: true, ...over };
  }

  it("requires physical BLE proof before any live claim", () => {
    const out = logic.decide(signal({ physicalBleProven: false }), [aiCandidate()]);
    expect(out.decision).toBe("require_physical_proof");
  });

  it("blocks unsafe actions flagged by Tikanga", () => {
    const out = logic.decide(signal({ tikangaSafe: false }), [aiCandidate()]);
    expect(out.decision).toBe("block_unsafe");
  });

  it("sends direct over a strong proven route", () => {
    const out = logic.decide(signal(), [aiCandidate()]);
    expect(out.decision).toBe("send_direct");
    expect(out.selectedRoute).toBeDefined();
  });

  it("relays over a moderate route", () => {
    const out = logic.decide(signal(), [
      aiCandidate({ rssi: -70, latencyMs: 800, ackRate: 0.7, trustScore: 0.7, hops: 3, queuePressure: 30, lastSeenAgeMs: 30000 }),
    ]);
    expect(out.decision).toBe("send_relay");
  });

  it("uses a jump-code alternate path over a weak route", () => {
    const out = logic.decide(signal(), [
      aiCandidate({ rssi: -85, latencyMs: 1500, ackRate: 0.5, trustScore: 0.55, hops: 5, queuePressure: 60, lastSeenAgeMs: 60000 }),
    ]);
    expect(out.decision).toBe("send_jumpcode");
  });

  it("self-heals when route confidence is too low and no queue pressure exists", () => {
    const out = logic.decide(signal({ queueDepth: 0 }), [
      aiCandidate({ rssi: -95, latencyMs: 2500, ackRate: 0.2, trustScore: 0.3, hops: 7, queuePressure: 0, lastSeenAgeMs: 10000 }),
    ]);
    expect(out.decision).toBe("self_heal");
  });

  it("store-forwards a weak route under queue pressure", () => {
    const out = logic.decide(signal({ queueDepth: 5 }), [
      aiCandidate({ rssi: -95, latencyMs: 2500, ackRate: 0.2, trustScore: 0.3, hops: 7, queuePressure: 0, lastSeenAgeMs: 10000 }),
    ]);
    expect(out.decision).toBe("store_forward");
  });

  it("store-forwards when there is no candidate route at all", () => {
    const out = logic.decide(signal(), []);
    expect(out.decision).toBe("store_forward");
    expect(out.selectedRoute).toBeUndefined();
  });
});
