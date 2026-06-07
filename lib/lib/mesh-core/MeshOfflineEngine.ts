import { NodeStatus, PacketType, type MeshNode, type AckRecord } from "./types";
import { createPacket, isExpired } from "./MeshPacket";
import { getOrCreateIdentity } from "./MeshIdentity";
import { MeshRouteScorer } from "./MeshRouteScorer";
import { MeshTrustEngine } from "./MeshTrustEngine";
import { MeshStoreForwardQueue } from "./MeshStoreForwardQueue";
import { MeshDuplicateGuard } from "./MeshDuplicateGuard";
import type { IMeshTransport, ReceiveCallback } from "./MeshTransportAdapter";
import type { MeshPacket } from "./types";

export interface DeliveryJournalEntry {
  packetId: string;
  toNodeId: string;
  type: PacketType;
  deliveredAt: number;
  success: boolean;
  notes: string;
}

export interface SendOptions {
  toNodeId?: string;
  payload?: string;
  type?: PacketType;
  ttl?: number;
}

export class MeshOfflineEngine {
  private transport: IMeshTransport | null = null;
  private nodes = new Map<string, MeshNode>();
  private scorer = new MeshRouteScorer();
  private trust = new MeshTrustEngine();
  private queue = new MeshStoreForwardQueue();
  private guard = new MeshDuplicateGuard();
  private ackLog = new Map<string, AckRecord>();
  private journal: DeliveryJournalEntry[] = [];
  private receiveListeners = new Set<ReceiveCallback>();
  private unsubTransport: (() => void) | null = null;

  attach(transport: IMeshTransport): void {
    if (this.unsubTransport) this.unsubTransport();
    this.transport = transport;
    this.unsubTransport = transport.onReceive((pkt) => this.receivePacket(pkt));
  }

  async start(onCycleComplete?: () => void): Promise<void> {
    if (this.transport) {
      await this.transport.start();
    }
    const self = getOrCreateIdentity();
    this.nodes.set(self.nodeId, { ...self });
    this.queue.startRetryTimer(async (pkt) => {
      return this.dispatchPacket(pkt);
    }, undefined, onCycleComplete);
  }

  async stop(): Promise<void> {
    this.queue.stopRetryTimer();
    if (this.transport) {
      await this.transport.stop();
    }
  }

  async sendPacket(opts: SendOptions = {}): Promise<MeshPacket> {
    const self = getOrCreateIdentity();
    const pkt = createPacket(self.nodeId, {
      type: opts.type ?? PacketType.PULSE,
      toNodeId: opts.toNodeId ?? "BROADCAST",
      payload: opts.payload ?? "",
      ttl: opts.ttl,
    });

    this.guard.markSeen(pkt.id);
    const delivered = await this.dispatchPacket(pkt);

    this.journal.push({
      packetId: pkt.id,
      toNodeId: pkt.toNodeId,
      type: pkt.type,
      deliveredAt: Date.now(),
      success: delivered,
      notes: delivered ? "dispatched via transport" : "queued for retry",
    });

    if (!delivered) {
      this.queue.enqueue(pkt);
    }

    return pkt;
  }

  /**
   * Enqueue a pre-built packet directly into the store-forward queue without
   * attempting an immediate dispatch. Use this when the caller has already
   * determined that BLE delivery failed and wants the 5 s retry timer to own
   * all subsequent attempts.
   *
   * Compared to sendPacket():
   *  - No dispatch attempt on the call site — avoids races between the caller's
   *    success/failure state and a concurrent BLE reconnect.
   *  - The packet's fromNodeId is set by the caller so node identity is correct.
   *  - Returns true if the packet was accepted; false if expired or queue full.
   */
  enqueuePacket(pkt: MeshPacket): boolean {
    if (isExpired(pkt)) return false;
    this.guard.markSeen(pkt.id);
    const enqueued = this.queue.enqueue(pkt);
    if (enqueued) {
      this.journal.push({
        packetId: pkt.id,
        toNodeId: pkt.toNodeId,
        type: pkt.type,
        deliveredAt: Date.now(),
        success: false,
        notes: "enqueued externally for retry",
      });
    }
    return enqueued;
  }

  receivePacket(pkt: MeshPacket): void {
    if (isExpired(pkt)) return;
    if (this.guard.hasSeen(pkt.id)) return;
    this.guard.markSeen(pkt.id);

    if (pkt.type === PacketType.ACK) {
      this.ackLog.set(pkt.payload, {
        packetId: pkt.payload,
        ackedAt: Date.now(),
        fromNodeId: pkt.fromNodeId,
      });
      this.trust.recordAck(pkt.fromNodeId);
      this.queue.remove(pkt.payload);
    }

    this.trust.recordDeliverySuccess(pkt.fromNodeId);

    for (const cb of this.receiveListeners) {
      try { cb(pkt); } catch { /* ignore */ }
    }
  }

  onReceive(callback: ReceiveCallback): () => void {
    this.receiveListeners.add(callback);
    return () => this.receiveListeners.delete(callback);
  }

  addNode(node: MeshNode): void {
    this.nodes.set(node.nodeId, node);
  }

  removeNode(nodeId: string): void {
    this.nodes.delete(nodeId);
  }

  getNodes(): MeshNode[] {
    return Array.from(this.nodes.values());
  }

  getQueue(): MeshPacket[] {
    return this.queue.peek();
  }

  getDeliveryJournal(): DeliveryJournalEntry[] {
    return [...this.journal];
  }

  getTrustScore(nodeId: string): number {
    return this.trust.getScore(nodeId);
  }

  getRouteScore(targetNodeId: string): number {
    const target = this.nodes.get(targetNodeId);
    if (!target) return 0;
    const route = {
      toNodeId: targetNodeId,
      viaNodeId: targetNodeId,
      hopCount: 1,
      score: 0,
      updatedAt: target.lastSeenAt,
    };
    const trust = this.trust.getRecord(targetNodeId);
    return this.scorer.scoreRoute(target, route, trust);
  }

  getAckRecord(packetId: string): AckRecord | undefined {
    return this.ackLog.get(packetId);
  }

  private async dispatchPacket(pkt: MeshPacket): Promise<boolean> {
    if (!this.transport) return false;
    try {
      const ok = await this.transport.send(pkt);
      if (ok) {
        this.trust.recordDeliverySuccess(pkt.toNodeId);
      } else {
        this.trust.recordDeliveryFailure(pkt.toNodeId);
      }
      return ok;
    } catch {
      this.trust.recordDeliveryFailure(pkt.toNodeId);
      return false;
    }
  }
}

export const meshOfflineEngine = new MeshOfflineEngine();
