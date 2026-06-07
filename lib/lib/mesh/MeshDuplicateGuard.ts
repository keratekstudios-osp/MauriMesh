/**
 * MeshDuplicateGuard — in-memory dedup with TTL expiry.
 *
 * Prevents duplicate BLE packets from entering the inbox twice.
 * Pairs with meshStorage.ts for cross-session persistence.
 */

const DEFAULT_TTL_MS  = 10 * 60 * 1000; // 10 minutes
const MAX_ENTRIES     = 2000;

interface Entry {
  id: string;
  seenAt: number;
}

export class MeshDuplicateGuard {
  private readonly ttlMs: number;
  private entries: Entry[] = [];

  constructor(ttlMs: number = DEFAULT_TTL_MS) {
    this.ttlMs = ttlMs;
  }

  /**
   * Returns true if this ID has been seen within the TTL window.
   */
  hasSeen(id: string): boolean {
    const now = Date.now();
    const entry = this.entries.find((e) => e.id === id);
    if (!entry) return false;
    return now - entry.seenAt < this.ttlMs;
  }

  /**
   * Record an ID as seen right now.
   * Triggers expiry cleanup when the table is getting large.
   */
  markSeen(id: string): void {
    if (this.hasSeen(id)) return; // already present and fresh
    this.entries.push({ id, seenAt: Date.now() });
    if (this.entries.length >= MAX_ENTRIES) {
      this.clearExpired();
      // Hard-cap if clearExpired didn't free enough space
      if (this.entries.length >= MAX_ENTRIES) {
        this.entries.splice(0, Math.floor(MAX_ENTRIES / 4));
      }
    }
  }

  /**
   * Remove all entries whose TTL has elapsed.
   */
  clearExpired(): void {
    const cutoff = Date.now() - this.ttlMs;
    this.entries = this.entries.filter((e) => e.seenAt > cutoff);
  }

  /** Total entries currently tracked (including possibly-expired ones). */
  size(): number {
    return this.entries.length;
  }

  /** Pre-seed the guard from persisted seen-IDs (e.g. loaded from meshStorage). */
  seed(ids: { id: string; seenAt: number }[]): void {
    const now = Date.now();
    for (const entry of ids) {
      if (now - entry.seenAt < this.ttlMs && !this.hasSeen(entry.id)) {
        this.entries.push(entry);
      }
    }
  }
}
