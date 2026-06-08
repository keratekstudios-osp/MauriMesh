import { describe, it, expect } from "vitest";
import { LivingSelfGovernedAiMesh } from "../../src/maurimesh/invention-engine/livingSelfGovernedAiMesh";
import type { MeshNode } from "../../src/maurimesh/invention-engine/types";

// End-to-end coverage of the orchestrator that wires the self-learning,
// self-governance, AI routing, emergency and trust layers together. Pure
// simulation logic — it proves no live BLE.

function node(id: string, over: Partial<MeshNode> = {}): MeshNode {
  return {
    id,
    role: "ENDPOINT",
    trust: "VERIFIED",
    batteryPct: 90,
    signalPct: 90,
    online: true,
    lastSeenMs: Date.now(),
    transports: ["BLE"],
    ...over,
  };
}

describe("LivingSelfGovernedAiMesh — send pipeline", () => {
  it("approves and routes a benign message end-to-end", () => {
    const mesh = new LivingSelfGovernedAiMesh();
    mesh.setNodes([node("A"), node("B")]);

    const result = mesh.send({ from: "A", to: "B", body: "hello there" });

    expect(result.packet.from).toBe("A");
    expect(result.packet.to).toBe("B");
    expect(result.packet.culturalState).toBe("NOA_OPEN");
    expect(result.governance.approved).toBe(true);
    expect(result.routePlan.packetId).toBe(result.packet.id);
    expect(result.ledger.some((e) => e.status === "CREATED")).toBe(true);
    expect(result.ledger.some((e) => e.status === "QUEUED")).toBe(true);
  });

  it("classifies and strengthens an emergency message", () => {
    const mesh = new LivingSelfGovernedAiMesh();
    mesh.setNodes([node("A"), node("B")]);

    const result = mesh.send({ from: "A", to: "B", body: "please help, emergency" });

    expect(result.packet.culturalState).toBe("KIA_KAHA_EMERGENCY");
    expect(result.packet.priority).toBe(10);
    expect(result.packet.ttl).toBe(12);
    expect(result.packet.metadata?.emergencyMode).toBe(true);
  });

  it("rejects a packet from a blocked sender and stores it", () => {
    const mesh = new LivingSelfGovernedAiMesh();
    mesh.setNodes([node("A", { trust: "BLOCKED" }), node("B")]);

    const result = mesh.send({ from: "A", to: "B", body: "hi" });

    expect(result.governance.approved).toBe(false);
    expect(result.routePlan.governanceApproved).toBe(false);
    expect(result.routePlan.storeAndForward).toBe(true);
  });
});

describe("LivingSelfGovernedAiMesh — delivery feedback learning", () => {
  it("records route success and peer trust on ACK", () => {
    const mesh = new LivingSelfGovernedAiMesh();
    mesh.setNodes([node("A"), node("B")]);
    const { packet } = mesh.send({ from: "A", to: "B", body: "hi" });

    mesh.ack(packet.id, ["A", "B"], 120);

    const route = mesh.routeMemoryExport().find((m) => m.routeKey === "A>B");
    expect(route?.successCount).toBe(1);
    expect(mesh.ledgerExport().some((e) => e.status === "ACKED")).toBe(true);
    expect(mesh.trustMemoryExport().some((t) => t.nodeId === "B")).toBe(true);
  });

  it("records route failure and lowers peer trust on FAIL", () => {
    const mesh = new LivingSelfGovernedAiMesh();
    mesh.setNodes([node("A"), node("B")]);
    const { packet } = mesh.send({ from: "A", to: "B", body: "hi" });

    mesh.fail(packet.id, ["A", "C"], "no ack");

    const route = mesh.routeMemoryExport().find((m) => m.routeKey === "A>C");
    expect(route?.failureCount).toBe(1);
    expect(mesh.ledgerExport().some((e) => e.status === "FAILED")).toBe(true);
    const c = mesh.trustMemoryExport().find((t) => t.nodeId === "C");
    expect(c?.failures).toBe(1);
  });
});
