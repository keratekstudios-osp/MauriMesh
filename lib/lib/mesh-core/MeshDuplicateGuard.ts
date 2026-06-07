const DEFAULT_WINDOW_MS = 10 * 60 * 1000;
const DEFAULT_MAX_ENTRIES = 2000;

interface SeenEntry {
  id: string;
  seenAt: number;
}

export class MeshDuplicateGuard {
  private entries: SeenEntry[] = [];
  private readonly windowMs: number;
  private readonly maxEntries: number;

  constructor(windowMs = DEFAULT_WINDOW_MS, maxEntries = DEFAULT_MAX_ENTRIES) {
    this.windowMs = windowMs;
    this.maxEntries = maxEntries;
  }

  hasSeen(id: string): boolean {
    const now = Date.now();
    const entry = this.entries.find((e) => e.id === id);
    if (!entry) return false;
    return now - entry.seenAt < this.windowMs;
  }

  markSeen(id: string): void {
    if (this.hasSeen(id)) return;
    if (this.entries.length >= this.maxEntries) {
      this.evictExpired();
      if (this.entries.length >= this.maxEntries) {
        const oldest = this.entries.reduce((min, e) =>
          e.seenAt < min.seenAt ? e : min
        );
        const idx = this.entries.indexOf(oldest);
        if (idx >= 0) this.entries.splice(idx, 1);
      }
    }
    this.entries.push({ id, seenAt: Date.now() });
  }

  evictExpired(): number {
    const cutoff = Date.now() - this.windowMs;
    const before = this.entries.length;
    this.entries = this.entries.filter((e) => e.seenAt > cutoff);
    return before - this.entries.length;
  }

  size(): number {
    return this.entries.length;
  }

  clear(): void {
    this.entries = [];
  }
}
