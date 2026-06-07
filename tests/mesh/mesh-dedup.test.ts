import { describe, it, expect } from "vitest";
import { MeshDuplicateGuard } from "../../artifacts/messenger-mobile/lib/mesh-core/MeshDuplicateGuard";

describe("duplicate_packet_filter — capacity overflow eviction", () => {
  it("retains entries within TTL window when overflow occurs (no bulk splice)", () => {
    const guard = new MeshDuplicateGuard(60_000, 5);

    for (let i = 0; i < 5; i++) {
      guard.markSeen(`pkt-${i}`);
    }

    guard.markSeen("pkt-overflow");

    for (let i = 1; i < 5; i++) {
      expect(
        guard.hasSeen(`pkt-${i}`),
        `pkt-${i} should still be in window after single-entry overflow eviction`,
      ).toBe(true);
    }

    expect(guard.hasSeen("pkt-overflow")).toBe(true);
  });

  it("evicts only the single oldest entry on overflow, keeping cache at maxEntries", () => {
    const guard = new MeshDuplicateGuard(60_000, 4);

    guard.markSeen("pkt-A");
    guard.markSeen("pkt-B");
    guard.markSeen("pkt-C");
    guard.markSeen("pkt-D");

    guard.markSeen("pkt-E");

    expect(guard.size()).toBe(4);

    expect(guard.hasSeen("pkt-B")).toBe(true);
    expect(guard.hasSeen("pkt-C")).toBe(true);
    expect(guard.hasSeen("pkt-D")).toBe(true);
    expect(guard.hasSeen("pkt-E")).toBe(true);
  });

  it("preserves duplicate detection for non-evicted entries after overflow", () => {
    const guard = new MeshDuplicateGuard(60_000, 3);

    guard.markSeen("pkt-X");
    guard.markSeen("pkt-Y");
    guard.markSeen("pkt-Z");

    guard.markSeen("pkt-W");

    expect(guard.hasSeen("pkt-Y")).toBe(true);
    expect(guard.hasSeen("pkt-Z")).toBe(true);
    expect(guard.hasSeen("pkt-W")).toBe(true);
  });

  it("evicts expired entries before falling back to oldest-entry eviction", () => {
    const guard = new MeshDuplicateGuard(1, 3);

    guard.markSeen("pkt-old-1");
    guard.markSeen("pkt-old-2");
    guard.markSeen("pkt-old-3");

    return new Promise<void>((resolve) =>
      setTimeout(() => {
        guard.markSeen("pkt-fresh");
        expect(guard.hasSeen("pkt-fresh")).toBe(true);
        expect(guard.hasSeen("pkt-old-1")).toBe(false);
        expect(guard.hasSeen("pkt-old-2")).toBe(false);
        resolve();
      }, 5),
    );
  });

  it("first occurrence of any packet is never treated as duplicate", () => {
    const guard = new MeshDuplicateGuard(60_000, 10);
    for (let i = 0; i < 10; i++) {
      expect(guard.hasSeen(`unique-${i}`)).toBe(false);
      guard.markSeen(`unique-${i}`);
    }
  });

  it("second occurrence of the same packet ID is recognised as duplicate", () => {
    const guard = new MeshDuplicateGuard(60_000, 10);
    guard.markSeen("dup-pkt");
    expect(guard.hasSeen("dup-pkt")).toBe(true);
  });

  it("guard size stays within maxEntries under continuous load", () => {
    const MAX = 8;
    const guard = new MeshDuplicateGuard(60_000, MAX);
    for (let i = 0; i < MAX * 3; i++) {
      guard.markSeen(`load-pkt-${i}`);
      expect(guard.size()).toBeLessThanOrEqual(MAX);
    }
  });

  it("clear resets size to zero", () => {
    const guard = new MeshDuplicateGuard(60_000, 5);
    for (let i = 0; i < 5; i++) guard.markSeen(`pkt-${i}`);
    guard.clear();
    expect(guard.size()).toBe(0);
  });
});
