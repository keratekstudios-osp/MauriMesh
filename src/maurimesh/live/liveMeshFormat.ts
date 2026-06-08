import type { MeshNodeRecord } from "./types";

const FRESH_WINDOW_MS = 30_000;

export function timeAgo(iso?: string): string {
  if (!iso) return "never";
  const t = new Date(iso).getTime();
  if (!Number.isFinite(t) || t <= 0) return "never";
  const diff = Date.now() - t;
  if (diff < 5_000) return "just now";
  const s = Math.floor(diff / 1000);
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const d = Math.floor(h / 24);
  return `${d}d ago`;
}

export function isFresh(iso?: string, withinMs = FRESH_WINDOW_MS): boolean {
  if (!iso) return false;
  const t = new Date(iso).getTime();
  return Number.isFinite(t) && t > 0 && Date.now() - t <= withinMs;
}

export type SignalQuality = {
  label: string;
  color: string;
  bars: number; // 0..4
};

// RSSI is reported in dBm (negative; closer to 0 = stronger). 0/undefined => unknown.
export function rssiQuality(rssi?: number): SignalQuality {
  if (typeof rssi !== "number" || rssi === 0) {
    return { label: "Unknown", color: "#64748B", bars: 0 };
  }
  if (rssi >= -60) return { label: "Excellent", color: "#00D084", bars: 4 };
  if (rssi >= -72) return { label: "Good", color: "#4FC3F7", bars: 3 };
  if (rssi >= -84) return { label: "Fair", color: "#F59E0B", bars: 2 };
  return { label: "Weak", color: "#FF4D5E", bars: 1 };
}

export type RouteHealth = {
  id: string;
  label: string;
  address?: string;
  rssi?: number;
  seenCount: number;
  lastSeenAt: string;
  fresh: boolean;
  quality: SignalQuality;
  score: number; // 0..100
  tier: "Healthy" | "Fair" | "Poor";
};

// Derive a route-health score from REAL signal + recency + repeat sightings.
// Latency/packet-loss are intentionally NOT fabricated — they are not measured
// until TX/RX/ACK phases are proven (see live spine truth boundary).
export function deriveRouteHealth(node: MeshNodeRecord): RouteHealth {
  const quality = rssiQuality(node.lastRssi);
  const fresh = isFresh(node.lastSeenAt);
  const signalScore = (quality.bars / 4) * 60;
  const freshScore = fresh ? 25 : 0;
  const seenScore = (Math.min(node.seenCount, 15) / 15) * 15;
  const score = Math.round(signalScore + freshScore + seenScore);
  const tier: RouteHealth["tier"] =
    score >= 70 ? "Healthy" : score >= 40 ? "Fair" : "Poor";
  return {
    id: node.id,
    label: node.label || node.name || node.address || node.id,
    address: node.address,
    rssi: node.lastRssi,
    seenCount: node.seenCount,
    lastSeenAt: node.lastSeenAt,
    fresh,
    quality,
    score,
    tier,
  };
}

export function nodeDisplayName(node: MeshNodeRecord): string {
  return node.label || node.name || node.address || node.id;
}
