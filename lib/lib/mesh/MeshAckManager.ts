/**
 * MeshAckManager — delivery acknowledgement tracking.
 *
 * Flow:
 *   Receiver: call createAck() → send the resulting packet back to the sender.
 *   Sender:   call recordAck() when an ACK packet arrives → delivery confirmed.
 *             Call pendingAcks() to find packets that timed out and need retry.
 */

import type { MeshPacket } from "./maurimesh-intelligent-contract";

const ACK_TIMEOUT_MS  = 15_000;  // 15 s before a packet is considered unacked
const MAX_RETRIES     = 3;

export interface AckRecord {
  packetId:    string;
  toNodeId:    string;
  sentAt:      number;
  retryCount:  number;
  delivered:   boolean;
}

export class MeshAckManager {
  private pending = new Map<string, AckRecord>();

  // ── Track outbound packets ─────────────────────────────────────────────────

  /**
   * Register an outbound packet so we can track its ACK.
   */
  trackOutbound(packet: MeshPacket): void {
    this.pending.set(packet.packetId, {
      packetId:   packet.packetId,
      toNodeId:   packet.toNodeId,
      sentAt:     Date.now(),
      retryCount: 0,
      delivered:  false,
    });
  }

  /**
   * Mark a packet as delivered once the ACK arrives.
   * Returns true if the packetId was being tracked.
   */
  recordAck(originalPacketId: string): boolean {
    const record = this.pending.get(originalPacketId);
    if (!record) return false;
    record.delivered = true;
    return true;
  }

  /**
   * Returns all unacked packets whose timeout has elapsed and retry count
   * is below the limit.  Increments the retry counter for each returned entry.
   */
  pendingRetries(): AckRecord[] {
    const now = Date.now();
    const retries: AckRecord[] = [];

    for (const record of this.pending.values()) {
      if (record.delivered) continue;
      if (now - record.sentAt < ACK_TIMEOUT_MS) continue;
      if (record.retryCount >= MAX_RETRIES) continue;

      record.retryCount++;
      record.sentAt = now; // reset timer for next window
      retries.push(record);
    }

    return retries;
  }

  /**
   * Remove delivered and exhausted records.
   */
  prune(): void {
    for (const [id, record] of this.pending.entries()) {
      if (record.delivered || record.retryCount >= MAX_RETRIES) {
        this.pending.delete(id);
      }
    }
  }

  isDelivered(packetId: string): boolean {
    return this.pending.get(packetId)?.delivered ?? false;
  }

  pendingCount(): number {
    return [...this.pending.values()].filter((r) => !r.delivered).length;
  }

  // ── Build ACK packet ───────────────────────────────────────────────────────

  /**
   * Build an ACK MeshPacket to be sent back to the original sender.
   *
   * @param original    The packet being acknowledged.
   * @param myNodeId    This node's ID (becomes the ACK sender).
   */
  createAck(original: MeshPacket, myNodeId: string): MeshPacket {
    return {
      packetId:  `ack-${original.packetId}`,
      type:      "ACK",
      fromNodeId: myNodeId,
      toNodeId:  original.fromNodeId,
      previousNodeId: myNodeId,
      routePath: [myNodeId],
      lane:      original.lane,
      ttl:       3,
      createdAt: Date.now(),
      priority:  9,         // ACKs are highest priority
      payload:   original.packetId,
      checksum:  "",
    };
  }
}
