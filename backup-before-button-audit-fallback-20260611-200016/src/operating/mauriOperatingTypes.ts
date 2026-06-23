export type MauriOperatingDomain =
  | "foundation"
  | "physical"
  | "transport"
  | "packet"
  | "routing"
  | "learning"
  | "healing"
  | "tikanga"
  | "whanau"
  | "observability"
  | "experience"
  | "proof";

export type MauriLayerState =
  | "idle"
  | "observing"
  | "ready"
  | "learning"
  | "fallback"
  | "repairing"
  | "blocked";

export type MauriLayerCriticality =
  | "core"
  | "high"
  | "medium"
  | "support";

export type MauriOperatingLayer = {
  id: string;
  index: number;
  domain: MauriOperatingDomain;
  name: string;
  purpose: string;
  criticality: MauriLayerCriticality;
  state: MauriLayerState;
  score: number;
  learnsFrom: MauriOperatingDomain[];
  teachesTo: MauriOperatingDomain[];
};

export type MauriOperatingSignal = {
  id: string;
  at: number;
  sourceLayerId: string;
  type:
    | "observe"
    | "route_success"
    | "route_failure"
    | "ack_received"
    | "peer_seen"
    | "peer_lost"
    | "fallback_used"
    | "repair_started"
    | "repair_success"
    | "tikanga_warning"
    | "truth_required"
    | "proof_required"
    | "runtime_tick";
  confidence: number;
  impact: number;
  lesson: string;
  data?: Record<string, unknown>;
};

export type MauriDomainScore = {
  domain: MauriOperatingDomain;
  score: number;
  layers: number;
  ready: number;
  learning: number;
  fallback: number;
  repairing: number;
  blocked: number;
};

export type MauriOperatingDecision =
  | "operate_strong"
  | "operate_monitored"
  | "fallback_store_forward"
  | "self_heal"
  | "block_unsafe_or_unproven";

export type MauriOperatingSnapshot = {
  at: number;
  layerCount: number;
  domainScores: MauriDomainScore[];
  wholeSystemScore: number;
  decision: MauriOperatingDecision;
  truth: string;
  strongestLayers: MauriOperatingLayer[];
  weakestLayers: MauriOperatingLayer[];
  latestSignals: MauriOperatingSignal[];
};
