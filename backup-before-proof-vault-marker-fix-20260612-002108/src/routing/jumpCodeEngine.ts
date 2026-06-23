import { MauriAiRouteCandidate } from "../ai/mauriAiTypes";

export type JumpCodePath = {
  id: string;
  fromPeerId: string;
  toPeerId: string;
  relayPeerIds: string[];
  jumpScore: number;
  reason: string[];
};

function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

export class JumpCodeEngine {
  createJumpCodePath(
    fromPeerId: string,
    toPeerId: string,
    candidates: MauriAiRouteCandidate[]
  ): JumpCodePath {
    const relays = candidates
      .filter(candidate => candidate.peerId !== fromPeerId && candidate.peerId !== toPeerId)
      .sort((a, b) => b.ackRate + b.trustScore - (a.ackRate + a.trustScore))
      .slice(0, 3);

    const avgRelay =
      relays.length === 0
        ? 0
        : relays.reduce((sum, relay) => sum + relay.ackRate + relay.trustScore, 0) /
          (relays.length * 2);

    const jumpScore = clamp01(avgRelay * 0.7 + Math.min(relays.length, 3) / 3 * 0.3);

    return {
      id: `jump_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`,
      fromPeerId,
      toPeerId,
      relayPeerIds: relays.map(relay => relay.peerId),
      jumpScore,
      reason: [
        `relayCount=${relays.length}`,
        `avgRelayTrustAck=${avgRelay.toFixed(2)}`,
        `jumpScore=${jumpScore.toFixed(2)}`,
      ],
    };
  }

  shouldUseJumpCode(bestRouteScore: number): boolean {
    return bestRouteScore < 0.62 && bestRouteScore >= 0.32;
  }
}
