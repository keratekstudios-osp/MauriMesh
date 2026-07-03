import { useEffect, useRef, useState } from "react";
import type { MeshMetricSnapshot } from "./types";

// A single point in the client-side rolling history. The live metrics spine
// only ever reports a cumulative snapshot, so we sample it over time here to
// build genuine time-series — no values are fabricated, every point is a real
// reading captured at the moment it arrived from the BLE bridge.
export type MetricSample = {
  t: number; // epoch ms when the sample was captured
  averageLatencyMs: number;
  deliveryCount: number;
  failureCount: number;
  relayCount: number;
  ackCount: number;
};

export const FIVE_MIN_MS = 5 * 60 * 1000;

// Accumulate a rolling window of real metric snapshots. Appends a new point
// whenever the live source reports a fresh `updatedAt`, and prunes anything
// older than `windowMs` so the series stays a true rolling window.
export function useMeshHistory(
  metrics: MeshMetricSnapshot,
  updatedAt: string,
  windowMs = FIVE_MIN_MS,
): MetricSample[] {
  const [samples, setSamples] = useState<MetricSample[]>([]);
  const lastStamp = useRef<string>("");

  useEffect(() => {
    if (!updatedAt || updatedAt === lastStamp.current) return;
    lastStamp.current = updatedAt;
    const now = Date.now();
    setSamples((prev) => {
      const next = [
        ...prev,
        {
          t: now,
          averageLatencyMs: metrics.averageLatencyMs,
          deliveryCount: metrics.deliveryCount,
          failureCount: metrics.failureCount,
          relayCount: metrics.relayCount,
          ackCount: metrics.ackCount,
        },
      ];
      const cutoff = now - windowMs;
      return next.filter((s) => s.t >= cutoff);
    });
  }, [
    updatedAt,
    windowMs,
    metrics.averageLatencyMs,
    metrics.deliveryCount,
    metrics.failureCount,
    metrics.relayCount,
    metrics.ackCount,
  ]);

  return samples;
}

// Linear-interpolated quantile of an already-sorted ascending array.
export function quantile(sorted: number[], q: number): number {
  if (sorted.length === 0) return 0;
  if (sorted.length === 1) return sorted[0];
  const pos = (sorted.length - 1) * q;
  const base = Math.floor(pos);
  const rest = pos - base;
  const next = sorted[base + 1];
  if (next !== undefined) {
    return sorted[base] + rest * (next - sorted[base]);
  }
  return sorted[base];
}

function bucketIndex(t: number, bucketMs: number): number {
  return Math.floor(t / bucketMs);
}

// Number of buckets that span a window at a given bucket size.
export function bucketCount(windowMs: number, bucketMs: number): number {
  return Math.max(1, Math.ceil(windowMs / bucketMs));
}

// Group the rolling samples into fixed time buckets and, for each bucket,
// compute P50/P90/P99 of the real latency readings that fell inside it.
// Buckets with no readings report 0 (truthful — nothing was measured).
export function bucketPercentiles(
  samples: MetricSample[],
  now: number,
  windowMs: number,
  bucketMs: number,
): { p50: number[]; p90: number[]; p99: number[] } {
  const count = bucketCount(windowMs, bucketMs);
  const startIdx = bucketIndex(now, bucketMs) - count + 1;
  const groups: number[][] = Array.from({ length: count }, () => []);
  for (const s of samples) {
    const slot = bucketIndex(s.t, bucketMs) - startIdx;
    if (slot >= 0 && slot < count) groups[slot].push(s.averageLatencyMs);
  }
  const p50: number[] = [];
  const p90: number[] = [];
  const p99: number[] = [];
  for (const g of groups) {
    const sorted = [...g].sort((a, b) => a - b);
    p50.push(Math.round(quantile(sorted, 0.5)));
    p90.push(Math.round(quantile(sorted, 0.9)));
    p99.push(Math.round(quantile(sorted, 0.99)));
  }
  return { p50, p90, p99 };
}

// Bucket the per-interval change (delta) of a cumulative counter field.
// Cumulative counts only ever increase, so deltas are clamped at >= 0.
export function bucketDeltas(
  samples: MetricSample[],
  now: number,
  windowMs: number,
  bucketMs: number,
  field: "deliveryCount" | "failureCount" | "relayCount" | "ackCount",
): number[] {
  const count = bucketCount(windowMs, bucketMs);
  const startIdx = bucketIndex(now, bucketMs) - count + 1;
  const sums = new Array<number>(count).fill(0);
  for (let i = 1; i < samples.length; i++) {
    const prev = samples[i - 1];
    const cur = samples[i];
    const delta = Math.max(0, cur[field] - prev[field]);
    const slot = bucketIndex(cur.t, bucketMs) - startIdx;
    if (slot >= 0 && slot < count) sums[slot] += delta;
  }
  return sums;
}
