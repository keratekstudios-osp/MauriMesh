export type MessageFallbackTransport =
  | "BLE_DIRECT"
  | "BLE_RELAY"
  | "WIFI_LOCAL"
  | "WIFI_DIRECT_READY"
  | "INTERNET_GATEWAY"
  | "STORE_FORWARD_QUEUE"
  | "OFFLINE_HOLD";

export type MessageDeliveryState =
  | "LIVE_SEND_READY"
  | "LIVE_SEND_FAILED"
  | "QUEUED_FOR_RETRY"
  | "RETRY_WAITING"
  | "DELIVERED_PENDING_ACK"
  | "DELIVERED_WITH_STRICT_ACK"
  | "DELIVERED_WITH_RELAY_ACK"
  | "DELIVERY_PENDING_PROOF"
  | "OFFLINE_HOLD";

export type AckProofState =
  | "STRICT_ACK"
  | "DELAYED_ACK"
  | "RELAY_ACK"
  | "ROUTE_OBSERVED_ACK"
  | "DELIVERY_PENDING_PROOF"
  | "NO_ACK_YET";

export type FallbackMessagePacket = {
  packetId: string;
  from: string;
  to: string;
  bodyPreview: string;
  payloadSizeBytes: number;
  createdAt: number;
  urgency: "low" | "normal" | "high" | "emergency";
  requiresAck: boolean;
  preferredTransport: MessageFallbackTransport;
};

export type MessageQueueRecord = {
  packet: FallbackMessagePacket;
  state: MessageDeliveryState;
  attemptCount: number;
  nextRetryAt: number;
  lastTransportTried: MessageFallbackTransport;
  fallbackReason: string;
  queueTtlMs: number;
  proofHashStatus: "READY" | "PENDING" | "FAILED_SAFE_CACHE";
};

export type AckFallbackInput = {
  packetId: string;
  strictAckReceived: boolean;
  relayAckReceived: boolean;
  routeObserved: boolean;
  elapsedMs: number;
  requiresAck: boolean;
};

export type AckFallbackDecision = {
  ackState: AckProofState;
  deliveryState: MessageDeliveryState;
  canClaimDelivered: boolean;
  canClaimPending: boolean;
  reason: string;
  proofLabel: string;
};

export type MessageFallbackDecision = {
  packetId: string;
  selectedState: MessageDeliveryState;
  queueRecord: MessageQueueRecord;
  ackDecision: AckFallbackDecision;
  retryPlan: MessageFallbackTransport[];
  shouldQueue: boolean;
  shouldRetryLater: boolean;
  shouldEscalateToOperator: boolean;
  finalTruth: string;
};
