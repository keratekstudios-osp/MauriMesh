import { RouteEdge, RouteNode, RoutePlan, TransportKind } from "../types/core.types";
import { clamp01, weightedAverage } from "../math/mathIntelligence";

export function scoreRouteEdge(edge: RouteEdge, destinationTrust: number): number {
  const latencyScore = clamp01(1 - edge.latencyMs / 2000);
  const privacyScore = clamp01(1 - edge.privacyRisk);
  const batteryScore = clamp01(1 - edge.batteryCost);

  return weightedAverage([
    { value: edge.ackSuccess, weight: 1.414 },
    { value: privacyScore, weight: 1.414 },
    { value: destinationTrust, weight: 1.2 },
    { value: latencyScore, weight: 1 },
    { value: batteryScore, weight: 1 },
  ]);
}

export function planRoute(input: {
  from: string;
  to: string;
  nodes: RouteNode[];
  edges: RouteEdge[];
  preferredTransport?: TransportKind;
}): RoutePlan {
  const nodeById = new Map(input.nodes.map((node) => [node.id, node]));
  const start = nodeById.get(input.from);
  const target = nodeById.get(input.to);

  if (!start || !target) {
    return {
      allowed: false,
      selectedPath: [],
      transport: "STORE_FORWARD",
      score: 0,
      reason: "Sender or recipient node not found.",
      fallback: "STORE_FORWARD",
      requiresProof: true,
    };
  }

  const directEdges = input.edges.filter((edge) => edge.from === input.from && edge.to === input.to);
  const oneHopRoutes: Array<{ path: string[]; edgeScore: number; transport: TransportKind }> = [];

  for (const edge of directEdges) {
    oneHopRoutes.push({
      path: [input.from, input.to],
      edgeScore: scoreRouteEdge(edge, target.trust),
      transport: edge.transport,
    });
  }

  for (const first of input.edges.filter((edge) => edge.from === input.from)) {
    const relay = nodeById.get(first.to);
    if (!relay || !relay.online) continue;

    for (const second of input.edges.filter((edge) => edge.from === relay.id && edge.to === input.to)) {
      const scoreA = scoreRouteEdge(first, relay.trust);
      const scoreB = scoreRouteEdge(second, target.trust);

      oneHopRoutes.push({
        path: [input.from, relay.id, input.to],
        edgeScore: Math.min(scoreA, scoreB),
        transport: first.transport,
      });
    }
  }

  const viable = oneHopRoutes
    .filter((route) => {
      if (!input.preferredTransport) return true;
      return route.transport === input.preferredTransport;
    })
    .sort((a, b) => b.edgeScore - a.edgeScore);

  const best = viable[0];

  if (!best || best.edgeScore < 0.45) {
    return {
      allowed: true,
      selectedPath: [input.from],
      transport: "STORE_FORWARD",
      score: best?.edgeScore ?? 0,
      reason: "No safe verified route found. Store-forward selected.",
      fallback: "STORE_FORWARD",
      requiresProof: true,
    };
  }

  return {
    allowed: true,
    selectedPath: best.path,
    transport: best.transport,
    score: best.edgeScore,
    reason: "Safest verified route selected using trust, ACK, privacy, latency, and battery scoring.",
    fallback: "STORE_FORWARD",
    requiresProof: true,
  };
}
