import { describe, it, expect, vi, afterEach } from "vitest";
import { tickMeshGovernanceSim } from "../../src/lib/meshGovernanceSim";

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
