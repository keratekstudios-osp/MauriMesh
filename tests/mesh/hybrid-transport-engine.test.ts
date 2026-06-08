import { describe, it, expect } from "vitest";
import {
  HybridTransportEngine,
  createSimulationAdapter,
  createStoreForwardAdapter,
  type TransportAdapter,
} from "../../lib/mauri-mesh-engine/src/hybridTransportEngine";
import type {
  MeshPacket,
  RouteDecision,
  TransportKind,
} from "../../lib/mauri-mesh-engine/src/types";

// A stub adapter that records every time it is asked to send, so a test can
// assert the exact order the engine tries transports in.
function recordingAdapter(
  kind: TransportKind,
  log: TransportKind[],
  ok: boolean
): TransportAdapter {
  return {
    kind,
    available: () => true,
    send: async () => {
      log.push(kind);
      return { ok, transport: kind, latencyMs: 0, reason: `${kind} attempted` };
    },
  };
}

// Covers the hybrid mesh hop engine: how it selects a transport, falls back
// through the transport order, and stores packets when nothing can deliver.
// Pure simulation — it proves no live BLE.

function packet(): MeshPacket {
  return {
    id: "p1",
    type: "data",
    from: "A",
    to: "B",
    payload: { text: "hi" },
    createdAt: Date.now(),
    ttlMs: 60_000,
    hopCount: 0,
    maxHops: 8,
    path: [],
    reversePath: [],
    jumpCode: "JC",
  };
}

function decision(transport?: TransportKind): RouteDecision {
  return {
    decision: transport ? "ALLOW_DIRECT" : "STORE_FORWARD",
    selected: transport
      ? { peerId: "B", transport, score: 1, reason: "r", jumpCode: "JC" }
      : undefined,
    candidates: [],
    reason: "test reason",
  };
}

describe("HybridTransportEngine — transport selection and fallback", () => {
  it("uses the preferred transport when it is available", async () => {
    const engine = new HybridTransportEngine();
    engine.register(createSimulationAdapter());

    const result = await engine.send(packet(), decision("simulation"));
    expect(result.ok).toBe(true);
    expect(result.transport).toBe("simulation");
    expect(result.reason).toContain("[SIMULATION]");
    expect(result.reason).toContain("Not real BLE");
  });

  it("falls back through the transport order when the preferred one is missing", async () => {
    const engine = new HybridTransportEngine();
    engine.register(createSimulationAdapter());

    // Ask for BLE, which is not registered; the engine must fall back.
    const result = await engine.send(packet(), decision("ble"));
    expect(result.ok).toBe(true);
    expect(result.transport).toBe("simulation");
  });

  it("returns the governance reason when no route was selected", async () => {
    const engine = new HybridTransportEngine();
    engine.register(createSimulationAdapter());

    const result = await engine.send(packet(), decision(undefined));
    expect(result.ok).toBe(false);
    expect(result.transport).toBe("store-forward");
    expect(result.reason).toBe("test reason");
  });

  it("reports failure when no transport adapter can deliver", async () => {
    const engine = new HybridTransportEngine();
    const result = await engine.send(packet(), decision("ble"));
    expect(result.ok).toBe(false);
    expect(result.transport).toBe("store-forward");
    expect(result.reason).toContain("No available hybrid transport");
  });

  it("enqueues the packet through the store-forward adapter", async () => {
    const engine = new HybridTransportEngine();
    const queue: MeshPacket[] = [];
    engine.register(createStoreForwardAdapter(queue));

    const result = await engine.send(packet(), decision("store-forward"));
    expect(result.ok).toBe(false);
    expect(queue).toHaveLength(1);
    expect(queue[0].id).toBe("p1");
  });

  it("attempts transports in the engine's fallback order and short-circuits on first success", async () => {
    const engine = new HybridTransportEngine();
    const log: TransportKind[] = [];
    // Register out of order; the engine must still try them by its own order:
    // ble -> wifi-lan -> webrtc -> internet-api -> store-forward -> simulation.
    engine.register(recordingAdapter("webrtc", log, false));
    engine.register(recordingAdapter("internet-api", log, true));
    engine.register(recordingAdapter("wifi-lan", log, false));
    engine.register(recordingAdapter("ble", log, false));

    // Preferred transport is absent (no preferred match) so the fallback runs.
    const result = await engine.send(packet(), decision("satellite" as TransportKind));

    expect(log).toEqual(["ble", "wifi-lan", "webrtc", "internet-api"]);
    expect(result.ok).toBe(true);
    expect(result.transport).toBe("internet-api");
  });

  it("never reports BLE when only the simulation transport delivered (truth boundary)", async () => {
    const engine = new HybridTransportEngine();
    engine.register(createSimulationAdapter());

    // The route asked for BLE, but only simulation exists; the result must be
    // labelled simulation and must NOT claim it went over a BLE radio.
    const result = await engine.send(packet(), decision("ble"));
    expect(result.transport).not.toBe("ble");
    expect(result.transport).toBe("simulation");
    expect(result.reason).toContain("Not real BLE");
  });
});
