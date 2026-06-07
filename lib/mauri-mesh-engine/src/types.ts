export type TransportKind =
  | "ble"
  | "wifi-lan"
  | "webrtc"
  | "internet-api"
  | "store-forward"
  | "simulation";

export type MeshMode = "LIVE" | "SIMULATION" | "HYBRID" | "UNAVAILABLE";

export type PeerStatus = "online" | "relay" | "weak" | "offline" | "blocked";

export type GovernanceDecision =
  | "ALLOW_DIRECT"
  | "ALLOW_RELAY"
  | "STORE_FORWARD"
  | "BLOCK_LOOP"
  | "BLOCK_STALE"
  | "BLOCK_UNTRUSTED"
  | "DROP_EXPIRED"
  | "NO_ROUTE";

export type MeshPeer = {
  id: string;
  label: string;
  status: PeerStatus;
  transport: TransportKind;
  rssi?: number;
  signal: number;
  trust: number;
  batteryPressure: number;
  latencyMs: number;
  successCount: number;
  failureCount: number;
  lastSeen: number;
  routeScore: number;
  jumpCode: string;
  x?: number;
  y?: number;
};

export type MeshPacketType = "data" | "ack" | "presence" | "control";

export type MeshPacket = {
  id: string;
  type: MeshPacketType;
  from: string;
  to: string;
  payload: unknown;
  createdAt: number;
  ttlMs: number;
  hopCount: number;
  maxHops: number;
  path: string[];
  reversePath: string[];
  jumpCode: string;
  /**
   * SHA-256 hex digest of the canonical payload (stableStringify of payload
   * minus transport bookkeeping fields). Set by the integrity layer on both
   * send and receive so that every packet in the engine carries its hash.
   * Optional for backward compatibility with packets built before the
   * integrity layer was added.
   */
  payloadHash?: string;
};

/**
 * Tunable thresholds for the self-healing and traffic-control layers of the AI
 * routing engine. All fields are required here; the engine accepts a
 * `Partial<RoutingEngineConfig>` and fills any missing field from
 * `DEFAULT_ROUTING_CONFIG`, so today's behavior is preserved when nothing is
 * passed. Dense vs. sparse meshes can retune these without editing source.
 */
export type RoutingEngineConfig = {
  /** Trust value below which a peer is quarantined ("blocked"). */
  trustBlockThreshold: number;
  /** How long a quarantined peer stays blocked before self-heal rehabilitation. */
  peerBlockCooldownMs: number;
  /** Trust a rehabilitated peer is restored to (probation; must re-earn standing). */
  rehabTrust: number;
  /** Sliding window over which recent relay load is counted for congestion shaping. */
  congestionWindowMs: number;
  /** Score penalty applied per recent packet carried by a relay candidate. */
  congestionPenaltyPerPacket: number;
  /** Upper bound on the congestion penalty so a strong relay is never fully starved. */
  congestionMaxPenalty: number;
};

export type RouteCandidate = {
  peerId: string;
  transport: TransportKind;
  score: number;
  reason: string;
  jumpCode: string;
};

export type RouteDecision = {
  decision: GovernanceDecision;
  selected?: RouteCandidate;
  candidates: RouteCandidate[];
  reason: string;
};

export type DeliveryOutcome = {
  packetId: string;
  peerId: string;
  ok: boolean;
  latencyMs: number;
  reason?: string;
  timestamp: number;
};

export type MeshSnapshot = {
  mode: MeshMode;
  localNodeId: string;
  message: string;
  peers: MeshPeer[];
  routes: Array<{
    from: string;
    to: string;
    quality: number;
    transport: TransportKind;
    jumpCode: string;
  }>;
  queue: MeshPacket[];
  governance: {
    packetsSeen: number;
    packetsDropped: number;
    routeDecisions: number;
    learningEvents: number;
    /**
     * Self-healing layer: count of peers that were quarantined (blocked) and
     * later autonomously rehabilitated back into routing after their cooldown
     * elapsed or after a recovering delivery. Optional for backward compat.
     */
    rehabilitations?: number;
    /**
     * MauriAI traffic control: count of relay routes where a congestion penalty
     * was applied to spread load across peers instead of hammering one relay.
     * Optional for backward compat.
     */
    trafficShapedRoutes?: number;
    /**
     * Self-healing layer: number of peers currently quarantined (blocked)
     * awaiting rehabilitation. Optional for backward compat.
     */
    quarantinedPeers?: number;
  };
};
