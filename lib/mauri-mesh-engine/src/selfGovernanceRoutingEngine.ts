import {
  DeliveryOutcome,
  MeshPacket,
  MeshPeer,
  PeerStatus,
  RouteCandidate,
  RouteDecision,
  TransportKind,
} from "./types";
import { createJumpCode, scoreJumpCompatibility } from "./jumpCodeEngine";

const DEFAULT_MAX_PACKET_AGE_MS = 1000 * 60 * 10;
const STALE_PEER_MS = 1000 * 45;

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export class SelfGovernanceRoutingEngine {
  private peers = new Map<string, MeshPeer>();
  private seenPackets = new Set<string>();
  private droppedPackets = 0;
  private routeDecisions = 0;
  private learningEvents = 0;

  constructor(private readonly localNodeId: string) {}

  upsertPeer(
    input: Partial<MeshPeer> & { id: string; label?: string; transport?: TransportKind }
  ): MeshPeer {
    const now = Date.now();
    const existing = this.peers.get(input.id);

    const transport: TransportKind = input.transport ?? existing?.transport ?? "simulation";
    const signal = clamp(input.signal ?? existing?.signal ?? this.rssiToSignal(input.rssi), 0, 100);
    const trust = clamp(input.trust ?? existing?.trust ?? 70, 0, 100);
    const latencyMs = Math.max(0, input.latencyMs ?? existing?.latencyMs ?? 250);
    const batteryPressure = clamp(input.batteryPressure ?? existing?.batteryPressure ?? 10, 0, 100);
    const status: PeerStatus =
      input.status ?? existing?.status ?? (signal < 35 ? "weak" : "online");

    const peer: MeshPeer = {
      id: input.id,
      label: input.label ?? existing?.label ?? input.id,
      status,
      transport,
      rssi: input.rssi ?? existing?.rssi,
      signal,
      trust,
      batteryPressure,
      latencyMs,
      successCount: input.successCount ?? existing?.successCount ?? 0,
      failureCount: input.failureCount ?? existing?.failureCount ?? 0,
      lastSeen: input.lastSeen ?? now,
      routeScore: 0,
      jumpCode: createJumpCode({
        from: this.localNodeId,
        to: input.id,
        transport,
        routeHint: "PEER",
      }),
      x: input.x ?? existing?.x,
      y: input.y ?? existing?.y,
    };

    peer.routeScore = this.calculateRouteScore(peer);
    this.peers.set(peer.id, peer);
    return peer;
  }

  createPacket(input: {
    to: string;
    payload: unknown;
    type?: MeshPacket["type"];
    ttlMs?: number;
    maxHops?: number;
    from?: string;
  }): MeshPacket {
    const createdAt = Date.now();
    const senderNodeId = input.from ?? this.localNodeId;
    const packetId = `pkt_${senderNodeId}_${createdAt}_${Math.random().toString(36).slice(2, 8)}`;

    return {
      id: packetId,
      type: input.type ?? "data",
      from: senderNodeId,
      to: input.to,
      payload: input.payload,
      createdAt,
      ttlMs: input.ttlMs ?? DEFAULT_MAX_PACKET_AGE_MS,
      hopCount: 0,
      maxHops: input.maxHops ?? 6,
      path: [senderNodeId],
      reversePath: [],
      jumpCode: createJumpCode({
        from: senderNodeId,
        to: input.to,
        transport: "store-forward",
        routeHint: "NEW_PACKET",
      }),
    };
  }

  decideRoute(packet: MeshPacket): RouteDecision {
    this.routeDecisions++;

    const now = Date.now();

    if (this.seenPackets.has(packet.id)) {
      this.droppedPackets++;
      return {
        decision: "BLOCK_LOOP",
        candidates: [],
        reason: "Packet already seen. Loop/rebroadcast blocked.",
      };
    }

    if (now - packet.createdAt > packet.ttlMs) {
      this.droppedPackets++;
      return {
        decision: "DROP_EXPIRED",
        candidates: [],
        reason: "Packet TTL expired.",
      };
    }

    if (packet.hopCount >= packet.maxHops) {
      this.droppedPackets++;
      return {
        decision: "DROP_EXPIRED",
        candidates: [],
        reason: "Packet max hop limit reached.",
      };
    }

    const peers = [...this.peers.values()]
      .filter((peer) => peer.id !== this.localNodeId)
      .filter((peer) => peer.status !== "blocked")
      .filter((peer) => !packet.path.includes(peer.id))
      .filter(
        (peer) =>
          now - peer.lastSeen <= STALE_PEER_MS || peer.id === packet.to
      );

    const candidates: RouteCandidate[] = peers
      .map((peer) => {
        const jumpScore = scoreJumpCompatibility(packet, peer);
        const score = clamp(peer.routeScore * 0.75 + jumpScore * 0.25, 0, 100);

        return {
          peerId: peer.id,
          transport: peer.transport,
          score,
          jumpCode: createJumpCode({
            from: this.localNodeId,
            to: peer.id,
            transport: peer.transport,
            routeHint: packet.to === peer.id ? "DIRECT_TARGET" : "RELAY_TARGET",
          }),
          reason:
            packet.to === peer.id
              ? "Direct target peer visible."
              : "Relay candidate selected by score.",
        };
      })
      .sort((a, b) => b.score - a.score);

    const direct = candidates.find((c) => c.peerId === packet.to);
    if (direct && direct.score >= 35) {
      return {
        decision: "ALLOW_DIRECT",
        selected: direct,
        candidates,
        reason: "Direct peer route approved by self-governance engine.",
      };
    }

    const relay = candidates.find((c) => c.score >= 50);
    if (relay) {
      return {
        decision: "ALLOW_RELAY",
        selected: relay,
        candidates,
        reason: "Relay route approved. Direct peer not visible or not strong enough.",
      };
    }

    if (candidates.length === 0) {
      return {
        decision: "STORE_FORWARD",
        candidates,
        reason: "No safe visible peer. Packet should be stored until route returns.",
      };
    }

    return {
      decision: "NO_ROUTE",
      candidates,
      reason: "Peers exist, but none passed route governance threshold.",
    };
  }

  markPacketSeen(packetId: string): void {
    this.seenPackets.add(packetId);
  }

  applyDeliveryOutcome(outcome: DeliveryOutcome): void {
    const peer = this.peers.get(outcome.peerId);
    if (!peer) return;

    this.learningEvents++;

    if (outcome.ok) {
      peer.successCount += 1;
      peer.latencyMs = Math.round(peer.latencyMs * 0.7 + outcome.latencyMs * 0.3);
      peer.trust = clamp(peer.trust + 2, 0, 100);
      peer.status = peer.signal < 35 ? "weak" : "online";
    } else {
      peer.failureCount += 1;
      peer.trust = clamp(peer.trust - 6, 0, 100);
      if (peer.trust < 25) peer.status = "blocked";
      else if (peer.signal < 35) peer.status = "weak";
    }

    peer.lastSeen = outcome.timestamp;
    peer.routeScore = this.calculateRouteScore(peer);
    this.peers.set(peer.id, peer);
  }

  getPeers(): MeshPeer[] {
    return [...this.peers.values()]
      .map((peer) => ({
        ...peer,
        routeScore: this.calculateRouteScore(peer),
      }))
      .sort((a, b) => b.routeScore - a.routeScore);
  }

  getGovernanceStats() {
    return {
      packetsSeen: this.seenPackets.size,
      packetsDropped: this.droppedPackets,
      routeDecisions: this.routeDecisions,
      learningEvents: this.learningEvents,
    };
  }

  private calculateRouteScore(peer: MeshPeer): number {
    const total = peer.successCount + peer.failureCount;
    const successRate = total === 0 ? 0.65 : peer.successCount / total;
    const signalScore = peer.signal / 100;
    const latencyScore = clamp(1 - peer.latencyMs / 2000, 0, 1);
    const trustScore = peer.trust / 100;
    const batteryScore = clamp(1 - peer.batteryPressure / 100, 0, 1);
    const recencyMs = Date.now() - peer.lastSeen;
    const recencyScore = clamp(1 - recencyMs / STALE_PEER_MS, 0, 1);

    const score =
      successRate * 0.28 +
      signalScore * 0.2 +
      latencyScore * 0.16 +
      trustScore * 0.18 +
      batteryScore * 0.08 +
      recencyScore * 0.1;

    return Math.round(clamp(score * 100, 0, 100));
  }

  private rssiToSignal(rssi?: number): number {
    if (typeof rssi !== "number") return 55;
    if (rssi >= -45) return 100;
    if (rssi <= -100) return 5;
    return Math.round(((rssi + 100) / 55) * 95 + 5);
  }
}
