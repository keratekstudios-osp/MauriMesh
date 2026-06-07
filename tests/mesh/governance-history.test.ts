import { describe, it, expect } from "vitest";
import { createGovernanceHistory } from "../../src/lib/governanceHistory";

const counters = (r: number, t: number, q: number) => ({
  rehabilitations: r,
  trafficShapedRoutes: t,
  quarantinedPeers: q,
});

describe("createGovernanceHistory", () => {
  it("starts empty", () => {
    const h = createGovernanceHistory(20);
    expect(h.read()).toEqual([]);
  });

  it("records snapshots in order with a timestamp", () => {
    const h = createGovernanceHistory(20);
    h.record(counters(1, 2, 3), 1000);
    const out = h.record(counters(4, 5, 6), 2000);
    expect(out).toEqual([
      { t: 1000, rehabilitations: 1, trafficShapedRoutes: 2, quarantinedPeers: 3 },
      { t: 2000, rehabilitations: 4, trafficShapedRoutes: 5, quarantinedPeers: 6 },
    ]);
  });

  it("caps the window at maxEntries, dropping the oldest", () => {
    const h = createGovernanceHistory(3);
    for (let i = 1; i <= 5; i += 1) h.record(counters(i, i, i), i);
    const out = h.read();
    expect(out).toHaveLength(3);
    expect(out.map((e) => e.t)).toEqual([3, 4, 5]);
  });

  it("read() returns a copy that cannot mutate internal state", () => {
    const h = createGovernanceHistory(5);
    h.record(counters(1, 1, 1), 1);
    const snapshot = h.read();
    snapshot.push({ t: 99, rehabilitations: 9, trafficShapedRoutes: 9, quarantinedPeers: 9 });
    expect(h.read()).toHaveLength(1);
  });

  it("clamps a non-positive maxEntries to at least one", () => {
    const h = createGovernanceHistory(0);
    h.record(counters(1, 1, 1), 1);
    h.record(counters(2, 2, 2), 2);
    expect(h.read()).toEqual([
      { t: 2, rehabilitations: 2, trafficShapedRoutes: 2, quarantinedPeers: 2 },
    ]);
  });

  it("only persists the three governance fields (no extra keys leak in)", () => {
    const h = createGovernanceHistory(5);
    const polluted = { ...counters(1, 2, 3), secret: "x" } as never;
    const [entry] = h.record(polluted, 1);
    expect(Object.keys(entry).sort()).toEqual([
      "quarantinedPeers",
      "rehabilitations",
      "t",
      "trafficShapedRoutes",
    ]);
  });
});
