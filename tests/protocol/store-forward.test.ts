import { describe, it, expect, beforeEach } from "vitest";

// ── Store & Forward queue implementation ──────────────────────────────────────

interface QueuedMessage {
  id: string;
  destination: string;
  payload: string;
  priority: number; // 0 = low, 1 = normal, 2 = high
  enqueuedAt: number;
  ttlMs: number;
}

class StoreForwardQueue {
  private messages: QueuedMessage[] = [];
  private readonly maxCapacity: number;

  constructor(maxCapacity = 100) {
    this.maxCapacity = maxCapacity;
  }

  enqueue(msg: QueuedMessage): boolean {
    if (this.messages.length >= this.maxCapacity) return false;
    this.messages.push({ ...msg });
    return true;
  }

  dequeue(destination?: string): QueuedMessage | null {
    const now = Date.now();
    this.pruneExpired(now);

    const available = destination
      ? this.messages.filter((m) => m.destination === destination)
      : [...this.messages];

    if (available.length === 0) return null;

    available.sort((a, b) =>
      b.priority !== a.priority
        ? b.priority - a.priority
        : a.enqueuedAt - b.enqueuedAt,
    );

    const best = available[0];
    this.messages = this.messages.filter((m) => m.id !== best.id);
    return best;
  }

  pruneExpired(nowMs = Date.now()): number {
    const before = this.messages.length;
    this.messages = this.messages.filter(
      (m) => nowMs - m.enqueuedAt <= m.ttlMs,
    );
    return before - this.messages.length;
  }

  size(): number {
    return this.messages.length;
  }

  capacity(): number {
    return this.maxCapacity;
  }

  isFull(): boolean {
    return this.messages.length >= this.maxCapacity;
  }

  peek(): QueuedMessage | null {
    const live = [...this.messages].filter(
      (m) => Date.now() - m.enqueuedAt <= m.ttlMs,
    );
    if (live.length === 0) return null;
    live.sort((a, b) =>
      b.priority !== a.priority ? b.priority - a.priority : a.enqueuedAt - b.enqueuedAt,
    );
    return live[0];
  }
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const NOW = 1_700_000_000_000;

function makeMsg(id: string, overrides: Partial<QueuedMessage> = {}): QueuedMessage {
  return {
    id,
    destination: "node-C",
    payload: "hello",
    priority: 1,
    enqueuedAt: Date.now(),   // live timestamp so dequeue/peek don't prune immediately
    ttlMs: 60_000,
    ...overrides,
  };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("enqueue", () => {
  it("adds a message and increases size", () => {
    const q = new StoreForwardQueue();
    expect(q.enqueue(makeMsg("m1"))).toBe(true);
    expect(q.size()).toBe(1);
  });
  it("returns false when queue is full", () => {
    const q = new StoreForwardQueue(2);
    q.enqueue(makeMsg("m1"));
    q.enqueue(makeMsg("m2"));
    expect(q.enqueue(makeMsg("m3"))).toBe(false);
    expect(q.size()).toBe(2);
  });
  it("multiple messages enqueue correctly", () => {
    const q = new StoreForwardQueue();
    q.enqueue(makeMsg("m1"));
    q.enqueue(makeMsg("m2"));
    q.enqueue(makeMsg("m3"));
    expect(q.size()).toBe(3);
  });
  it("isFull reflects capacity state", () => {
    const q = new StoreForwardQueue(1);
    expect(q.isFull()).toBe(false);
    q.enqueue(makeMsg("m1"));
    expect(q.isFull()).toBe(true);
  });
});

describe("dequeue", () => {
  it("returns null from empty queue", () => {
    const q = new StoreForwardQueue();
    expect(q.dequeue()).toBeNull();
  });
  it("removes and returns the message", () => {
    const q = new StoreForwardQueue();
    q.enqueue(makeMsg("m1"));
    const msg = q.dequeue();
    expect(msg?.id).toBe("m1");
    expect(q.size()).toBe(0);
  });
  it("prefers higher priority messages", () => {
    const q = new StoreForwardQueue();
    const t = Date.now();
    q.enqueue(makeMsg("low",  { priority: 0, enqueuedAt: t }));
    q.enqueue(makeMsg("high", { priority: 2, enqueuedAt: t + 1 }));
    q.enqueue(makeMsg("norm", { priority: 1, enqueuedAt: t + 2 }));
    expect(q.dequeue()?.id).toBe("high");
  });
  it("at equal priority, FIFO ordering applies", () => {
    const q = new StoreForwardQueue();
    const t = Date.now();
    q.enqueue(makeMsg("first",  { priority: 1, enqueuedAt: t }));
    q.enqueue(makeMsg("second", { priority: 1, enqueuedAt: t + 10 }));
    expect(q.dequeue()?.id).toBe("first");
  });
  it("filters by destination when specified", () => {
    const q = new StoreForwardQueue();
    q.enqueue(makeMsg("m1", { destination: "node-A" }));
    q.enqueue(makeMsg("m2", { destination: "node-B" }));
    const msg = q.dequeue("node-B");
    expect(msg?.id).toBe("m2");
    expect(q.size()).toBe(1);
  });
  it("returns null when destination has no messages", () => {
    const q = new StoreForwardQueue();
    q.enqueue(makeMsg("m1", { destination: "node-A" }));
    expect(q.dequeue("node-Z")).toBeNull();
  });
});

describe("pruneExpired", () => {
  it("removes messages past their TTL", () => {
    const q = new StoreForwardQueue();
    q.enqueue(makeMsg("stale", { enqueuedAt: NOW, ttlMs: 1000 }));
    const pruned = q.pruneExpired(NOW + 2000);
    expect(pruned).toBe(1);
    expect(q.size()).toBe(0);
  });
  it("keeps messages within TTL", () => {
    const q = new StoreForwardQueue();
    q.enqueue(makeMsg("live", { enqueuedAt: NOW, ttlMs: 10_000 }));
    const pruned = q.pruneExpired(NOW + 5000);
    expect(pruned).toBe(0);
    expect(q.size()).toBe(1);
  });
  it("handles mixed expired and live messages", () => {
    const q = new StoreForwardQueue();
    q.enqueue(makeMsg("stale", { enqueuedAt: NOW, ttlMs: 500 }));
    q.enqueue(makeMsg("live",  { enqueuedAt: NOW, ttlMs: 5000 }));
    q.pruneExpired(NOW + 1000);
    expect(q.size()).toBe(1);
  });
});

describe("capacity and peek", () => {
  it("capacity returns configured max", () => {
    const q = new StoreForwardQueue(50);
    expect(q.capacity()).toBe(50);
  });
  it("peek returns highest priority without removing it", () => {
    const q = new StoreForwardQueue();
    q.enqueue(makeMsg("m1", { priority: 2 }));
    q.enqueue(makeMsg("m2", { priority: 0 }));
    expect(q.peek()?.id).toBe("m1");
    expect(q.size()).toBe(2);
  });
  it("peek returns null on empty queue", () => {
    const q = new StoreForwardQueue();
    expect(q.peek()).toBeNull();
  });
});
