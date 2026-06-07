import type { MeshPacket } from "./types";
import { isExpired } from "./MeshPacket";

const DEFAULT_MAX_SIZE = 200;
const DEFAULT_RETRY_INTERVAL_MS = 5_000;

export type RetryCallback = (packet: MeshPacket) => Promise<boolean>;

export class MeshStoreForwardQueue {
  private queue: MeshPacket[] = [];
  private maxSize: number;
  private retryTimer: ReturnType<typeof setInterval> | null = null;

  constructor(maxSize = DEFAULT_MAX_SIZE) {
    this.maxSize = maxSize;
  }

  enqueue(packet: MeshPacket): boolean {
    if (isExpired(packet)) return false;
    if (this.queue.some((p) => p.id === packet.id)) return false;

    if (this.queue.length >= this.maxSize) {
      const expiredIdx = this.queue.findIndex((p) => isExpired(p));
      if (expiredIdx >= 0) {
        this.queue.splice(expiredIdx, 1);
      } else {
        return false;
      }
    }

    this.queue.push(packet);
    return true;
  }

  dequeue(): MeshPacket | undefined {
    this.evictExpired();
    return this.queue.shift();
  }

  peek(): MeshPacket[] {
    this.evictExpired();
    return [...this.queue];
  }

  remove(packetId: string): boolean {
    const before = this.queue.length;
    this.queue = this.queue.filter((p) => p.id !== packetId);
    return this.queue.length < before;
  }

  size(): number {
    return this.queue.length;
  }

  evictExpired(): number {
    const before = this.queue.length;
    this.queue = this.queue.filter((p) => !isExpired(p));
    return before - this.queue.length;
  }

  startRetryTimer(
    callback: RetryCallback,
    intervalMs = DEFAULT_RETRY_INTERVAL_MS,
    onCycleComplete?: () => void
  ): void {
    if (this.retryTimer) return;
    this.retryTimer = setInterval(async () => {
      const pending = this.peek();
      for (const packet of pending) {
        const delivered = await callback(packet);
        if (delivered) this.remove(packet.id);
      }
      onCycleComplete?.();
    }, intervalMs);
  }

  stopRetryTimer(): void {
    if (this.retryTimer) {
      clearInterval(this.retryTimer);
      this.retryTimer = null;
    }
  }
}
