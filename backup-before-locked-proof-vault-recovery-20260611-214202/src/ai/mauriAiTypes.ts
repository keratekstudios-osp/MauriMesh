export type MauriAiDecision =
  | "send_direct"
  | "send_relay"
  | "send_jumpcode"
  | "store_forward"
  | "self_heal"
  | "block_unsafe"
  | "require_physical_proof";

export type MauriAiSignal = {
  peerId?: string;
  packetId?: string;
  rssi?: number;
  latencyMs?: number;
  ackSuccess?: boolean;
  routeFailure?: boolean;
  peerTrusted?: boolean;
  peerStale?: boolean;
  queueDepth?: number;
  batterySafe?: boolean;
  tikangaSafe?: boolean;
  physicalBleProven?: boolean;
};

export type MauriAiRouteCandidate = {
  peerId: string;
  routeId: string;
  hops: number;
  rssi: number;
  latencyMs: number;
  ackRate: number;
  trustScore: number;
  queuePressure: number;
  lastSeenAgeMs: number;
};

export type MauriAiRouteScore = {
  peerId: string;
  routeId: string;
  score: number;
  reason: string[];
};

export type MauriAiGovernanceResult = {
  allowed: boolean;
  decision: MauriAiDecision;
  score: number;
  warnings: string[];
  truth: string;
};

export type MauriAiRuntimeSnapshot = {
  at: number;
  decision: MauriAiDecision;
  selectedRoute?: MauriAiRouteScore;
  routeScores: MauriAiRouteScore[];
  governance: MauriAiGovernanceResult;
  memory: {
    learnedEvents: number;
    routeSuccess: number;
    routeFailure: number;
    storedPackets: number;
    forwardedPackets: number;
    healedEvents: number;
  };
  truth: string;
};
