import { describe, it, expect, beforeEach } from "vitest";

// ── ACK engine data structures ────────────────────────────────────────────────

interface PendingPacket {
  id: string;
  destination: string;
  sentAt: number;
  retries: number;
  maxRetries: number;
  timeoutMs: number;
}

interface AckRecord {
  packetId: string;
  ackedAt: number;
  roundTripMs: number;
}

// ── ACK engine implementation ─────────────────────────────────────────────────

class AckEngine {
  private pending = new Map<string, PendingPacket>();
  private acked = new Map<string, AckRecord>();

  register(packet: PendingPacket): void {
    this.pending.set(packet.id, { ...packet });
  }

  acknowledge(packetId: string, nowMs = Date.now()): boolean {
    const pkt = this.pending.get(packetId);
    if (!pkt) return false;
    this.acked.set(packetId, {
      packetId,
      ackedAt: nowMs,
      roundTripMs: nowMs - pkt.sentAt,
    });
    this.pending.delete(packetId);
    return true;
  }

  getTimedOut(nowMs = Date.now()): PendingPacket[] {
    return [...this.pending.values()].filter(
      (p) => nowMs - p.sentAt > p.timeoutMs,
    );
  }

  retry(packetId: string, nowMs = Date.now()): boolean {
    const pkt = this.pending.get(packetId);
    if (!pkt) return false;
    if (pkt.retries >= pkt.maxRetries) return false;
    this.pending.set(packetId, { ...pkt, retries: pkt.retries + 1, sentAt: nowMs });
    return true;
  }

  pendingCount(): number {
    return this.pending.size;
  }

  ackedCount(): number {
    return this.acked.size;
  }

  getRoundTrip(packetId: string): number | null {
    return this.acked.get(packetId)?.roundTripMs ?? null;
  }

  isAcked(packetId: string): boolean {
    return this.acked.has(packetId);
  }

  hasPending(packetId: string): boolean {
    return this.pending.has(packetId);
  }

  averageRoundTrip(): number | null {
    if (this.acked.size === 0) return null;
    const total = [...this.acked.values()].reduce((s, r) => s + r.roundTripMs, 0);
    return total / this.acked.size;
  }
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const NOW = 1_700_000_000_000;

function makePacket(id: string, overrides: Partial<PendingPacket> = {}): PendingPacket {
  return {
    id,
    destination: "node-B",
    sentAt: NOW,
    retries: 0,
    maxRetries: 3,
    timeoutMs: 2000,
    ...overrides,
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("register", () => {
  it("adds packet to pending", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1"));
    expect(engine.pendingCount()).toBe(1);
  });
  it("pending count grows with each registered packet", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1"));
    engine.register(makePacket("p2"));
    engine.register(makePacket("p3"));
    expect(engine.pendingCount()).toBe(3);
  });
  it("registered packet is immediately hasPending", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1"));
    expect(engine.hasPending("p1")).toBe(true);
  });
  it("registered packet is not yet acked", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1"));
    expect(engine.isAcked("p1")).toBe(false);
  });
});

describe("acknowledge", () => {
  it("returns true for a pending packet", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1"));
    expect(engine.acknowledge("p1", NOW + 100)).toBe(true);
  });
  it("returns false for unknown packet", () => {
    const engine = new AckEngine();
    expect(engine.acknowledge("ghost")).toBe(false);
  });
  it("moves packet from pending to acked", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1"));
    engine.acknowledge("p1", NOW + 150);
    expect(engine.hasPending("p1")).toBe(false);
    expect(engine.isAcked("p1")).toBe(true);
  });
  it("records correct round-trip time", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1", { sentAt: NOW }));
    engine.acknowledge("p1", NOW + 350);
    expect(engine.getRoundTrip("p1")).toBe(350);
  });
});

describe("getTimedOut", () => {
  it("returns packets past their timeout", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1", { sentAt: NOW, timeoutMs: 1000 }));
    const timedOut = engine.getTimedOut(NOW + 2000);
    expect(timedOut.some((p) => p.id === "p1")).toBe(true);
  });
  it("does not return packets within timeout", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1", { sentAt: NOW, timeoutMs: 5000 }));
    expect(engine.getTimedOut(NOW + 100)).toHaveLength(0);
  });
  it("returns empty when no pending", () => {
    const engine = new AckEngine();
    expect(engine.getTimedOut(NOW + 9999)).toHaveLength(0);
  });
  it("handles mix of timed-out and live packets", () => {
    const engine = new AckEngine();
    engine.register(makePacket("slow", { sentAt: NOW, timeoutMs: 500 }));
    engine.register(makePacket("fast", { sentAt: NOW, timeoutMs: 5000 }));
    const timedOut = engine.getTimedOut(NOW + 1000);
    expect(timedOut.some((p) => p.id === "slow")).toBe(true);
    expect(timedOut.some((p) => p.id === "fast")).toBe(false);
  });
});

describe("retry", () => {
  it("increments retry count", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1"));
    engine.retry("p1", NOW + 100);
    const timedOut = engine.getTimedOut(NOW + 100 + 2001);
    const pkt = timedOut.find((p) => p.id === "p1");
    expect(pkt?.retries).toBe(1);
  });
  it("returns false for unknown packet", () => {
    const engine = new AckEngine();
    expect(engine.retry("ghost")).toBe(false);
  });
  it("returns false when max retries reached", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1", { retries: 3, maxRetries: 3 }));
    expect(engine.retry("p1")).toBe(false);
  });
  it("resets sentAt on retry to update the timeout clock", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1", { sentAt: NOW, timeoutMs: 1000 }));
    engine.retry("p1", NOW + 500);
    const timedOut = engine.getTimedOut(NOW + 600);
    expect(timedOut.some((p) => p.id === "p1")).toBe(false);
  });
});

describe("averageRoundTrip", () => {
  it("returns null when no acked packets", () => {
    const engine = new AckEngine();
    expect(engine.averageRoundTrip()).toBeNull();
  });
  it("returns correct average across multiple packets", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1", { sentAt: NOW }));
    engine.register(makePacket("p2", { sentAt: NOW }));
    engine.acknowledge("p1", NOW + 100);
    engine.acknowledge("p2", NOW + 200);
    expect(engine.averageRoundTrip()).toBe(150);
  });
  it("single packet average equals its round trip", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1", { sentAt: NOW }));
    engine.acknowledge("p1", NOW + 80);
    expect(engine.averageRoundTrip()).toBe(80);
  });
  it("unacked packets do not affect average", () => {
    const engine = new AckEngine();
    engine.register(makePacket("p1", { sentAt: NOW }));
    engine.register(makePacket("p2", { sentAt: NOW }));
    engine.acknowledge("p1", NOW + 200);
    expect(engine.averageRoundTrip()).toBe(200);
  });
});
