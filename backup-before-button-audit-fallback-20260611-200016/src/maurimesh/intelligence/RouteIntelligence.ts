import { RouteCandidate, RouteDecision } from "./types";

function clamp(value: number) {
  return Math.max(0, Math.min(100, Math.round(value)));
}

function scoreRoute(route: RouteCandidate): number {
  if (!route.available) return 0;

  const latencyScore = clamp(100 - route.latencyMs);
  const energyScore = clamp(100 - route.energyCost);

  return clamp(
    route.deliveryConfidence * 0.42 +
      route.trust * 0.28 +
      latencyScore * 0.18 +
      energyScore * 0.12
  );
}

export function decideBestRoute(
  candidates: RouteCandidate[] = defaultRouteCandidates
): RouteDecision {
  const scored = candidates
    .map((candidate) => ({
      candidate,
      score: scoreRoute(candidate),
    }))
    .sort((a, b) => b.score - a.score);

  const selected = scored[0]?.candidate || defaultRouteCandidates[0];
  const score = scored[0]?.score || 0;

  return {
    selected,
    candidates,
    score,
    reason:
      selected.transport === "HYBRID"
        ? "Hybrid path selected because it balances delivery confidence, trust, latency, and energy."
        : `${selected.name} selected because it has the strongest current route score.`,
  };
}

export const defaultRouteCandidates: RouteCandidate[] = [
  {
    id: "route_ble_direct",
    name: "BLE Direct",
    transport: "BLE",
    latencyMs: 42,
    trust: 78,
    energyCost: 24,
    deliveryConfidence: 72,
    available: true,
  },
  {
    id: "route_ble_relay_wifi",
    name: "BLE Relay → Wi-Fi Completion",
    transport: "HYBRID",
    latencyMs: 28,
    trust: 88,
    energyCost: 31,
    deliveryConfidence: 94,
    available: true,
  },
  {
    id: "route_store_forward",
    name: "Store-and-Forward Relay",
    transport: "BLE_RELAY",
    latencyMs: 66,
    trust: 83,
    energyCost: 18,
    deliveryConfidence: 81,
    available: true,
  },
  {
    id: "route_internet_fallback",
    name: "Internet Fallback",
    transport: "INTERNET",
    latencyMs: 35,
    trust: 70,
    energyCost: 44,
    deliveryConfidence: 86,
    available: true,
  },
];
