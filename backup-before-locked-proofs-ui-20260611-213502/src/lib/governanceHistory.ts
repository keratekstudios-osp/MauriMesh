import type { MeshGovernanceCounters } from "./meshGovernanceSim";

/** One recorded governance snapshot plus the time it was captured. */
export type GovernanceHistoryEntry = MeshGovernanceCounters & {
  /** Capture timestamp (ms since epoch). */
  t: number;
};

export type GovernanceHistory = {
  /** Append a snapshot and return the current rolling window (newest last). */
  record: (
    counters: MeshGovernanceCounters,
    at?: number
  ) => GovernanceHistoryEntry[];
  /** Read the current rolling window without mutating it (newest last). */
  read: () => GovernanceHistoryEntry[];
};

/**
 * [SIMULATION - NOT LIVE BLE] A fixed-size rolling buffer of governance counter
 * snapshots so the Mesh Status screen can render the self-heal cycle over time
 * rather than only the latest value. Pure and side-effect free (no timers, no
 * I/O) so the server owns the single shared instance and clients can keep a
 * local fallback buffer. Reaching this data NEVER proves live BLE.
 */
export function createGovernanceHistory(maxEntries = 20): GovernanceHistory {
  const cap = Math.max(1, Math.floor(maxEntries));
  const entries: GovernanceHistoryEntry[] = [];

  function read(): GovernanceHistoryEntry[] {
    return entries.slice();
  }

  function record(
    counters: MeshGovernanceCounters,
    at: number = Date.now()
  ): GovernanceHistoryEntry[] {
    entries.push({
      t: at,
      rehabilitations: counters.rehabilitations,
      trafficShapedRoutes: counters.trafficShapedRoutes,
      quarantinedPeers: counters.quarantinedPeers,
    });
    if (entries.length > cap) {
      entries.splice(0, entries.length - cap);
    }
    return read();
  }

  return { record, read };
}
