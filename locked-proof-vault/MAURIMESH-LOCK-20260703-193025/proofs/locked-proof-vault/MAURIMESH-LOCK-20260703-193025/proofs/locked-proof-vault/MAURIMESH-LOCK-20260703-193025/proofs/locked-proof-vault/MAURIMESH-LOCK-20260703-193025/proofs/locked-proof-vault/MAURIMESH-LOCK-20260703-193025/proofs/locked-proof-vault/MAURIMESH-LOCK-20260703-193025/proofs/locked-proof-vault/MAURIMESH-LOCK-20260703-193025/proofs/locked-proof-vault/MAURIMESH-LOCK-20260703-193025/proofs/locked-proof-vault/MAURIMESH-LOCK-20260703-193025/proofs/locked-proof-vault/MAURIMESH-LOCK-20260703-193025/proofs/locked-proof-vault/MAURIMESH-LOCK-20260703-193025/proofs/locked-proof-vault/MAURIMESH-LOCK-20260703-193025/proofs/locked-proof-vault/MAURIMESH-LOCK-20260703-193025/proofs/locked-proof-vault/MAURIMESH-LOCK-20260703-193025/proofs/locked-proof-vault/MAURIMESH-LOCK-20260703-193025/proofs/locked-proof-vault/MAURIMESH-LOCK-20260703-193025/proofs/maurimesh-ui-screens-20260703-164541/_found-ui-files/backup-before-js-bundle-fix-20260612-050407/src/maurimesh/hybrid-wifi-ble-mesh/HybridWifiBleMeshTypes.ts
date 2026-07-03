export type HybridTransport =
  | "BLE_DIRECT"
  | "BLE_RELAY"
  | "STORE_FORWARD"
  | "WIFI_LOCAL"
  | "WIFI_DIRECT_READY"
  | "INTERNET_GATEWAY"
  | "OFFLINE_HOLD";

export type HybridLinkState = {
  bleDirectAvailable: boolean;
  bleRelayAvailable: boolean;
  wifiLocalAvailable: boolean;
  wifiDirectAvailable: boolean;
  internetGatewayAvailable: boolean;
  peerTrustScore: number;
  routePressure: "low" | "medium" | "high" | "critical";
  batteryPressure: "low" | "medium" | "high" | "critical";
  thermalPressure: "low" | "medium" | "high" | "critical";
  payloadUrgency: "low" | "normal" | "high" | "emergency";
  payloadSizeBytes: number;
  timestamp: number;
};

export type HybridMeshPacket = {
  packetId: string;
  from: string;
  to: string;
  createdAt: number;
  payloadSizeBytes: number;
  urgency: "low" | "normal" | "high" | "emergency";
  requiresAck: boolean;
};

export type HybridMeshProofEvent = {
  id: string;
  packetId: string;
  stage:
    | "HYBRID_ROUTE_DECISION"
    | "HYBRID_FAILOVER"
    | "HYBRID_STORE_FORWARD"
    | "HYBRID_GATEWAY_READY"
    | "HYBRID_OFFLINE_HOLD";
  transport: HybridTransport;
  status: "READY" | "FALLBACK" | "DEFERRED" | "BLOCKED";
  reason: string;
  timestamp: number;
};

export type HybridMeshDecision = {
  selectedTransport: HybridTransport;
  fallbackOrder: HybridTransport[];
  shouldStoreForward: boolean;
  shouldUseGateway: boolean;
  shouldUseRelay: boolean;
  shouldHoldOffline: boolean;
  maxHops: number;
  ttlMs: number;
  retryLimit: number;
  proofEvents: HybridMeshProofEvent[];
  confidence: number;
  reason: string;
  finalTruth: string;
};
