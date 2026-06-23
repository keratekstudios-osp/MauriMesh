export type StoreForwardPacket = {
  packetId: string;
  peerId: string;
  payload: unknown;
  createdAt: number;
  lastAttemptAt: number;
  attempts: number;
  maxAttempts: number;
  ttlMs: number;
  priority: number;
};

export type StoreForwardDecision = {
  shouldStore: boolean;
  shouldRetryNow: boolean;
  shouldDrop: boolean;
  reason: string;
  nextRetryMs: number;
};

export class StoreForwardIntelligence {
  private queue = new Map<string, StoreForwardPacket>();

  store(packet: Omit<StoreForwardPacket, "createdAt" | "lastAttemptAt" | "attempts">): void {
    this.queue.set(packet.packetId, {
      ...packet,
      createdAt: Date.now(),
      lastAttemptAt: 0,
      attempts: 0,
    });
  }

  decide(packet: StoreForwardPacket): StoreForwardDecision {
    const age = Date.now() - packet.createdAt;
    const expired = age > packet.ttlMs;
    const maxed = packet.attempts >= packet.maxAttempts;

    if (expired) {
      return {
        shouldStore: false,
        shouldRetryNow: false,
        shouldDrop: true,
        reason: "Packet TTL expired.",
        nextRetryMs: 0,
      };
    }

    if (maxed) {
      return {
        shouldStore: false,
        shouldRetryNow: false,
        shouldDrop: true,
        reason: "Packet max retry attempts reached.",
        nextRetryMs: 0,
      };
    }

    const backoff = Math.min(30000, 1000 * Math.pow(2, packet.attempts));
    const ready = Date.now() - packet.lastAttemptAt >= backoff;

    return {
      shouldStore: true,
      shouldRetryNow: ready,
      shouldDrop: false,
      reason: ready ? "Packet ready for retry." : "Packet waiting for backoff window.",
      nextRetryMs: backoff,
    };
  }

  markAttempt(packetId: string): void {
    const packet = this.queue.get(packetId);
    if (!packet) return;
    packet.attempts += 1;
    packet.lastAttemptAt = Date.now();
  }

  remove(packetId: string): void {
    this.queue.delete(packetId);
  }

  snapshot() {
    return {
      queued: this.queue.size,
      packets: [...this.queue.values()].map(packet => ({
        packetId: packet.packetId,
        peerId: packet.peerId,
        attempts: packet.attempts,
        ageMs: Date.now() - packet.createdAt,
        priority: packet.priority,
        decision: this.decide(packet),
      })),
    };
  }
}
