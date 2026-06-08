import {
  loadActiveRouteBlacklistEntries,
  saveRouteBlacklistEntry,
} from "./RouteSafetyBlacklistStore";

export const ROUTE_SAFETY_ENGINE_MARKER =
  "ROUTE_SAFETY_ENGINE_PERSISTENT_20260608_A";

export type RouteSafetyDecision =
  | { ok: true; reason: "accepted" }
  | { ok: false; reason: "blacklisted" | "ttl_expired" | "duplicate" | "malformed" };

type FailureRecord = {
  count: number;
  lastFailureAt: number;
  reason: string;
};

export class RouteSafetyEngine {
  private seenPackets = new Set<string>();
  private failureCounts = new Map<string, FailureRecord>();
  private blacklistedRoutes = new Map<string, number>();
  private hydrated = false;

  constructor(
    private readonly options: {
      failureThreshold?: number;
      cooldownMs?: number;
      seenCacheLimit?: number;
    } = {}
  ) {}

  private get failureThreshold() {
    return this.options.failureThreshold ?? 3;
  }

  private get cooldownMs() {
    return this.options.cooldownMs ?? 10 * 60 * 1000;
  }

  private get seenCacheLimit() {
    return this.options.seenCacheLimit ?? 10000;
  }

  async init(): Promise<void> {
    if (this.hydrated) return;

    const entries = await loadActiveRouteBlacklistEntries(this.cooldownMs);
    const now = Date.now();

    for (const entry of entries) {
      const expiresAt = Date.parse(entry.expiresAt);
      if (Number.isFinite(expiresAt) && expiresAt > now) {
        this.blacklistedRoutes.set(entry.routeKey, expiresAt);
      }
    }

    this.hydrated = true;
  }

  async checkPacket(input: {
    packetId?: string;
    routeKey: string;
    ttl?: number;
    raw?: unknown;
  }): Promise<RouteSafetyDecision> {
    await this.init();

    const now = Date.now();
    const blacklistExpiry = this.blacklistedRoutes.get(input.routeKey);

    if (blacklistExpiry && blacklistExpiry > now) {
      return { ok: false, reason: "blacklisted" };
    }

    if (!input.routeKey || !input.raw) {
      await this.recordFailure(input.routeKey || "unknown", "malformed");
      return { ok: false, reason: "malformed" };
    }

    if (typeof input.ttl === "number" && input.ttl <= 0) {
      await this.recordFailure(input.routeKey, "ttl_expired");
      return { ok: false, reason: "ttl_expired" };
    }

    if (input.packetId && this.seenPackets.has(input.packetId)) {
      await this.recordFailure(input.routeKey, "duplicate");
      return { ok: false, reason: "duplicate" };
    }

    if (input.packetId) {
      this.seenPackets.add(input.packetId);
      this.trimSeenCache();
    }

    return { ok: true, reason: "accepted" };
  }

  async recordFailure(routeKey: string, reason: string): Promise<void> {
    await this.init();

    const key = routeKey || "unknown";
    const current = this.failureCounts.get(key) || {
      count: 0,
      lastFailureAt: 0,
      reason,
    };

    const next: FailureRecord = {
      count: current.count + 1,
      lastFailureAt: Date.now(),
      reason,
    };

    this.failureCounts.set(key, next);

    if (next.count >= this.failureThreshold) {
      const expiresAtMs = Date.now() + this.cooldownMs;
      this.blacklistedRoutes.set(key, expiresAtMs);

      await saveRouteBlacklistEntry({
        routeKey: key,
        reason,
        failureCount: next.count,
        blacklistedAt: new Date().toISOString(),
        expiresAt: new Date(expiresAtMs).toISOString(),
        cooldownMs: this.cooldownMs,
        source: ROUTE_SAFETY_ENGINE_MARKER,
      });
    }
  }

  isBlacklisted(routeKey: string): boolean {
    const expiry = this.blacklistedRoutes.get(routeKey);
    return Boolean(expiry && expiry > Date.now());
  }

  getBlacklistSnapshot() {
    const now = Date.now();

    return Array.from(this.blacklistedRoutes.entries())
      .filter(([, expiresAt]) => expiresAt > now)
      .map(([routeKey, expiresAt]) => ({
        routeKey,
        expiresAt: new Date(expiresAt).toISOString(),
      }));
  }

  private trimSeenCache(): void {
    if (this.seenPackets.size <= this.seenCacheLimit) return;

    const keep = Array.from(this.seenPackets).slice(-this.seenCacheLimit);
    this.seenPackets = new Set(keep);
  }
}

export const routeSafetyEngine = new RouteSafetyEngine();
