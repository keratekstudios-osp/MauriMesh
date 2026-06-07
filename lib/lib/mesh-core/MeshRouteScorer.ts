import type { MeshNode, RouteEntry, TrustRecord } from "./types";

export interface ScoredRoute {
  node: MeshNode;
  route: RouteEntry;
  finalScore: number;
}

export interface ScorerOptions {
  trustWeight?: number;
  hopWeight?: number;
  rssiWeight?: number;
  recencyWeight?: number;
}

const DEFAULT_WEIGHTS: Required<ScorerOptions> = {
  trustWeight: 0.35,
  hopWeight: 0.25,
  rssiWeight: 0.25,
  recencyWeight: 0.15,
};

export class MeshRouteScorer {
  private weights: Required<ScorerOptions>;

  constructor(opts: ScorerOptions = {}) {
    this.weights = { ...DEFAULT_WEIGHTS, ...opts };
  }

  scoreRoute(
    node: MeshNode,
    route: RouteEntry,
    trust: TrustRecord | undefined
  ): number {
    const trustScore = this.normalizeTrust(trust?.score ?? 50);
    const hopScore = this.normalizeHops(route.hopCount);
    const rssiScore = this.normalizeRssi(node.rssi);
    const recencyScore = this.normalizeRecency(node.lastSeenAt);

    return (
      trustScore * this.weights.trustWeight +
      hopScore * this.weights.hopWeight +
      rssiScore * this.weights.rssiWeight +
      recencyScore * this.weights.recencyWeight
    );
  }

  rankRoutes(
    nodes: MeshNode[],
    routes: RouteEntry[],
    trustMap: Map<string, TrustRecord>
  ): ScoredRoute[] {
    const scored: ScoredRoute[] = [];

    for (const node of nodes) {
      const route = routes.find((r) => r.toNodeId === node.nodeId);
      if (!route) continue;
      const trust = trustMap.get(node.nodeId);
      const finalScore = this.scoreRoute(node, route, trust);
      scored.push({ node, route, finalScore });
    }

    return scored.sort((a, b) => b.finalScore - a.finalScore);
  }

  private normalizeTrust(score: number): number {
    return Math.max(0, Math.min(100, score)) / 100;
  }

  private normalizeHops(hops: number): number {
    if (hops <= 1) return 1.0;
    if (hops <= 2) return 0.75;
    if (hops <= 3) return 0.5;
    if (hops <= 4) return 0.25;
    return 0.1;
  }

  private normalizeRssi(rssi?: number): number {
    if (rssi == null) return 0.4;
    if (rssi >= -50) return 1.0;
    if (rssi >= -70) return 0.7;
    if (rssi >= -85) return 0.4;
    if (rssi >= -100) return 0.2;
    return 0.05;
  }

  private normalizeRecency(lastSeenAt: number): number {
    const ageMs = Date.now() - lastSeenAt;
    if (ageMs < 5_000) return 1.0;
    if (ageMs < 15_000) return 0.8;
    if (ageMs < 30_000) return 0.5;
    if (ageMs < 60_000) return 0.3;
    return 0.1;
  }
}
