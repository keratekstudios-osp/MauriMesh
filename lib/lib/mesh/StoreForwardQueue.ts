/**
 * StoreForwardQueue — standalone re-export + enhanced wrapper.
 *
 * The core in-memory queue lives in maurimesh-intelligent-contract.ts.
 * This file re-exports it and adds:
 *   - QueuedMeshMessage (the checklist-spec wrapper type)
 *   - A PersistentStoreForwardQueue that auto-saves to AsyncStorage
 */

export { StoreForwardQueue } from "./maurimesh-intelligent-contract";
export type { MeshPacket } from "./maurimesh-intelligent-contract";

import { StoreForwardQueue } from "./maurimesh-intelligent-contract";
import type { MeshPacket } from "./maurimesh-intelligent-contract";
import { loadQueue, saveQueue } from "./meshStorage";

// ── Wire-format wrapper (checklist spec) ──────────────────────────────────────

export interface QueuedMeshMessage {
  message:       MeshPacket;
  status:        "queued" | "sending" | "sent" | "delivered" | "failed";
  retryCount:    number;
  lastAttemptAt?: number;
}

// ── Persistent queue ──────────────────────────────────────────────────────────

/**
 * PersistentStoreForwardQueue extends the in-memory StoreForwardQueue with
 * AsyncStorage persistence so queued messages survive app restarts.
 */
export class PersistentStoreForwardQueue extends StoreForwardQueue {
  private dirty = false;

  /** Load persisted packets into the in-memory queue. */
  async hydrate(): Promise<void> {
    const packets = await loadQueue();
    for (const p of packets) {
      super.enqueue(p);
    }
  }

  /** Persist the current queue to storage. Call after mutations. */
  async flush(): Promise<void> {
    if (!this.dirty) return;
    await saveQueue(this.queue);
    this.dirty = false;
  }

  override enqueue(packet: MeshPacket): void {
    super.enqueue(packet);
    this.dirty = true;
  }

  override dequeue(): MeshPacket | undefined {
    const p = super.dequeue();
    if (p) this.dirty = true;
    return p;
  }

  override remove(packetId: string): void {
    super.remove(packetId);
    this.dirty = true;
  }
}
