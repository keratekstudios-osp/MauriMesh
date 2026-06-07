import { describe, it, expect } from "vitest";
import { SelfGovernanceRoutingEngine } from "../../lib/mauri-mesh-engine/src/selfGovernanceRoutingEngine";

// These tests exercise the live AI routing engine that powers MauriMesh's
// relay routing, self-learning, self-healing and traffic-control layers.

function strongPeer(
  engine: SelfGovernanceRoutingEngine,
  id: string,
  overrides: Record<string, unknown> = {},
) {
  return engine.upsertPeer({
    id,
    label: id,
    transport: "ble",
    signal: 90,
    trust: 85,
    latencyMs: 150,
    status: "online",
    ...overrides,
  });
}

describe("SelfGovernanceRoutingEngine — relay routing", () => {
  it("approves a direct route when the target peer is visible and strong", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    strongPeer(engine, "B");

    const packet = engine.createPacket({ to: "B", payload: { text: "hi" } });
    const decision = engine.decideRoute(packet);

    expect(decision.decision).toBe("ALLOW_DIRECT");
    expect(decision.selected?.peerId).toBe("B");
  });

  it("approves a relay route when the target is not directly visible", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    strongPeer(engine, "C");

    const packet = engine.createPacket({ to: "Z-unknown", payload: { text: "relay" } });
    const decision = engine.decideRoute(packet);

    expect(decision.decision).toBe("ALLOW_RELAY");
    expect(decision.selected?.peerId).toBe("C");
  });

  it("stores the packet for later when no peer is visible at all", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    const packet = engine.createPacket({ to: "Z-unknown", payload: { text: "store" } });
    const decision = engine.decideRoute(packet);

    expect(decision.decision).toBe("STORE_FORWARD");
  });

  it("blocks a packet it has already seen (loop prevention)", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    strongPeer(engine, "B");
    const packet = engine.createPacket({ to: "B", payload: { text: "loop" } });

    engine.markPacketSeen(packet.id);
    const decision = engine.decideRoute(packet);

    expect(decision.decision).toBe("BLOCK_LOOP");
  });
});

describe("SelfGovernanceRoutingEngine — self-learning", () => {
  it("raises a peer's route score after successful deliveries", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    strongPeer(engine, "B", { trust: 60, signal: 70 });

    const before = engine.getPeers().find((p) => p.id === "B")!.routeScore;

    for (let i = 0; i < 5; i++) {
      engine.applyDeliveryOutcome({
        packetId: `pkt-${i}`,
        peerId: "B",
        ok: true,
        latencyMs: 90,
        timestamp: Date.now(),
      });
    }

    const after = engine.getPeers().find((p) => p.id === "B")!.routeScore;
    expect(after).toBeGreaterThanOrEqual(before);
    expect(engine.getGovernanceStats().learningEvents).toBeGreaterThanOrEqual(5);
  });

  it("quarantines a peer whose trust collapses after repeated failures", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    strongPeer(engine, "BAD", { trust: 50 });

    for (let i = 0; i < 10; i++) {
      engine.applyDeliveryOutcome({
        packetId: `fail-${i}`,
        peerId: "BAD",
        ok: false,
        latencyMs: 500,
        timestamp: Date.now(),
      });
    }

    const peer = engine.getPeers().find((p) => p.id === "BAD")!;
    expect(peer.status).toBe("blocked");
  });
});

describe("SelfGovernanceRoutingEngine — self-healing", () => {
  it("rehabilitates a quarantined peer once its cooldown has elapsed", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    strongPeer(engine, "BAD", { trust: 50, signal: 70 });

    // Fail in the past so the block cooldown has already elapsed by "now".
    const past = Date.now() - 60_000;
    for (let i = 0; i < 10; i++) {
      engine.applyDeliveryOutcome({
        packetId: `fail-${i}`,
        peerId: "BAD",
        ok: false,
        latencyMs: 500,
        timestamp: past,
      });
    }
    expect(engine.getPeers().find((p) => p.id === "BAD")!.status).toBe("blocked");

    // Any routing decision triggers the self-healing pass.
    engine.decideRoute(engine.createPacket({ to: "elsewhere", payload: {} }));

    const healed = engine.getPeers().find((p) => p.id === "BAD")!;
    expect(healed.status).not.toBe("blocked");
    expect(engine.getGovernanceStats().rehabilitations).toBeGreaterThanOrEqual(1);
  });

  it("rehabilitates a struggling peer immediately on a recovering success", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    strongPeer(engine, "BAD", { trust: 50, signal: 70 });

    for (let i = 0; i < 10; i++) {
      engine.applyDeliveryOutcome({
        packetId: `fail-${i}`,
        peerId: "BAD",
        ok: false,
        latencyMs: 500,
        timestamp: Date.now(),
      });
    }
    expect(engine.getPeers().find((p) => p.id === "BAD")!.status).toBe("blocked");

    engine.applyDeliveryOutcome({
      packetId: "recover",
      peerId: "BAD",
      ok: true,
      latencyMs: 120,
      timestamp: Date.now(),
    });

    const healed = engine.getPeers().find((p) => p.id === "BAD")!;
    expect(healed.status).not.toBe("blocked");
    expect(engine.getGovernanceStats().rehabilitations).toBeGreaterThanOrEqual(1);
  });
});

describe("SelfGovernanceRoutingEngine — MauriAI traffic control", () => {
  it("spreads relay traffic across equally-strong peers under congestion", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    strongPeer(engine, "R1");
    strongPeer(engine, "R2");

    const selected = new Set<string>();
    for (let i = 0; i < 8; i++) {
      const packet = engine.createPacket({ to: "far-target", payload: { i } });
      const decision = engine.decideRoute(packet);
      expect(decision.decision).toBe("ALLOW_RELAY");
      if (decision.selected) selected.add(decision.selected.peerId);
    }

    // Greedy routing would pin every packet on one relay; traffic control must
    // distribute load across both.
    expect(selected.has("R1")).toBe(true);
    expect(selected.has("R2")).toBe(true);
    expect(engine.getGovernanceStats().trafficShapedRoutes).toBeGreaterThan(0);
  });
});

describe("SelfGovernanceRoutingEngine — state lifecycle", () => {
  it("removePeer purges the peer along with its quarantine and traffic state", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    strongPeer(engine, "BAD", { trust: 50, signal: 70 });

    for (let i = 0; i < 10; i++) {
      engine.applyDeliveryOutcome({
        packetId: `fail-${i}`,
        peerId: "BAD",
        ok: false,
        latencyMs: 500,
        timestamp: Date.now(),
      });
    }
    expect(engine.getGovernanceStats().quarantinedPeers).toBeGreaterThanOrEqual(1);

    expect(engine.removePeer("BAD")).toBe(true);
    expect(engine.getPeers().some((p) => p.id === "BAD")).toBe(false);
    expect(engine.getGovernanceStats().quarantinedPeers).toBe(0);
    expect(engine.removePeer("BAD")).toBe(false);
  });

  it("does not strand quarantine state for peers that have been removed", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    strongPeer(engine, "GONE", { trust: 50, signal: 70 });
    strongPeer(engine, "OK");

    for (let i = 0; i < 10; i++) {
      engine.applyDeliveryOutcome({
        packetId: `fail-${i}`,
        peerId: "GONE",
        ok: false,
        latencyMs: 500,
        timestamp: Date.now(),
      });
    }

    engine.removePeer("GONE");
    // A routing decision runs the GC pass; quarantine state must stay clean.
    engine.decideRoute(engine.createPacket({ to: "far", payload: {} }));
    expect(engine.getGovernanceStats().quarantinedPeers).toBe(0);
  });
});
