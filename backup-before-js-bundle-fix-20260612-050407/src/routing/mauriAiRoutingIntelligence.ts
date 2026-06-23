import {
  MauriAiRouteCandidate,
  MauriAiRouteScore,
  MauriAiSignal,
} from "../ai/mauriAiTypes";

function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

export class MauriAiRoutingIntelligence {
  scoreRoute(candidate: MauriAiRouteCandidate): MauriAiRouteScore {
    const signalScore = clamp01((candidate.rssi + 100) / 70);
    const latencyScore = clamp01(1 - Math.min(candidate.latencyMs, 3000) / 3000);
    const ackScore = clamp01(candidate.ackRate);
    const trustScore = clamp01(candidate.trustScore);
    const hopScore = clamp01(1 - Math.min(candidate.hops, 8) / 8);
    const queueScore = clamp01(1 - Math.min(candidate.queuePressure, 100) / 100);
    const recencyScore = clamp01(1 - Math.min(candidate.lastSeenAgeMs, 120000) / 120000);

    const score = clamp01(
      signalScore * 0.18 +
        latencyScore * 0.16 +
        ackScore * 0.24 +
        trustScore * 0.18 +
        hopScore * 0.08 +
        queueScore * 0.08 +
        recencyScore * 0.08
    );

    const reason = [
      `signal=${signalScore.toFixed(2)}`,
      `latency=${latencyScore.toFixed(2)}`,
      `ack=${ackScore.toFixed(2)}`,
      `trust=${trustScore.toFixed(2)}`,
      `hops=${hopScore.toFixed(2)}`,
      `queue=${queueScore.toFixed(2)}`,
      `recency=${recencyScore.toFixed(2)}`,
    ];

    return {
      peerId: candidate.peerId,
      routeId: candidate.routeId,
      score,
      reason,
    };
  }

  chooseBestRoute(candidates: MauriAiRouteCandidate[]): MauriAiRouteScore | undefined {
    return candidates
      .map(candidate => this.scoreRoute(candidate))
      .sort((a, b) => b.score - a.score)[0];
  }

  learnFromSignal(signal: MauriAiSignal): string {
    if (signal.ackSuccess) return "ACK success strengthens route trust and future selection.";
    if (signal.routeFailure) return "Route failure lowers direct confidence and increases fallback pressure.";
    if (signal.peerStale) return "Stale peer should be deprioritized and store-forward considered.";
    if (signal.rssi !== undefined) return "RSSI signal updates physical route strength.";
    return "Signal observed and retained for future route scoring.";
  }
}
