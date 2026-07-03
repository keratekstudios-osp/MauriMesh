import { MauriMeshDecision, MauriMeshRouteCandidate, MauriMeshTransport } from "../types";

function clamp(value: number) {
  return Math.max(0, Math.min(100, Math.round(value)));
}

export function mauriMeshScoreRoute(input: {
  id: string;
  path: string[];
  transport: MauriMeshTransport;
  latencyMs?: number;
  trust?: number;
  resilience?: number;
  governance?: number;
  congestion?: number;
}): MauriMeshRouteCandidate {
  const latencyScore = clamp(100 - Math.min(input.latencyMs ?? 50, 100));
  const trustScore = clamp(input.trust ?? 50);
  const resilienceScore = clamp(input.resilience ?? 50);
  const governanceScore = clamp(input.governance ?? 50);
  const congestionScore = clamp(100 - (input.congestion ?? 0));

  const finalScore = clamp(
    latencyScore * 0.18 +
      trustScore * 0.28 +
      resilienceScore * 0.24 +
      governanceScore * 0.22 +
      congestionScore * 0.08
  );

  let decision: MauriMeshDecision = "APPROVED";
  let reason = "Route accepted.";

  if (governanceScore < 40) {
    decision = "REVIEW_REQUIRED";
    reason = "Governance score below safe threshold.";
  }

  if (trustScore < 30 || resilienceScore < 30) {
    decision = "APPROVED_WITH_WARNING";
    reason = "Route usable but weak trust/resilience detected.";
  }

  if (finalScore < 35) {
    decision = "BLOCKED";
    reason = "Route score too weak for safe delivery.";
  }

  return {
    id: input.id,
    path: input.path,
    transport: input.transport,
    latencyScore,
    trustScore,
    resilienceScore,
    governanceScore,
    congestionScore,
    finalScore,
    decision,
    reason,
  };
}

export function mauriMeshChooseBestRoute(routes: MauriMeshRouteCandidate[]) {
  const usable = routes.filter((route) => route.decision !== "BLOCKED" && route.decision !== "REFUSED");
  const pool = usable.length ? usable : routes;
  return [...pool].sort((a, b) => b.finalScore - a.finalScore)[0];
}
