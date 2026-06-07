import { describe, expect, it } from "vitest";

function stableNodeId(address?: string, name?: string): string {
  const raw = `${address || "unknown-address"}::${name || "unknown-name"}`;
  let hash = 0;
  for (let i = 0; i < raw.length; i += 1) {
    hash = (hash * 31 + raw.charCodeAt(i)) >>> 0;
  }
  return `node_${hash.toString(16)}`;
}

describe("live mesh pure logic", () => {
  it("creates stable node ids for the same BLE address", () => {
    expect(stableNodeId("AA:BB:CC", "peer")).toBe(stableNodeId("AA:BB:CC", "peer"));
  });

  it("creates different ids for different BLE addresses", () => {
    expect(stableNodeId("AA:BB:CC", "peer")).not.toBe(stableNodeId("DD:EE:FF", "peer"));
  });
});
