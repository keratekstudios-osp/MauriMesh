import {
  getProofMetricsSnapshot,
  ProofMetricsSnapshot,
} from "../live/proofMetricsSpine";

export const TASK_191_ALL_INTEGRATIONS_BRIDGE_MARKER =
  "TASK_191_ALL_INTEGRATIONS_BRIDGE_20260608_A";

export type IntegrationStatus =
  | "wired"
  | "ready_for_apk"
  | "physical_proof_required"
  | "no_data_yet";

export type AllIntegrationsSnapshot = {
  marker: string;
  updatedAt: number;
  truthLevel: "physical_proof";
  proofMetrics: ProofMetricsSnapshot;
  deliveryAnalytics: {
    delivered: number;
    failed: number;
    successRate: number;
    attempted: number;
    acknowledged: number;
    relayHops: number;
    avgLatencyMs: number;
    status: IntegrationStatus;
  };
  ackTracking: {
    delivered: number;
    acked: number;
    inTransit: number;
    ackRate: number;
    status: IntegrationStatus;
  };
  storeForward: {
    total: number;
    pending: number;
    failed: number;
    reachablePeers: number;
    relayCount: number;
    deliveryCount: number;
    status: IntegrationStatus;
  };
  latency: {
    avgLatencyMs: number;
    samples: number;
    failures: number;
    reachablePeers: number;
    status: IntegrationStatus;
  };
  routeHealth: {
    healthGood: number;
    healthWeak: number;
    healthPoor: number;
    packetLossPercent: number;
    relayHops: number;
    status: IntegrationStatus;
  };
  nextPhysicalProof: string[];
};

function statusFrom(metrics: ProofMetricsSnapshot): IntegrationStatus {
  if (metrics.attempted === 0 && metrics.events.length === 0) return "no_data_yet";
  if (metrics.delivered > 0 || metrics.acknowledged > 0) return "wired";
  return "physical_proof_required";
}

export async function getAllIntegrationsSnapshot(): Promise<AllIntegrationsSnapshot> {
  const metrics = await getProofMetricsSnapshot();
  const status = statusFrom(metrics);

  const healthGood = metrics.successRate >= 80 && metrics.packetLossPercent <= 10 ? 1 : 0;
  const healthWeak =
    metrics.attempted > 0 && metrics.successRate >= 40 && metrics.successRate < 80 ? 1 : 0;
  const healthPoor =
    metrics.attempted > 0 && (metrics.successRate < 40 || metrics.packetLossPercent > 50) ? 1 : 0;

  return {
    marker: TASK_191_ALL_INTEGRATIONS_BRIDGE_MARKER,
    updatedAt: Date.now(),
    truthLevel: "physical_proof",
    proofMetrics: metrics,
    deliveryAnalytics: {
      delivered: metrics.delivered,
      failed: metrics.failed,
      successRate: metrics.successRate,
      attempted: metrics.attempted,
      acknowledged: metrics.acknowledged,
      relayHops: metrics.relayHops,
      avgLatencyMs: metrics.avgLatencyMs,
      status,
    },
    ackTracking: {
      delivered: metrics.delivered,
      acked: metrics.acknowledged,
      inTransit: metrics.inTransit,
      ackRate: metrics.ackRate,
      status,
    },
    storeForward: {
      total: metrics.storeForwardTotal,
      pending: metrics.storeForwardPending,
      failed: metrics.storeForwardFailed,
      reachablePeers: metrics.reachablePeers,
      relayCount: metrics.relayHops,
      deliveryCount: metrics.delivered,
      status,
    },
    latency: {
      avgLatencyMs: metrics.avgLatencyMs,
      samples: metrics.events.filter((event) => typeof event.latencyMs === "number").length,
      failures: metrics.failed,
      reachablePeers: metrics.reachablePeers,
      status,
    },
    routeHealth: {
      healthGood,
      healthWeak,
      healthPoor,
      packetLossPercent: metrics.packetLossPercent,
      relayHops: metrics.relayHops,
      status,
    },
    nextPhysicalProof: [
      "Install latest APK on two phones.",
      "Open /raw-packet-proof on both phones.",
      "Start receiver on both phones.",
      "Send proof packet from Phone A to Phone B.",
      "Capture Phone B RX_RAW_PACKET.",
      "Capture Phone B ACK_SENT=true.",
      "Capture Phone A ACK received.",
      "Open /ble-proof and save evidence to Proof Ledger.",
      "Open /proof-metrics and confirm metrics rise from recorded proof events.",
    ],
  };
}
