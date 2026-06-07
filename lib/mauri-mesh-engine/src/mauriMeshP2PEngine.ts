import { createJumpCode } from "./jumpCodeEngine";
import { SelfGovernanceRoutingEngine } from "./selfGovernanceRoutingEngine";
import {
  createSimulationAdapter,
  createStoreForwardAdapter,
  HybridTransportEngine,
  TransportAdapter,
} from "./hybridTransportEngine";
import {
  DeliveryOutcome,
  MeshPacket,
  MeshSnapshot,
  MeshMode,
  MeshPeer,
  TransportKind,
} from "./types";

export class MauriMeshP2PEngine {
  private governance: SelfGovernanceRoutingEngine;
  private hybrid: HybridTransportEngine;
  private queue: MeshPacket[] = [];
  private mode: MeshMode = "HYBRID";
  private _localNodeId: string;

  constructor(localNodeId: string) {
    this._localNodeId = localNodeId;
    this.governance = new SelfGovernanceRoutingEngine(localNodeId);
    this.hybrid = new HybridTransportEngine();

    this.hybrid.register(createStoreForwardAdapter(this.queue));
    this.hybrid.register(createSimulationAdapter());
  }

  get localNodeId(): string {
    return this._localNodeId;
  }

  setLocalNodeId(id: string): void {
    this._localNodeId = id;
    this.governance = new SelfGovernanceRoutingEngine(id);
  }

  registerTransport(adapter: TransportAdapter): void {
    this.hybrid.register(adapter);
  }

  ingestPeer(
    input: Partial<MeshPeer> & { id: string; label?: string; transport?: TransportKind }
  ): MeshPeer {
    return this.governance.upsertPeer(input);
  }

  async sendMessage(
    to: string,
    payload: unknown,
    from?: string
  ): Promise<{
    packet: MeshPacket;
    delivered: boolean;
    decision: string;
    reason: string;
  }> {
    const packet = this.governance.createPacket({
      to,
      payload,
      from,
      type: "data",
      ttlMs: 1000 * 60 * 10,
      maxHops: 6,
    });

    const decision = this.governance.decideRoute(packet);

    if (
      decision.decision === "BLOCK_LOOP" ||
      decision.decision === "BLOCK_STALE" ||
      decision.decision === "BLOCK_UNTRUSTED" ||
      decision.decision === "DROP_EXPIRED"
    ) {
      return {
        packet,
        delivered: false,
        decision: decision.decision,
        reason: decision.reason,
      };
    }

    if (decision.decision === "NO_ROUTE" || decision.decision === "STORE_FORWARD") {
      this.queue.push(packet);
      return {
        packet,
        delivered: false,
        decision: decision.decision,
        reason: decision.reason,
      };
    }

    const result = await this.hybrid.send(packet, decision);

    if (decision.selected) {
      this.learn({
        packetId: packet.id,
        peerId: decision.selected.peerId,
        ok: result.ok,
        latencyMs: result.latencyMs,
        reason: result.reason,
        timestamp: Date.now(),
      });
    }

    if (result.ok) this.governance.markPacketSeen(packet.id);

    return {
      packet: {
        ...packet,
        jumpCode:
          decision.selected?.jumpCode ??
          createJumpCode({
            from: this.localNodeId,
            to,
            transport: result.transport,
            routeHint: "RESULT",
          }),
      },
      delivered: result.ok,
      decision: decision.decision,
      reason: result.reason,
    };
  }

  receivePacket(packet: MeshPacket): {
    accepted: boolean;
    reason: string;
    ack?: MeshPacket;
  } {
    const decision = this.governance.decideRoute(packet);

    if (packet.to === this.localNodeId) {
      this.governance.markPacketSeen(packet.id);

      const ack: MeshPacket = {
        id: `ack_${packet.id}`,
        type: "ack",
        from: this.localNodeId,
        to: packet.from,
        payload: { received: true, packetId: packet.id },
        createdAt: Date.now(),
        ttlMs: 1000 * 60 * 10,
        hopCount: 0,
        maxHops: packet.maxHops,
        path: [this.localNodeId],
        reversePath: [...packet.path].reverse(),
        jumpCode: createJumpCode({
          from: this.localNodeId,
          to: packet.from,
          transport: "store-forward",
          routeHint: "STRICT_REVERSE_ACK",
        }),
      };

      return {
        accepted: true,
        reason: "Packet delivered to local node. Strict reverse ACK created.",
        ack,
      };
    }

    if (
      decision.decision === "ALLOW_RELAY" ||
      decision.decision === "ALLOW_DIRECT"
    ) {
      this.governance.markPacketSeen(packet.id);
      return {
        accepted: true,
        reason: `Packet accepted for ${decision.decision}.`,
      };
    }

    if (decision.decision === "STORE_FORWARD") {
      this.queue.push(packet);
      return {
        accepted: true,
        reason: "Packet stored for future forwarding.",
      };
    }

    return {
      accepted: false,
      reason: decision.reason,
    };
  }

  learn(outcome: DeliveryOutcome): void {
    this.governance.applyDeliveryOutcome(outcome);
  }

  getSnapshot(): MeshSnapshot {
    const peers = this.governance.getPeers();
    const governance = this.governance.getGovernanceStats();

    return {
      mode: this.mode,
      localNodeId: this.localNodeId,
      message:
        peers.length > 0
          ? "AI self-governance routing engine active."
          : "AI engine active. Waiting for live peers.",
      peers,
      routes: peers.map((peer) => ({
        from: this.localNodeId,
        to: peer.id,
        quality: peer.routeScore,
        transport: peer.transport,
        jumpCode: peer.jumpCode,
      })),
      queue: [...this.queue],
      governance,
    };
  }
}

export const mauriMeshEngine = new MauriMeshP2PEngine("local-device");
