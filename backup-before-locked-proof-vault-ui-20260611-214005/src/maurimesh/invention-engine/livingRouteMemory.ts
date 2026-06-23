import { LearningMemory } from "./types";
import { nowMs, routeKey } from "./utils";

export class LivingRouteMemory {
  private memory = new Map<string, LearningMemory>();

  recordSuccess(nodes: string[], latencyMs: number): LearningMemory {
    const key = routeKey(nodes);
    const existing = this.memory.get(key) || {
      routeKey: key,
      successCount: 0,
      failureCount: 0,
      averageLatencyMs: latencyMs,
      trustDelta: 0,
      lastUpdatedMs: nowMs(),
    };

    const total = existing.successCount + 1;
    existing.averageLatencyMs =
      (existing.averageLatencyMs * existing.successCount + latencyMs) / total;
    existing.successCount += 1;
    existing.trustDelta += 0.03;
    existing.lastUpdatedMs = nowMs();

    this.memory.set(key, existing);
    return existing;
  }

  recordFailure(nodes: string[]): LearningMemory {
    const key = routeKey(nodes);
    const existing = this.memory.get(key) || {
      routeKey: key,
      successCount: 0,
      failureCount: 0,
      averageLatencyMs: 9999,
      trustDelta: 0,
      lastUpdatedMs: nowMs(),
    };

    existing.failureCount += 1;
    existing.trustDelta -= 0.05;
    existing.lastUpdatedMs = nowMs();

    this.memory.set(key, existing);
    return existing;
  }

  scoreRoute(nodes: string[]): number {
    const key = routeKey(nodes);
    const mem = this.memory.get(key);
    if (!mem) return 0.5;

    const attempts = mem.successCount + mem.failureCount;
    const successRatio = attempts === 0 ? 0.5 : mem.successCount / attempts;
    const latencyScore = Math.max(0, 1 - mem.averageLatencyMs / 10000);
    const trustScore = Math.max(0, Math.min(1, 0.5 + mem.trustDelta));

    return successRatio * 0.5 + latencyScore * 0.25 + trustScore * 0.25;
  }

  exportMemory(): LearningMemory[] {
    return Array.from(this.memory.values());
  }
}
