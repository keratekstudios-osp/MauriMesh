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

// ── Self-healing layer ────────────────────────────────────────────────────────
// A peer whose trust collapses below this is quarantined ("blocked").
const TRUST_BLOCK_THRESHOLD = 25;
// How long a quarantined peer stays blocked before the mesh autonomously
// rehabilitates it back onto probation so the network self-heals.
const PEER_BLOCK_COOLDOWN_MS = 1000 * 30;
// Trust a rehabilitated peer is restored to: above the block threshold but low,
// so it must re-earn its standing through successful deliveries.
const REHAB_TRUST = 30;

// ── MauriAI traffic control ───────────────────────────────────────────────────
// Sliding window over which recent relay load is counted for congestion shaping.
const CONGESTION_WINDOW_MS = 1000 * 5;
// Score penalty applied per recent packet carried by a relay candidate.
const CONGESTION_PENALTY_PER_PACKET = 6;
// Upper bound on the congestion penalty so a strong relay is never fully starved.
const CONGESTION_MAX_PENALTY = 30;

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export class SelfGovernanceRoutingEngine {
  private peers = new Map<string, MeshPeer>();
  private seenPackets = new Set<string>();
  private droppedPackets = 0;
  private routeDecisions = 0;
  private learningEvents = 0;
  private rehabilitations = 0;
  private trafficShapedRoutes = 0;
  // Self-healing: peerId -> timestamp after which a blocked peer may rehabilitate.
  private blockedUntil = new Map<string, number>();
  // Traffic control: peerId -> recent send timestamps within the congestion window.
  private recentSends = new Map<string, number[]>();

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

    // Self-healing layer: autonomously rehabilitate quarantined peers whose
    // cooldown has elapsed so the mesh recovers lost routes without operator
    // intervention. Runs before route selection so healed peers are eligible.
    this.selfHeal(now);

    const peers = [...this.peers.values()]
      .filter((peer) => peer.id !== this.localNodeId)
      .filter((peer) => peer.status !== "blocked")
      .filter((peer) => !packet.path.includes(peer.id))
      .filter(
        (peer) =>
          now - peer.lastSeen <= STALE_PEER_MS || peer.id === packet.to
      );

    let trafficShaped = false;

    const candidates: RouteCandidate[] = peers
      .map((peer) => {
        const jumpScore = scoreJumpCompatibility(packet, peer);
        const baseScore = clamp(peer.routeScore * 0.75 + jumpScore * 0.25, 0, 100);

        // MauriAI traffic control: relay candidates are penalised in proportion
        // to the load they have recently carried so packets spread across the
        // mesh instead of saturating a single relay. The direct target is never
        // penalised — delivery to the destination stays deterministic.
        const isRelay = peer.id !== packet.to;
        let score = baseScore;
        let reason =
          packet.to === peer.id
            ? "Direct target peer visible."
            : "Relay candidate selected by score.";

        if (isRelay) {
          const load = this.peerLoad(peer.id, now);
          if (load > 0) {
            const penalty = Math.min(
              CONGESTION_MAX_PENALTY,
              load * CONGESTION_PENALTY_PER_PACKET
            );
            score = clamp(baseScore - penalty, 0, 100);
            trafficShaped = true;
            reason = `Relay candidate scored with congestion penalty (load ${load}).`;
          }
        }

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
          reason,
        };
      })
      .sort((a, b) => b.score - a.score);

    const direct = candidates.find((c) => c.peerId === packet.to);
    if (direct && direct.score >= 35) {
      this.recordPeerLoad(direct.peerId, now);
      return {
        decision: "ALLOW_DIRECT",
        selected: direct,
        candidates,
        reason: "Direct peer route approved by self-governance engine.",
      };
    }

    const relay = candidates.find((c) => c.score >= 50);
    if (relay) {
      this.recordPeerLoad(relay.peerId, now);
      if (trafficShaped) this.trafficShapedRoutes++;
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
      // Self-healing: a peer that was quarantined or weak and now succeeds is
      // rehabilitated faster than a healthy peer is rewarded, so recovered
      // routes return to service quickly.
      const wasStruggling = peer.status === "blocked" || peer.status === "weak";
      if (wasStruggling && this.blockedUntil.delete(peer.id)) {
        this.rehabilitations++;
      } else {
        this.blockedUntil.delete(peer.id);
      }
      peer.trust = clamp(peer.trust + (wasStruggling ? 8 : 2), 0, 100);
      peer.status = peer.signal < 35 ? "weak" : "online";
    } else {
      peer.failureCount += 1;
      peer.trust = clamp(peer.trust - 6, 0, 100);
      if (peer.trust < TRUST_BLOCK_THRESHOLD) {
        peer.status = "blocked";
        // Quarantine with a cooldown; the self-healing pass will rehabilitate
        // this peer onto probation once the cooldown elapses.
        this.blockedUntil.set(peer.id, outcome.timestamp + PEER_BLOCK_COOLDOWN_MS);
      } else if (peer.signal < 35) {
        peer.status = "weak";
      }
    }

    peer.lastSeen = outcome.timestamp;
    peer.routeScore = this.calculateRouteScore(peer);
    this.peers.set(peer.id, peer);
  }

  /**
   * Self-healing pass: rehabilitate quarantined peers whose cooldown has
   * elapsed by restoring them onto probation (low trust) so the mesh can
   * autonomously recover routes lost to transient failures.
   */
  private selfHeal(now: number): void {
    for (const peer of this.peers.values()) {
      if (peer.status !== "blocked") continue;
      const until = this.blockedUntil.get(peer.id);
      if (until !== undefined && now < until) continue;

      peer.trust = clamp(Math.max(peer.trust, REHAB_TRUST), 0, 100);
      peer.status = peer.signal < 35 ? "weak" : "online";
      peer.routeScore = this.calculateRouteScore(peer);
      this.peers.set(peer.id, peer);
      this.blockedUntil.delete(peer.id);
      this.rehabilitations++;
      this.learningEvents++;
    }

    this.pruneTransientState(now);
  }

  /**
   * Garbage-collect self-healing and traffic-control state so the maps stay
   * bounded by the live peer set over long-running sessions: drop traffic
   * windows that have fully expired or belong to peers that no longer exist,
   * and drop quarantine entries for peers that are gone.
   */
  private pruneTransientState(now: number): void {
    for (const [id, sends] of this.recentSends) {
      if (!this.peers.has(id)) {
        this.recentSends.delete(id);
        continue;
      }
      const fresh = sends.filter((t) => now - t <= CONGESTION_WINDOW_MS);
      if (fresh.length === 0) this.recentSends.delete(id);
      else if (fresh.length !== sends.length) this.recentSends.set(id, fresh);
    }
    for (const id of this.blockedUntil.keys()) {
      if (!this.peers.has(id)) this.blockedUntil.delete(id);
    }
  }

  /**
   * Lifecycle cleanup: forget a peer entirely, including its quarantine and
   * traffic-control state, so a departed/replaced node leaves no residue.
   */
  removePeer(id: string): boolean {
    this.blockedUntil.delete(id);
    this.recentSends.delete(id);
    return this.peers.delete(id);
  }

  /** Traffic control: number of packets a relay has carried within the window. */
  private peerLoad(peerId: string, now: number): number {
    const sends = this.recentSends.get(peerId);
    if (!sends) return 0;
    const fresh = sends.filter((t) => now - t <= CONGESTION_WINDOW_MS);
    if (fresh.length !== sends.length) {
      if (fresh.length === 0) this.recentSends.delete(peerId);
      else this.recentSends.set(peerId, fresh);
    }
    return fresh.length;
  }

  /** Traffic control: record that a peer has just been selected to carry a packet. */
  private recordPeerLoad(peerId: string, now: number): void {
    const sends = this.recentSends.get(peerId) ?? [];
    sends.push(now);
    this.recentSends.set(
      peerId,
      sends.filter((t) => now - t <= CONGESTION_WINDOW_MS)
    );
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
      rehabilitations: this.rehabilitations,
      trafficShapedRoutes: this.trafficShapedRoutes,
      quarantinedPeers: this.blockedUntil.size,
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
