// MauriMesh Intelligent Contract
// Core types and routing / queuing primitives for the offline BLE mesh.
//
// Resolution: the incoming branch added TrustState, a full RouteScore
// scoring system, and expanded packet/lane types.  HEAD added backward-
// compat helpers (updateNodeRssi, markNodeUnreachable, allNodes, public
// queue accessor) that other modules depend on.  Both sets are kept here.

// ─── Transport lanes ─────────────────────────────────────────────────────────

export type MeshLane = "BLE" | "WIFI" | "INTERNET" | "PIXEL_CALL";

// ─── Packet types ─────────────────────────────────────────────────────────────

export type PacketType =
  | "CHAT_MESSAGE"
  | "ACK"
  | "READ_ACK"
  | "ROUTE_BEACON"
  | "NODE_DISCOVERY"
  | "STORE_FORWARD"
  | "PIXEL_FRAME"
  | "CALL_INVITE";

// Dynamic priority by packet type — higher number = higher priority.
// Order: ACK(10) > READ_ACK(9) > CALL_INVITE(7) > CHAT(5) > BROADCAST_CHAT(4)
//        > PIXEL_FRAME(3) > ROUTE_BEACON(3) > NODE_DISCOVERY(3) > STORE_FORWARD(2)
//
// The optional `toNodeId` parameter distinguishes directed CHAT (priority 5)
// from broadcast CHAT (priority 4) to satisfy the required ordering:
//   ACK > READ_ACK > CALL_INVITE > CHAT > BROADCAST
export function packetPriority(type: PacketType, toNodeId?: string): number {
  switch (type) {
    case "ACK":            return 10;
    case "READ_ACK":       return 9;
    case "CALL_INVITE":    return 7;
    case "CHAT_MESSAGE":   return toNodeId === "BROADCAST" ? 4 : 5;
    case "PIXEL_FRAME":    return 3;
    case "ROUTE_BEACON":   return 3;
    case "NODE_DISCOVERY": return 3;
    case "STORE_FORWARD":  return 2;
    default:               return 5;
  }
}

// Alias for backward compatibility with code that imported MeshPacketType
export type MeshPacketType = PacketType;

// ─── Trust ────────────────────────────────────────────────────────────────────

export type TrustState = "TRUSTED" | "UNKNOWN" | "REVOKED";

// ─── MeshNode ─────────────────────────────────────────────────────────────────

export interface MeshNode {
  nodeId: string;
  displayName?: string;
  bleAddress?: string;
  lastSeen: number;
  rssi?: number;
  batteryLevel?: number;
  trustState: TrustState;
  supportedLanes: MeshLane[];
  /** @deprecated use trustState instead; kept for backward compat */
  isReachable?: boolean;
}

// ─── MeshPacket ───────────────────────────────────────────────────────────────

export interface MeshPacket {
  packetId: string;
  type: PacketType;
  fromNodeId: string;
  toNodeId: string;
  previousNodeId?: string;
  routePath: string[];
  lane: MeshLane;
  ttl: number;
  /** Number of relay hops this packet has already traversed (0 = origin). */
  hopCount?: number;
  /** Hard cap on relay hops — packet is dropped if hopCount exceeds this. */
  maxHops?: number;
  /**
   * Strict reverse-path for ACK packets. Built by reversing the original
   * message's routePath at the final recipient. Each relay node follows
   * reversePath[reversePathIndex + 1] as the ONLY valid next hop.
   * No RouteScore carrier selection; no rerouting on failure.
   */
  reversePath?: string[];
  /**
   * Current position of the carrying node in reversePath. Incremented with
   * each relay so the next hop knows where it sits in the return path.
   */
  reversePathIndex?: number;
  /**
   * Base64-encoded Ed25519 public key (32 bytes) of the originating node.
   * Set by the sender; preserved unchanged through all relay hops.
   * Required for signature verification at every hop and at final delivery.
   *
   * Optional at the type level only because ROUTE_BEACON liveness packets are
   * intentionally unsigned. The receive gate (verifyAndDispatch in
   * useMeshTransport.ts) enforces authenticity at runtime: every type EXCEPT
   * ROUTE_BEACON is dropped unless it carries a valid fromPublicKey + signature
   * whose key matches the bound identity for fromNodeId.
   */
  fromPublicKey?: string;
  /**
   * Base64-encoded Ed25519 detached signature (64 bytes) of the stable packet
   * body (packetId, type, fromNodeId, toNodeId, payload, createdAt, fromPublicKey).
   * Mutable relay fields (routePath, ttl, hopCount, reversePath, etc.) are
   * intentionally excluded so the signature survives fragmentation/reassembly
   * and multi-hop relay without re-signing.
   */
  signature?: string;
  createdAt: number;
  priority: number;
  payload: string;
  checksum: string;
}

// ─── RouteScore ───────────────────────────────────────────────────────────────

export interface RouteScore {
  nodeId: string;
  lane: MeshLane;
  score: number;
  rssiScore: number;
  trustScore: number;
  successScore: number;
  latencyScore: number;
  lastSeenScore: number;
}

// ─── IntelligentMeshRouter ────────────────────────────────────────────────────

export class IntelligentMeshRouter {
  private nodes = new Map<string, MeshNode>();
  private deliveredPackets = new Set<string>();
  private routeSuccess = new Map<string, number>();
  private routeFailures = new Map<string, number>();

  registerNode(node: MeshNode): void {
    this.nodes.set(node.nodeId, {
      ...node,
      lastSeen: Date.now(),
    });
  }

  /** Update RSSI for a known node (backward-compat helper). */
  updateNodeRssi(nodeId: string, rssi: number): void {
    const node = this.nodes.get(nodeId);
    if (node) {
      node.rssi = rssi;
      node.lastSeen = Date.now();
    }
  }

  /** Mark a node as unreachable (backward-compat helper). */
  markNodeUnreachable(nodeId: string): void {
    const node = this.nodes.get(nodeId);
    if (node) {
      node.isReachable = false;
    }
  }

  /** Remove a node from the routing table entirely (called on peer expiry). */
  removeNode(nodeId: string): void {
    this.nodes.delete(nodeId);
    this.routeSuccess.delete(nodeId);
    this.routeFailures.delete(nodeId);
  }

  shouldAcceptPacket(packet: MeshPacket): boolean {
    if (this.deliveredPackets.has(packet.packetId)) return false;
    if (packet.ttl <= 0) return false;

    const sender = this.nodes.get(packet.fromNodeId);
    if (sender?.trustState === "REVOKED") return false;

    return true;
  }

  markDelivered(packetId: string): void {
    this.deliveredPackets.add(packetId);
    // Prune seen-set to avoid unbounded growth (keep last 2000)
    if (this.deliveredPackets.size > 2000) {
      const first = this.deliveredPackets.values().next().value;
      if (first !== undefined) this.deliveredPackets.delete(first);
    }
  }

  /**
   * Select the best reachable next-hop toward targetNodeId.
   * Returns a RouteScore or null when no candidate is available.
   *
   * @param excludeNodeIds — node IDs to skip (e.g. the packet's routePath,
   *   to prevent forwarding back to a prior hop).
   */
  selectBestRoute(
    targetNodeId: string,
    preferredLane: MeshLane = "BLE",
    excludeNodeIds: ReadonlyArray<string> = []
  ): RouteScore | null {
    const directNode = this.nodes.get(targetNodeId);

    if (
      directNode &&
      !excludeNodeIds.includes(directNode.nodeId) &&
      directNode.trustState !== "REVOKED" &&
      directNode.supportedLanes.includes(preferredLane)
    ) {
      return this.scoreNode(directNode, preferredLane);
    }

    const candidates = [...this.nodes.values()]
      .filter((node) => !excludeNodeIds.includes(node.nodeId))
      .filter((node) => node.trustState !== "REVOKED")
      .filter((node) => node.supportedLanes.includes(preferredLane));

    if (!candidates.length) return null;

    return candidates
      .map((node) => this.scoreNode(node, preferredLane))
      .sort((a, b) => b.score - a.score)[0];
  }

  /**
   * Clone the packet with decremented TTL and the relay node appended to
   * routePath.  Returns null if the packet should not be forwarded.
   *
   * NOTE: Callers must invoke shouldAcceptPacket() for dedup BEFORE calling
   * this method.  prepareRelayPacket only checks loop prevention and TTL; it
   * does NOT consult the delivered-packet set, so it is safe to call even
   * after markDelivered() has been recorded for the original packet.
   */
  prepareRelayPacket(
    packet: MeshPacket,
    relayNodeId: string
  ): MeshPacket | null {
    if (packet.ttl <= 1) return null;
    if (packet.routePath.includes(relayNodeId)) return null;

    return {
      ...packet,
      previousNodeId: relayNodeId,
      routePath: [...packet.routePath, relayNodeId],
      ttl: packet.ttl - 1,
    };
  }

  recordRouteSuccess(nodeId: string): void {
    this.routeSuccess.set(nodeId, (this.routeSuccess.get(nodeId) ?? 0) + 1);
  }

  recordRouteFailure(nodeId: string): void {
    this.routeFailures.set(nodeId, (this.routeFailures.get(nodeId) ?? 0) + 1);
  }

  /** All registered nodes (snapshot). */
  allNodes(): MeshNode[] {
    return Array.from(this.nodes.values());
  }

  private scoreNode(node: MeshNode, lane: MeshLane): RouteScore {
    const rssiScore = this.normalizeRssi(node.rssi);
    const trustScore = node.trustState === "TRUSTED" ? 100 : 45;
    const successScore = this.getSuccessScore(node.nodeId);
    const latencyScore = 80;
    const lastSeenScore = this.getLastSeenScore(node.lastSeen);

    const score =
      rssiScore * 0.25 +
      trustScore * 0.25 +
      successScore * 0.25 +
      latencyScore * 0.1 +
      lastSeenScore * 0.15;

    return {
      nodeId: node.nodeId,
      lane,
      score,
      rssiScore,
      trustScore,
      successScore,
      latencyScore,
      lastSeenScore,
    };
  }

  private getSuccessScore(nodeId: string): number {
    const success = this.routeSuccess.get(nodeId) ?? 0;
    const failure = this.routeFailures.get(nodeId) ?? 0;
    const total = success + failure;
    if (!total) return 60;
    return Math.round((success / total) * 100);
  }

  private normalizeRssi(rssi?: number): number {
    if (rssi == null) return 40;
    if (rssi >= -45) return 100;
    if (rssi <= -100) return 5;
    return Math.round(((rssi + 100) / 55) * 100);
  }

  private getLastSeenScore(lastSeen: number): number {
    const ageMs = Date.now() - lastSeen;
    if (ageMs < 5_000) return 100;
    if (ageMs < 30_000) return 80;
    if (ageMs < 120_000) return 50;
    return 20;
  }
}

// ─── StoreForwardQueue ────────────────────────────────────────────────────────

export class StoreForwardQueue {
  /** Exposed for direct iteration by legacy mesh-service callers. */
  queue: MeshPacket[] = [];

  private readonly maxSize = 500;

  enqueue(packet: MeshPacket): void {
    // Deduplicate by packetId
    if (this.queue.some((item) => item.packetId === packet.packetId)) return;

    // Drop lowest-priority NON-ACK packet when at capacity; never evict ACK / READ_ACK.
    if (this.queue.length >= this.maxSize) {
      let lowestIdx = -1;
      for (let i = 0; i < this.queue.length; i++) {
        const item = this.queue[i];
        if (item.type === "ACK" || item.type === "READ_ACK") continue;
        if (
          lowestIdx === -1 ||
          item.priority < this.queue[lowestIdx].priority
        ) {
          lowestIdx = i;
        }
      }
      if (lowestIdx !== -1) {
        this.queue.splice(lowestIdx, 1);
      } else {
        // All slots are ACKs — drop the new packet to protect them.
        return;
      }
    }

    this.queue.push(packet);
    this.queue.sort((a, b) => b.priority - a.priority);
  }

  dequeue(): MeshPacket | undefined {
    return this.queue.shift();
  }

  getPendingForNode(nodeId: string): MeshPacket[] {
    return this.queue.filter((packet) => packet.toNodeId === nodeId);
  }

  remove(packetId: string): void {
    this.queue = this.queue.filter((packet) => packet.packetId !== packetId);
  }

  size(): number {
    return this.queue.length;
  }
}
