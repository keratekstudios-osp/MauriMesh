// Run with: pnpm --filter @workspace/messenger-mobile test
// or: npx jest lib/mesh-core/__tests__/offline-engine.test.ts

import { MeshOfflineEngine } from "../MeshOfflineEngine";
import { MemoryMeshTransport } from "../transports/MemoryMeshTransport";
import { MeshDuplicateGuard } from "../MeshDuplicateGuard";
import { MeshStoreForwardQueue } from "../MeshStoreForwardQueue";
import { MeshTrustEngine } from "../MeshTrustEngine";
import { MeshRouteScorer } from "../MeshRouteScorer";
import { createPacket, isExpired } from "../MeshPacket";
import { resetIdentity, getNodeId } from "../MeshIdentity";
import { NodeStatus, PacketType } from "../types";

beforeEach(() => {
  resetIdentity();
});

// ── 1. Packet creation ────────────────────────────────────────────────────────

describe("createPacket", () => {
  test("creates packet with correct fields", () => {
    const nodeId = getNodeId();
    const pkt = createPacket(nodeId, {
      type: PacketType.CHAT,
      toNodeId: "peer-123",
      payload: "hello mesh",
      ttl: 4,
    });

    expect(pkt.id).toBeTruthy();
    expect(pkt.fromNodeId).toBe(nodeId);
    expect(pkt.toNodeId).toBe("peer-123");
    expect(pkt.type).toBe(PacketType.CHAT);
    expect(pkt.payload).toBe("hello mesh");
    expect(pkt.ttl).toBe(4);
    expect(pkt.routePath).toContain(nodeId);
    expect(pkt.createdAt).toBeLessThanOrEqual(Date.now());
    expect(pkt.expiresAt).toBeGreaterThan(pkt.createdAt);
  });

  test("defaults toNodeId to BROADCAST when not specified", () => {
    const pkt = createPacket(getNodeId());
    expect(pkt.toNodeId).toBe("BROADCAST");
  });

  test("expired packet check works", () => {
    const pkt = createPacket(getNodeId(), { lifetimeMs: -1 });
    expect(isExpired(pkt)).toBe(true);
  });
});

// ── 2. Duplicate guard ────────────────────────────────────────────────────────

describe("MeshDuplicateGuard", () => {
  test("rejects duplicate packet ID within window", () => {
    const guard = new MeshDuplicateGuard();
    guard.markSeen("pkt-abc");
    expect(guard.hasSeen("pkt-abc")).toBe(true);
  });

  test("accepts unseen packet ID", () => {
    const guard = new MeshDuplicateGuard();
    expect(guard.hasSeen("pkt-xyz")).toBe(false);
  });

  test("evicts entries after window expires", () => {
    const guard = new MeshDuplicateGuard(1);
    guard.markSeen("pkt-old");
    return new Promise<void>((resolve) =>
      setTimeout(() => {
        guard.evictExpired();
        expect(guard.hasSeen("pkt-old")).toBe(false);
        resolve();
      }, 10)
    );
  });
});

// ── 3. Store-forward queue ────────────────────────────────────────────────────

describe("MeshStoreForwardQueue", () => {
  test("enqueues a valid packet", () => {
    const queue = new MeshStoreForwardQueue();
    const pkt = createPacket(getNodeId(), { toNodeId: "peer-1" });
    const ok = queue.enqueue(pkt);
    expect(ok).toBe(true);
    expect(queue.size()).toBe(1);
  });

  test("rejects duplicate packet ID", () => {
    const queue = new MeshStoreForwardQueue();
    const pkt = createPacket(getNodeId());
    queue.enqueue(pkt);
    const ok = queue.enqueue(pkt);
    expect(ok).toBe(false);
    expect(queue.size()).toBe(1);
  });

  test("dequeues packets in insertion order", () => {
    const queue = new MeshStoreForwardQueue();
    const p1 = createPacket(getNodeId(), { payload: "first" });
    const p2 = createPacket(getNodeId(), { payload: "second" });
    queue.enqueue(p1);
    queue.enqueue(p2);
    expect(queue.dequeue()?.payload).toBe("first");
    expect(queue.dequeue()?.payload).toBe("second");
  });

  test("removes packet by ID", () => {
    const queue = new MeshStoreForwardQueue();
    const pkt = createPacket(getNodeId());
    queue.enqueue(pkt);
    const removed = queue.remove(pkt.id);
    expect(removed).toBe(true);
    expect(queue.size()).toBe(0);
  });
});

// ── 4. MemoryMeshTransport delivery ──────────────────────────────────────────

describe("MemoryMeshTransport", () => {
  test("delivers packet back to onReceive listener", async () => {
    const transport = new MemoryMeshTransport();
    await transport.start();

    const received: import("../types").MeshPacket[] = [];
    transport.onReceive((pkt) => received.push(pkt));

    const pkt = createPacket(getNodeId(), { type: PacketType.PULSE });
    await transport.send(pkt);

    await new Promise((r) => setTimeout(r, 100));

    expect(received).toHaveLength(1);
    expect(received[0].id).toBe(pkt.id);

    await transport.stop();
  });

  test("returns false when not running", async () => {
    const transport = new MemoryMeshTransport();
    const pkt = createPacket(getNodeId());
    const ok = await transport.send(pkt);
    expect(ok).toBe(false);
  });

  test("logs delivery steps", async () => {
    const transport = new MemoryMeshTransport();
    await transport.start();
    const pkt = createPacket(getNodeId());
    await transport.send(pkt);
    await new Promise((r) => setTimeout(r, 100));
    const logLines = transport.getDeliveryLog();
    expect(logLines.some((l) => l.includes("SEND"))).toBe(true);
    expect(logLines.some((l) => l.includes("DELIVER"))).toBe(true);
    await transport.stop();
  });
});

// ── 5. Trust score update ─────────────────────────────────────────────────────

describe("MeshTrustEngine", () => {
  test("increases trust score after successful delivery", () => {
    const engine = new MeshTrustEngine();
    const before = engine.getScore("node-x");
    engine.recordDeliverySuccess("node-x");
    expect(engine.getScore("node-x")).toBeGreaterThan(before);
  });

  test("decreases trust score after delivery failure", () => {
    const engine = new MeshTrustEngine();
    const before = engine.getScore("node-y");
    engine.recordDeliveryFailure("node-y");
    expect(engine.getScore("node-y")).toBeLessThan(before);
  });

  test("increases score on ACK receipt", () => {
    const engine = new MeshTrustEngine();
    const before = engine.getScore("node-z");
    engine.recordAck("node-z");
    expect(engine.getScore("node-z")).toBeGreaterThan(before);
  });
});

// ── 6. Route score recalculated after delivery ────────────────────────────────

describe("MeshRouteScorer", () => {
  test("ranks routes by score — trusted node scores higher than unknown", () => {
    const scorer = new MeshRouteScorer();
    const trustMap = new Map([
      ["trusted-node", { nodeId: "trusted-node", score: 90, successCount: 10, failureCount: 0, lastAckAt: Date.now() }],
      ["unknown-node", { nodeId: "unknown-node", score: 20, successCount: 0, failureCount: 5, lastAckAt: 0 }],
    ]);
    const nodes = [
      { nodeId: "trusted-node", displayName: "Trusted", status: NodeStatus.TRUSTED, rssi: -55, lastSeenAt: Date.now(), trustScore: 90 },
      { nodeId: "unknown-node", displayName: "Unknown", status: NodeStatus.UNKNOWN, rssi: -90, lastSeenAt: Date.now() - 60_000, trustScore: 20 },
    ];
    const routes = nodes.map((n) => ({
      toNodeId: n.nodeId,
      viaNodeId: n.nodeId,
      hopCount: 1,
      score: 0,
      updatedAt: n.lastSeenAt,
    }));

    const ranked = scorer.rankRoutes(nodes, routes, trustMap);
    expect(ranked[0].node.nodeId).toBe("trusted-node");
    expect(ranked[0].finalScore).toBeGreaterThan(ranked[1].finalScore);
  });
});

// ── 7. ACK recorded against original packet ID ───────────────────────────────

describe("MeshOfflineEngine ACK recording", () => {
  test("records ACK and links it to original packet ID", async () => {
    const engine = new MeshOfflineEngine();
    const transport = new MemoryMeshTransport();
    engine.attach(transport);
    await engine.start();

    const nodeId = getNodeId();

    engine.addNode({
      nodeId: "peer-ack",
      displayName: "Peer",
      status: NodeStatus.TRUSTED,
      lastSeenAt: Date.now(),
      trustScore: 80,
    });

    const sentPkt = await engine.sendPacket({
      type: PacketType.PULSE,
      toNodeId: "peer-ack",
      payload: "ack-test",
    });

    const fakePkt = createPacket("peer-ack", {
      type: PacketType.ACK,
      toNodeId: nodeId,
      payload: sentPkt.id,
    });

    engine.receivePacket(fakePkt);

    const record = engine.getAckRecord(sentPkt.id);
    expect(record).toBeDefined();
    expect(record?.packetId).toBe(sentPkt.id);
    expect(record?.fromNodeId).toBe("peer-ack");

    await engine.stop();
  });
});

// ── 8. getRouteScore returns non-zero for a known node ────────────────────────

describe("MeshOfflineEngine.getRouteScore", () => {
  test("returns a positive score for a node that is registered", () => {
    const engine = new MeshOfflineEngine();
    engine.addNode({
      nodeId: "scored-node",
      displayName: "Scored",
      status: NodeStatus.TRUSTED,
      rssi: -60,
      lastSeenAt: Date.now(),
      trustScore: 80,
    });

    const score = engine.getRouteScore("scored-node");
    expect(score).toBeGreaterThan(0);
  });

  test("returns 0 for an unknown node", () => {
    const engine = new MeshOfflineEngine();
    const score = engine.getRouteScore("nonexistent-node");
    expect(score).toBe(0);
  });

  test("trusted node scores higher than unknown node after trust update", () => {
    const engine = new MeshOfflineEngine();

    engine.addNode({
      nodeId: "trusted-peer",
      displayName: "Trusted",
      status: NodeStatus.TRUSTED,
      rssi: -50,
      lastSeenAt: Date.now(),
      trustScore: 90,
    });
    engine.addNode({
      nodeId: "unknown-peer",
      displayName: "Unknown",
      status: NodeStatus.UNKNOWN,
      rssi: -90,
      lastSeenAt: Date.now() - 45_000,
      trustScore: 20,
    });

    const trustedScore = engine.getRouteScore("trusted-peer");
    const unknownScore = engine.getRouteScore("unknown-peer");
    expect(trustedScore).toBeGreaterThan(unknownScore);
  });
});
