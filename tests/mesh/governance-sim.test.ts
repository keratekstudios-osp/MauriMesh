import { describe, it, expect, vi, afterEach } from "vitest";
import {
  tickMeshGovernanceSim,
  createMeshGovernanceSim,
} from "../../src/lib/meshGovernanceSim";

afterEach(() => {
  vi.useRealTimers();
});

describe("meshGovernanceSim", () => {
  it("returns the three governance counters", () => {
    const counters = tickMeshGovernanceSim();
    expect(counters).toHaveProperty("rehabilitations");
    expect(counters).toHaveProperty("trafficShapedRoutes");
    expect(counters).toHaveProperty("quarantinedPeers");
    expect(typeof counters.rehabilitations).toBe("number");
    expect(typeof counters.trafficShapedRoutes).toBe("number");
    expect(typeof counters.quarantinedPeers).toBe("number");
  });

  it("quarantines a peer on the first tick", () => {
    const counters = tickMeshGovernanceSim();
    expect(counters.quarantinedPeers).toBeGreaterThanOrEqual(1);
  });

  it("shapes traffic as relays carry repeated load over time", () => {
    let counters = tickMeshGovernanceSim();
    for (let i = 0; i < 8; i++) {
      counters = tickMeshGovernanceSim();
    }
    expect(counters.trafficShapedRoutes).toBeGreaterThan(0);
  });

  it("oscillates quarantine -> self-heal so the count returns to zero", () => {
    vi.useFakeTimers();
    vi.setSystemTime(Date.now());

    const rehabStart = tickMeshGovernanceSim().rehabilitations;

    let sawQuarantined = false;
    let sawCleared = false;
    let rehabAfter = rehabStart;

    // Advance well past the 4s cooldown across several 1.5s ticks so the
    // self-heal pass releases the flaky peer and we observe the count drop.
    for (let i = 0; i < 8; i++) {
      vi.advanceTimersByTime(1500);
      const counters = tickMeshGovernanceSim();
      if (counters.quarantinedPeers >= 1) sawQuarantined = true;
      if (counters.quarantinedPeers === 0) sawCleared = true;
      rehabAfter = counters.rehabilitations;
    }

    expect(sawQuarantined).toBe(true);
    expect(sawCleared).toBe(true);
    expect(rehabAfter).toBeGreaterThan(rehabStart);
  });
});

describe("createMeshGovernanceSim", () => {
  it("read() reports counters without advancing the simulation", () => {
    const sim = createMeshGovernanceSim();
    sim.tick();
    const before = sim.read();
    const again = sim.read();
    expect(again).toEqual(before);
  });

  it("gives each instance its own independent engine state", () => {
    const a = createMeshGovernanceSim();
    const b = createMeshGovernanceSim();
    a.tick();
    a.tick();
    a.tick();
    // b has never ticked, so its counters stay at the initial zero state while
    // a has accumulated activity — proving the two do not share an engine.
    expect(b.read()).toEqual({
      rehabilitations: 0,
      trafficShapedRoutes: 0,
      quarantinedPeers: 0,
    });
    expect(a.read().quarantinedPeers).toBeGreaterThanOrEqual(1);
  });
});
