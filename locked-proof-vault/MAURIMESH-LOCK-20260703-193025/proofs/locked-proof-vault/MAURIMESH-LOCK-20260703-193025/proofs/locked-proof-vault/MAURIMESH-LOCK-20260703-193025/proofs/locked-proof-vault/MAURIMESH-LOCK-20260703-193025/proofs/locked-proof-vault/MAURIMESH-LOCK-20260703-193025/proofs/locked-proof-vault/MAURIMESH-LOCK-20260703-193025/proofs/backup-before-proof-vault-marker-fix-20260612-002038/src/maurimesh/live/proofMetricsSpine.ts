import AsyncStorage from "@react-native-async-storage/async-storage";

export const TASK_190_PROOF_METRICS_SPINE_MARKER =
  "TASK_190_PROOF_METRICS_SPINE_20260608_A";

const STORAGE_KEY = "maurimesh.proof.metrics.spine.v1";

export type ProofMetricEventType =
  | "send_attempt"
  | "send_submitted"
  | "rx_packet"
  | "ack_sent"
  | "ack_received"
  | "delivery_failed"
  | "relay_hop"
  | "store_forward_enqueued"
  | "store_forward_released";

export type ProofMetricEvent = {
  id: string;
  type: ProofMetricEventType;
  packetId: string;
  at: number;
  fromNode?: string;
  toNode?: string;
  transport?: "BLE" | "WIFI_DIRECT" | "LOCAL_WIFI" | "INTERNET" | "UNKNOWN";
  latencyMs?: number;
  relayHopCount?: number;
  peerId?: string;
  reason?: string;
  payloadBytes?: number;
  raw?: unknown;
};

export type ProofMetricsSnapshot = {
  marker: string;
  truthLevel: "physical_proof";
  updatedAt: number;

  attempted: number;
  delivered: number;
  acknowledged: number;
  failed: number;
  inTransit: number;

  ackRate: number;
  successRate: number;
  relayHops: number;
  avgLatencyMs: number;

  storeForwardTotal: number;
  storeForwardPending: number;
  storeForwardFailed: number;

  packetLossPercent: number;
  reachablePeers: number;
  knownPeers: number;

  events: ProofMetricEvent[];
};

const emptySnapshot = (): ProofMetricsSnapshot => ({
  marker: TASK_190_PROOF_METRICS_SPINE_MARKER,
  truthLevel: "physical_proof",
  updatedAt: Date.now(),

  attempted: 0,
  delivered: 0,
  acknowledged: 0,
  failed: 0,
  inTransit: 0,

  ackRate: 0,
  successRate: 0,
  relayHops: 0,
  avgLatencyMs: 0,

  storeForwardTotal: 0,
  storeForwardPending: 0,
  storeForwardFailed: 0,

  packetLossPercent: 0,
  reachablePeers: 0,
  knownPeers: 0,

  events: [],
});

function uniquePacketCount(events: ProofMetricEvent[], type: ProofMetricEventType): number {
  return new Set(events.filter((e) => e.type === type).map((e) => e.packetId)).size;
}

function count(events: ProofMetricEvent[], type: ProofMetricEventType): number {
  return events.filter((e) => e.type === type).length;
}

function calculate(events: ProofMetricEvent[]): ProofMetricsSnapshot {
  const latest = events.slice(-500);

  const attempted = uniquePacketCount(latest, "send_attempt");
  const submitted = uniquePacketCount(latest, "send_submitted");
  const rx = uniquePacketCount(latest, "rx_packet");
  const ackSent = uniquePacketCount(latest, "ack_sent");
  const ackReceived = uniquePacketCount(latest, "ack_received");
  const failed = uniquePacketCount(latest, "delivery_failed");

  const delivered = Math.max(rx, ackReceived);
  const acknowledged = Math.max(ackSent, ackReceived);
  const inTransit = Math.max(0, submitted - delivered - failed);

  const latencies = latest
    .map((e) => e.latencyMs)
    .filter((n): n is number => typeof n === "number" && Number.isFinite(n) && n >= 0);

  const avgLatencyMs =
    latencies.length > 0
      ? Math.round(latencies.reduce((sum, n) => sum + n, 0) / latencies.length)
      : 0;

  const relayHops = latest.reduce((sum, e) => sum + (e.relayHopCount || 0), 0);

  const storeForwardTotal = count(latest, "store_forward_enqueued");
  const storeForwardReleased = count(latest, "store_forward_released");
  const storeForwardFailed = count(latest, "delivery_failed");
  const storeForwardPending = Math.max(0, storeForwardTotal - storeForwardReleased - storeForwardFailed);

  const ackRate = attempted > 0 ? Math.round((acknowledged / attempted) * 100) : 0;
  const successRate = attempted > 0 ? Math.round((delivered / attempted) * 100) : 0;
  const packetLossPercent = attempted > 0 ? Math.round((failed / attempted) * 100) : 0;

  const peerSet = new Set<string>();
  latest.forEach((e) => {
    if (e.peerId) peerSet.add(e.peerId);
    if (e.fromNode) peerSet.add(e.fromNode);
    if (e.toNode) peerSet.add(e.toNode);
  });

  return {
    ...emptySnapshot(),
    updatedAt: Date.now(),
    attempted,
    delivered,
    acknowledged,
    failed,
    inTransit,
    ackRate,
    successRate,
    relayHops,
    avgLatencyMs,
    storeForwardTotal,
    storeForwardPending,
    storeForwardFailed,
    packetLossPercent,
    reachablePeers: peerSet.size,
    knownPeers: peerSet.size,
    events: latest,
  };
}

async function readEvents(): Promise<ProofMetricEvent[]> {
  try {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

async function writeEvents(events: ProofMetricEvent[]): Promise<void> {
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(events.slice(-500)));
}

export async function getProofMetricsSnapshot(): Promise<ProofMetricsSnapshot> {
  const events = await readEvents();
  return calculate(events);
}

export async function recordProofMetricEvent(
  event: Omit<ProofMetricEvent, "id" | "at">
): Promise<ProofMetricsSnapshot> {
  const events = await readEvents();

  const next: ProofMetricEvent = {
    ...event,
    id: `pm_${Date.now()}_${Math.random().toString(16).slice(2)}`,
    at: Date.now(),
    transport: event.transport || "BLE",
  };

  const updated = [...events, next].slice(-500);
  await writeEvents(updated);

  return calculate(updated);
}

export async function clearProofMetrics(): Promise<ProofMetricsSnapshot> {
  await writeEvents([]);
  return emptySnapshot();
}

export function makeProofPacketId(prefix = "MM-PROOF"): string {
  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;
}
