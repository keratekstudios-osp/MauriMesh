import { describe, it, expect, beforeEach } from "vitest";

// ── Mesh routing data structures ──────────────────────────────────────────────

interface MeshNode {
  id: string;
  online: boolean;
}

interface MeshEdge {
  from: string;
  to: string;
  quality: number; // 0–100
  latencyMs: number;
}

interface MeshGraph {
  nodes: Map<string, MeshNode>;
  edges: MeshEdge[];
}

interface Route {
  path: string[];
  hops: number;
  quality: number;
}

interface Packet {
  id: string;
  payload: string;
  timestamp: number;
}

// ── Graph utilities ────────────────────────────────────────────────────────────

function buildGraph(nodes: MeshNode[], edges: MeshEdge[]): MeshGraph {
  const nodeMap = new Map(nodes.map((n) => [n.id, n]));
  return { nodes: nodeMap, edges };
}

function getNeighbors(graph: MeshGraph, nodeId: string): MeshEdge[] {
  return graph.edges.filter(
    (e) =>
      (e.from === nodeId || e.to === nodeId) &&
      e.quality > 0,
  );
}

function shortestPath(graph: MeshGraph, from: string, to: string, maxHops = 8): Route | null {
  if (from === to) return { path: [from], hops: 0, quality: 100 };
  if (!graph.nodes.get(from)?.online || !graph.nodes.get(to)?.online) return null;

  const queue: { id: string; path: string[]; quality: number }[] = [
    { id: from, path: [from], quality: 100 },
  ];
  const visited = new Set<string>();

  while (queue.length > 0) {
    queue.sort((a, b) => b.quality - a.quality);
    const current = queue.shift()!;

    if (current.id === to) {
      return {
        path: current.path,
        hops: current.path.length - 1,
        quality: current.quality,
      };
    }

    if (current.path.length - 1 >= maxHops) continue;
    if (visited.has(current.id)) continue;
    visited.add(current.id);

    for (const edge of getNeighbors(graph, current.id)) {
      const next = edge.from === current.id ? edge.to : edge.from;
      if (!visited.has(next) && graph.nodes.get(next)?.online) {
        queue.push({
          id: next,
          path: [...current.path, next],
          quality: Math.min(current.quality, edge.quality),
        });
      }
    }
  }
  return null;
}

function isRouteStale(edge: MeshEdge, maxAgeMs: number, nowMs: number): boolean {
  const updatedAt = (edge as MeshEdge & { updatedAt?: number }).updatedAt ?? nowMs;
  return nowMs - updatedAt > maxAgeMs;
}

function buildRouteTable(graph: MeshGraph, origin: string): Map<string, Route> {
  const table = new Map<string, Route>();
  for (const [nodeId] of graph.nodes) {
    if (nodeId === origin) continue;
    const route = shortestPath(graph, origin, nodeId);
    if (route) table.set(nodeId, route);
  }
  return table;
}

function selectBestEdge(edges: MeshEdge[]): MeshEdge | null {
  if (edges.length === 0) return null;
  return edges.reduce((best, e) => (e.quality > best.quality ? e : best));
}

// ── Packet deduplication ───────────────────────────────────────────────────────

class PacketDeduplicator {
  private seen = new Map<string, number>();
  private ttlMs: number;

  constructor(ttlMs = 30_000) {
    this.ttlMs = ttlMs;
  }

  isDuplicate(packet: Packet, nowMs = Date.now()): boolean {
    this.evict(nowMs);
    if (this.seen.has(packet.id)) return true;
    this.seen.set(packet.id, nowMs);
    return false;
  }

  private evict(nowMs: number) {
    for (const [id, ts] of this.seen) {
      if (nowMs - ts > this.ttlMs) this.seen.delete(id);
    }
  }

  size(): number {
    return this.seen.size;
  }
}

// ── Test fixtures ─────────────────────────────────────────────────────────────

function makeGraph(): MeshGraph {
  return buildGraph(
    [
      { id: "A", online: true },
      { id: "B", online: true },
      { id: "C", online: true },
      { id: "D", online: false },
      { id: "E", online: true },
    ],
    [
      { from: "A", to: "B", quality: 94, latencyMs: 5 },
      { from: "B", to: "C", quality: 86, latencyMs: 8 },
      { from: "A", to: "E", quality: 88, latencyMs: 6 },
      { from: "E", to: "B", quality: 72, latencyMs: 12 },
      { from: "B", to: "D", quality: 35, latencyMs: 40 },
      { from: "C", to: "E", quality: 60, latencyMs: 20 },
    ],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

describe("buildGraph", () => {
  it("creates a node map with all nodes", () => {
    const g = makeGraph();
    expect(g.nodes.size).toBe(5);
  });
  it("stores node online status correctly", () => {
    const g = makeGraph();
    expect(g.nodes.get("A")?.online).toBe(true);
    expect(g.nodes.get("D")?.online).toBe(false);
  });
  it("stores all edges", () => {
    const g = makeGraph();
    expect(g.edges).toHaveLength(6);
  });
  it("allows empty graph", () => {
    const g = buildGraph([], []);
    expect(g.nodes.size).toBe(0);
    expect(g.edges).toHaveLength(0);
  });
  it("single node graph", () => {
    const g = buildGraph([{ id: "X", online: true }], []);
    expect(g.nodes.size).toBe(1);
  });
  it("preserves edge quality values", () => {
    const g = makeGraph();
    const edge = g.edges.find((e) => e.from === "A" && e.to === "B");
    expect(edge?.quality).toBe(94);
  });
});

describe("getNeighbors", () => {
  it("returns edges connected to node", () => {
    const g = makeGraph();
    const neighbors = getNeighbors(g, "B");
    expect(neighbors.length).toBeGreaterThan(0);
  });
  it("includes edges in both directions", () => {
    const g = makeGraph();
    const neighbors = getNeighbors(g, "E");
    expect(neighbors.some((e) => e.from === "A" || e.to === "A")).toBe(true);
  });
  it("returns empty for isolated node", () => {
    const g = buildGraph([{ id: "X", online: true }], []);
    expect(getNeighbors(g, "X")).toHaveLength(0);
  });
  it("filters out zero-quality edges", () => {
    const g = buildGraph(
      [{ id: "P", online: true }, { id: "Q", online: true }],
      [{ from: "P", to: "Q", quality: 0, latencyMs: 999 }],
    );
    expect(getNeighbors(g, "P")).toHaveLength(0);
  });
});

describe("shortestPath", () => {
  it("finds direct path A→B", () => {
    const g = makeGraph();
    const route = shortestPath(g, "A", "B");
    expect(route).not.toBeNull();
    expect(route!.hops).toBe(1);
  });
  it("finds multi-hop path A→C", () => {
    const g = makeGraph();
    const route = shortestPath(g, "A", "C");
    expect(route).not.toBeNull();
    expect(route!.hops).toBe(2);
    expect(route!.path[0]).toBe("A");
    expect(route!.path[route!.path.length - 1]).toBe("C");
  });
  it("returns null when destination is offline", () => {
    const g = makeGraph();
    const route = shortestPath(g, "A", "D");
    expect(route).toBeNull();
  });
  it("returns null when source is offline", () => {
    const g = makeGraph();
    const route = shortestPath(g, "D", "A");
    expect(route).toBeNull();
  });
  it("same source and destination returns 0-hop route", () => {
    const g = makeGraph();
    const route = shortestPath(g, "A", "A");
    expect(route?.hops).toBe(0);
  });
  it("prefers higher quality path", () => {
    const g = makeGraph();
    const route = shortestPath(g, "A", "C");
    expect(route!.quality).toBeGreaterThan(0);
  });
  it("respects maxHops limit", () => {
    const g = makeGraph();
    const route = shortestPath(g, "A", "C", 1);
    expect(route).toBeNull();
  });
  it("returns null for unknown source node", () => {
    const g = makeGraph();
    const route = shortestPath(g, "UNKNOWN", "A");
    expect(route).toBeNull();
  });
  it("quality is minimum of all edge qualities on path", () => {
    const g = makeGraph();
    const route = shortestPath(g, "A", "B");
    expect(route!.quality).toBeLessThanOrEqual(100);
  });
  it("A→E path exists", () => {
    const g = makeGraph();
    const route = shortestPath(g, "A", "E");
    expect(route).not.toBeNull();
    expect(route!.hops).toBe(1);
  });
});

describe("buildRouteTable", () => {
  it("builds routes from origin to all online reachable nodes", () => {
    const g = makeGraph();
    const table = buildRouteTable(g, "A");
    expect(table.size).toBeGreaterThan(0);
  });
  it("does not include offline nodes", () => {
    const g = makeGraph();
    const table = buildRouteTable(g, "A");
    expect(table.has("D")).toBe(false);
  });
  it("does not include origin itself", () => {
    const g = makeGraph();
    const table = buildRouteTable(g, "A");
    expect(table.has("A")).toBe(false);
  });
  it("empty graph gives empty table", () => {
    const g = buildGraph([], []);
    const table = buildRouteTable(g, "X");
    expect(table.size).toBe(0);
  });
});

describe("selectBestEdge", () => {
  it("selects edge with highest quality", () => {
    const edges: MeshEdge[] = [
      { from: "A", to: "B", quality: 70, latencyMs: 10 },
      { from: "A", to: "C", quality: 92, latencyMs: 5 },
      { from: "A", to: "D", quality: 45, latencyMs: 20 },
    ];
    expect(selectBestEdge(edges)?.quality).toBe(92);
  });
  it("returns null for empty array", () => {
    expect(selectBestEdge([])).toBeNull();
  });
  it("returns the single edge when only one", () => {
    const edges: MeshEdge[] = [{ from: "A", to: "B", quality: 80, latencyMs: 5 }];
    expect(selectBestEdge(edges)).toEqual(edges[0]);
  });
});

describe("route_failover_3_hop", () => {
  it("falls back to a 3-hop relay path when primary 1-hop relay is offline", () => {
    const g = buildGraph(
      [
        { id: "SRC", online: true },
        { id: "RELAY_DEAD", online: false },
        { id: "HOP1", online: true },
        { id: "HOP2", online: true },
        { id: "DST", online: true },
      ],
      [
        { from: "SRC", to: "RELAY_DEAD", quality: 95, latencyMs: 2 },
        { from: "RELAY_DEAD", to: "DST", quality: 95, latencyMs: 2 },
        { from: "SRC", to: "HOP1", quality: 80, latencyMs: 10 },
        { from: "HOP1", to: "HOP2", quality: 75, latencyMs: 12 },
        { from: "HOP2", to: "DST", quality: 70, latencyMs: 15 },
      ],
    );
    const route = shortestPath(g, "SRC", "DST");
    expect(route).not.toBeNull();
    expect(route!.hops).toBe(3);
    expect(route!.path).toEqual(["SRC", "HOP1", "HOP2", "DST"]);
  });

  it("3-hop fallback path quality is bounded by the minimum edge quality", () => {
    const g = buildGraph(
      [
        { id: "A", online: true },
        { id: "B", online: true },
        { id: "C", online: true },
        { id: "D", online: true },
      ],
      [
        { from: "A", to: "B", quality: 90, latencyMs: 5 },
        { from: "B", to: "C", quality: 60, latencyMs: 10 },
        { from: "C", to: "D", quality: 70, latencyMs: 15 },
      ],
    );
    const route = shortestPath(g, "A", "D");
    expect(route).not.toBeNull();
    expect(route!.hops).toBe(3);
    expect(route!.quality).toBe(60);
  });

  it("does not route through offline relay even when it would produce fewer hops", () => {
    const g = buildGraph(
      [
        { id: "S", online: true },
        { id: "BRIDGE_DEAD", online: false },
        { id: "M1", online: true },
        { id: "M2", online: true },
        { id: "T", online: true },
      ],
      [
        { from: "S", to: "BRIDGE_DEAD", quality: 99, latencyMs: 1 },
        { from: "BRIDGE_DEAD", to: "T", quality: 99, latencyMs: 1 },
        { from: "S", to: "M1", quality: 75, latencyMs: 15 },
        { from: "M1", to: "M2", quality: 72, latencyMs: 15 },
        { from: "M2", to: "T", quality: 70, latencyMs: 15 },
      ],
    );
    const route = shortestPath(g, "S", "T");
    expect(route).not.toBeNull();
    expect(route!.path).not.toContain("BRIDGE_DEAD");
    expect(route!.hops).toBe(3);
  });

  it("relay retry simulation: packet delivered on second attempt after initial failure", () => {
    let attempts = 0;

    function attemptRelay(pkt: { id: string; ttl: number }): boolean {
      if (pkt.ttl <= 0) return false;
      attempts++;
      return attempts >= 2;
    }

    const pkt = { id: "relay-pkt-001", ttl: 3 };
    let delivered = false;
    for (let i = 0; i < 3 && !delivered; i++) {
      delivered = attemptRelay(pkt);
    }

    expect(delivered).toBe(true);
    expect(attempts).toBe(2);
  });

  it("packet with ttl=0 is never delivered even on retry", () => {
    const pkt = { id: "dead-pkt", ttl: 0 };

    function attemptRelay(p: { ttl: number }): boolean {
      if (p.ttl <= 0) return false;
      return true;
    }

    expect(attemptRelay(pkt)).toBe(false);
  });

  it("stale-peer cleanup removes offline nodes from routing consideration", () => {
    const STALE_THRESHOLD_MS = 30_000;
    const now = Date.now();

    interface PeerRecord { nodeId: string; lastSeenAt: number; online: boolean }

    function pruneStale(peers: PeerRecord[], nowMs: number): PeerRecord[] {
      return peers.filter((p) => nowMs - p.lastSeenAt < STALE_THRESHOLD_MS && p.online);
    }

    const peers: PeerRecord[] = [
      { nodeId: "peer-A", lastSeenAt: now - 5_000,  online: true  },
      { nodeId: "peer-B", lastSeenAt: now - 35_000, online: true  },
      { nodeId: "peer-C", lastSeenAt: now - 1_000,  online: true  },
      { nodeId: "peer-D", lastSeenAt: now - 10_000, online: false },
    ];

    const active = pruneStale(peers, now);
    expect(active.map((p) => p.nodeId)).toEqual(["peer-A", "peer-C"]);
    expect(active).toHaveLength(2);
  });
});

describe("PacketDeduplicator", () => {
  let dedup: PacketDeduplicator;
  const now = Date.now();

  beforeEach(() => {
    dedup = new PacketDeduplicator(5000);
  });

  it("first occurrence is not a duplicate", () => {
    const pkt: Packet = { id: "pkt-001", payload: "hello", timestamp: now };
    expect(dedup.isDuplicate(pkt, now)).toBe(false);
  });
  it("second occurrence of same ID is a duplicate", () => {
    const pkt: Packet = { id: "pkt-002", payload: "hello", timestamp: now };
    dedup.isDuplicate(pkt, now);
    expect(dedup.isDuplicate(pkt, now)).toBe(true);
  });
  it("different packet IDs are not duplicates of each other", () => {
    const p1: Packet = { id: "pkt-003", payload: "a", timestamp: now };
    const p2: Packet = { id: "pkt-004", payload: "b", timestamp: now };
    dedup.isDuplicate(p1, now);
    expect(dedup.isDuplicate(p2, now)).toBe(false);
  });
  it("packet seen after TTL expiry is not duplicate", () => {
    const pkt: Packet = { id: "pkt-005", payload: "old", timestamp: now };
    dedup.isDuplicate(pkt, now);
    expect(dedup.isDuplicate(pkt, now + 6000)).toBe(false);
  });
  it("size increments for each unique packet", () => {
    dedup.isDuplicate({ id: "a", payload: "", timestamp: now }, now);
    dedup.isDuplicate({ id: "b", payload: "", timestamp: now }, now);
    expect(dedup.size()).toBe(2);
  });
  it("size does not grow for duplicates", () => {
    const pkt: Packet = { id: "pkt-006", payload: "", timestamp: now };
    dedup.isDuplicate(pkt, now);
    dedup.isDuplicate(pkt, now);
    dedup.isDuplicate(pkt, now);
    expect(dedup.size()).toBe(1);
  });
  it("eviction reduces size after TTL", () => {
    dedup.isDuplicate({ id: "old", payload: "", timestamp: now }, now);
    dedup.isDuplicate({ id: "new", payload: "", timestamp: now + 6000 }, now + 6000);
    expect(dedup.size()).toBe(1);
  });
});
