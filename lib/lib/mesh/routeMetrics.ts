/**
 * routeMetrics — real delivery-outcome feedback loop for MauriMesh routing.
 *
 * Per-peer RouteMetrics are accumulated from actual BLE send results and ACK
 * latencies, then persisted in AsyncStorage so the routing table survives
 * app restarts.
 *
 * RouteScore formula:
 *   score = successRate * 0.5
 *         + signalScore  * 0.2
 *         + latencyScore * 0.2
 *         + recencyScore * 0.1
 *
 * All components normalised to [0, 1].
 */

import AsyncStorage from "@react-native-async-storage/async-storage";

const KEY = "@maurimesh/route_metrics_v1";

// ── Types ─────────────────────────────────────────────────────────────────────

export interface RouteMetrics {
  peerId: string;
  successCount: number;
  failureCount: number;
  /** Exponential moving average of ACK round-trip latency in ms. */
  avgLatency: number;
  lastSuccessAt: number;
  lastFailureAt: number;
}

// ── Defaults ──────────────────────────────────────────────────────────────────

function emptyMetrics(peerId: string): RouteMetrics {
  return {
    peerId,
    successCount: 0,
    failureCount: 0,
    avgLatency: 0,
    lastSuccessAt: 0,
    lastFailureAt: 0,
  };
}

// ── Persistence ───────────────────────────────────────────────────────────────

export async function loadAllMetrics(): Promise<Map<string, RouteMetrics>> {
  try {
    const raw = await AsyncStorage.getItem(KEY);
    const arr: RouteMetrics[] = raw ? (JSON.parse(raw) as RouteMetrics[]) : [];
    return new Map(arr.map((m) => [m.peerId, m]));
  } catch {
    return new Map();
  }
}

async function _saveAllMetrics(metrics: Map<string, RouteMetrics>): Promise<void> {
  try {
    await AsyncStorage.setItem(KEY, JSON.stringify([...metrics.values()]));
  } catch {
    // non-fatal
  }
}

// ── Mutations (mutate the shared map in place, then persist) ──────────────────

/**
 * Record a successful delivery for `peerId`. `latencyMs` is the full
 * round-trip time from send to ACK receipt; pass 0 when only a BLE write
 * acknowledgement is available (no end-to-end ACK yet).
 */
export async function recordSuccess(
  metrics: Map<string, RouteMetrics>,
  peerId: string,
  latencyMs: number
): Promise<void> {
  const m = metrics.get(peerId) ?? emptyMetrics(peerId);
  const newSuccess = m.successCount + 1;
  // Exponential moving average (α = 0.3) so recent latencies have more weight
  const newAvg =
    m.avgLatency === 0 || latencyMs === 0
      ? latencyMs || m.avgLatency
      : Math.round(m.avgLatency * 0.7 + latencyMs * 0.3);
  const updated: RouteMetrics = {
    ...m,
    successCount: newSuccess,
    avgLatency: newAvg,
    lastSuccessAt: Date.now(),
  };
  metrics.set(peerId, updated);
  console.log(
    `[MauriMesh][RouteScore] success peerId=${peerId} successCount=${newSuccess} avgLatency=${newAvg}ms`
  );
  await _saveAllMetrics(metrics);
}

export async function recordFailure(
  metrics: Map<string, RouteMetrics>,
  peerId: string
): Promise<void> {
  const m = metrics.get(peerId) ?? emptyMetrics(peerId);
  const updated: RouteMetrics = {
    ...m,
    failureCount: m.failureCount + 1,
    lastFailureAt: Date.now(),
  };
  metrics.set(peerId, updated);
  console.log(
    `[MauriMesh][RouteScore] failure peerId=${peerId} failureCount=${updated.failureCount}`
  );
  await _saveAllMetrics(metrics);
}

// ── Score computation ─────────────────────────────────────────────────────────

/**
 * Compute a [0, 1] RouteScore for a peer.
 * `metrics` may be undefined when a peer has never been contacted.
 * `rssi` should be the current BLE advertisement RSSI value (e.g. −65).
 */
export function computeRouteScore(
  metrics: RouteMetrics | undefined,
  rssi: number
): number {
  // successRate — default 0.5 (optimistic) with no data so new peers are tried
  const total = (metrics?.successCount ?? 0) + (metrics?.failureCount ?? 0);
  const successRate = total > 0 ? (metrics!.successCount / total) : 0.5;

  // signalScore — RSSI normalised: −45 dBm → 1.0, −100 dBm → 0.0
  const clampedRssi = Math.max(-100, Math.min(-45, rssi));
  const signalScore = (clampedRssi + 100) / 55;

  // latencyScore — 0 ms (or unknown) → 0.7, 200 ms → ~0.96, 5000 ms → 0.0
  const latency = metrics?.avgLatency ?? 0;
  const latencyScore = latency === 0 ? 0.7 : Math.max(0, 1 - latency / 5_000);

  // recencyScore — how recently the peer was successfully reached
  const lastSuccess = metrics?.lastSuccessAt ?? 0;
  const ageMs = lastSuccess > 0 ? Date.now() - lastSuccess : Infinity;
  const recencyScore =
    ageMs < 30_000  ? 1.0 :
    ageMs < 300_000 ? 0.5 :
    lastSuccess > 0 ? 0.2 : 0.3;

  const score =
    successRate  * 0.5 +
    signalScore  * 0.2 +
    latencyScore * 0.2 +
    recencyScore * 0.1;

  return Math.max(0, Math.min(1, score));
}

export function getMetrics(
  metricsMap: Map<string, RouteMetrics>,
  peerId: string
): RouteMetrics {
  return metricsMap.get(peerId) ?? emptyMetrics(peerId);
}
