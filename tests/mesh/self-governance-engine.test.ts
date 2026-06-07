import { describe, it, expect } from "vitest";
import {
  DEFAULT_ROUTING_CONFIG,
  SelfGovernanceRoutingEngine,
} from "../../lib/mauri-mesh-engine/src/selfGovernanceRoutingEngine";
import { MauriMeshP2PEngine } from "../../lib/mauri-mesh-engine/src/mauriMeshP2PEngine";

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

describe("SelfGovernanceRoutingEngine — tunable thresholds", () => {
  it("defaults to today's values when no config is passed", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    expect(engine.getConfig()).toEqual(DEFAULT_ROUTING_CONFIG);
  });

  it("merges partial overrides over the defaults", () => {
    const engine = new SelfGovernanceRoutingEngine("A", { rehabTrust: 55 });
    const config = engine.getConfig();
    expect(config.rehabTrust).toBe(55);
    // Untouched fields keep their default values.
    expect(config.trustBlockThreshold).toBe(DEFAULT_ROUTING_CONFIG.trustBlockThreshold);
    expect(config.congestionWindowMs).toBe(DEFAULT_ROUTING_CONFIG.congestionWindowMs);
  });

  it("honours a custom trustBlockThreshold when quarantining a peer", () => {
    // A high threshold blocks a peer after a single failure, which the default
    // (25) would not do — proving the configured value drives the behavior.
    const engine = new SelfGovernanceRoutingEngine("A", { trustBlockThreshold: 65 });
    engine.upsertPeer({ id: "B", trust: 70, signal: 80, status: "online" });

    engine.applyDeliveryOutcome({
      packetId: "f1",
      peerId: "B",
      ok: false,
      latencyMs: 500,
      timestamp: Date.now(),
    });

    expect(engine.getGovernanceStats().quarantinedPeers).toBe(1);
  });

  it("does not block on a single failure under the default threshold", () => {
    const engine = new SelfGovernanceRoutingEngine("A");
    engine.upsertPeer({ id: "B", trust: 70, signal: 80, status: "online" });

    engine.applyDeliveryOutcome({
      packetId: "f1",
      peerId: "B",
      ok: false,
      latencyMs: 500,
      timestamp: Date.now(),
    });

    expect(engine.getGovernanceStats().quarantinedPeers).toBe(0);
  });

  it("honours a custom peerBlockCooldownMs so a blocked peer rehabilitates immediately", () => {
    const engine = new SelfGovernanceRoutingEngine("A", {
      trustBlockThreshold: 65,
      peerBlockCooldownMs: 0,
    });
    engine.upsertPeer({ id: "B", trust: 70, signal: 80, status: "online" });

    engine.applyDeliveryOutcome({
      packetId: "f1",
      peerId: "B",
      ok: false,
      latencyMs: 500,
      timestamp: Date.now(),
    });
    expect(engine.getGovernanceStats().quarantinedPeers).toBe(1);

    // Cooldown is 0, so the next routing pass self-heals the peer at once.
    engine.decideRoute(engine.createPacket({ to: "far", payload: {} }));
    expect(engine.getGovernanceStats().quarantinedPeers).toBe(0);
    expect(engine.getGovernanceStats().rehabilitations).toBeGreaterThanOrEqual(1);
  });
});

describe("MauriMeshP2PEngine — config forwarding", () => {
  it("forwards the routing config to its governance engine", () => {
    const engine = new MauriMeshP2PEngine("A", { trustBlockThreshold: 65 });
    engine.ingestPeer({ id: "B", trust: 70, signal: 80, status: "online" });

    engine.learn({
      packetId: "f1",
      peerId: "B",
      ok: false,
      latencyMs: 500,
      timestamp: Date.now(),
    });

    // The high threshold (forwarded into governance) blocks after one failure.
    expect(engine.getSnapshot().governance?.quarantinedPeers).toBe(1);
  });

  it("preserves the config across setLocalNodeId", () => {
    const engine = new MauriMeshP2PEngine("A", { trustBlockThreshold: 65 });
    engine.setLocalNodeId("A2");
    engine.ingestPeer({ id: "B", trust: 70, signal: 80, status: "online" });

    engine.learn({
      packetId: "f1",
      peerId: "B",
      ok: false,
      latencyMs: 500,
      timestamp: Date.now(),
    });

    expect(engine.getSnapshot().governance?.quarantinedPeers).toBe(1);
  });

  it("snapshots the passed config so later external mutation cannot leak in", () => {
    const cfg: Partial<{ trustBlockThreshold: number }> = { trustBlockThreshold: 65 };
    const engine = new MauriMeshP2PEngine("A", cfg);
    // Mutate the caller's object AFTER construction. A leaked reference would
    // drop the threshold to 1, so a single failure (trust 64) would NOT block.
    cfg.trustBlockThreshold = 1;
    engine.setLocalNodeId("A2"); // recreates governance from the stored config
    engine.ingestPeer({ id: "B", trust: 70, signal: 80, status: "online" });

    engine.learn({
      packetId: "f1",
      peerId: "B",
      ok: false,
      latencyMs: 500,
      timestamp: Date.now(),
    });

    // Threshold stayed at the snapshotted 65, so the peer is quarantined.
    expect(engine.getSnapshot().governance?.quarantinedPeers).toBe(1);
  });
});

describe("routing config defaults", () => {
  it("are frozen so they cannot be mutated process-wide", () => {
    expect(Object.isFrozen(DEFAULT_ROUTING_CONFIG)).toBe(true);
  });
});
