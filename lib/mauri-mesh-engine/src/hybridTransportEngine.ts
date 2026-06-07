import { MeshPacket, RouteDecision, TransportKind } from "./types";

export type TransportSendResult = {
  ok: boolean;
  transport: TransportKind;
  latencyMs: number;
  reason: string;
};

export type TransportAdapter = {
  kind: TransportKind;
  available: () => Promise<boolean> | boolean;
  send: (packet: MeshPacket, peerId: string) => Promise<TransportSendResult>;
};

export class HybridTransportEngine {
  private adapters = new Map<TransportKind, TransportAdapter>();

  register(adapter: TransportAdapter): void {
    this.adapters.set(adapter.kind, adapter);
  }

  async send(packet: MeshPacket, decision: RouteDecision): Promise<TransportSendResult> {
    if (!decision.selected) {
      return {
        ok: false,
        transport: "store-forward",
        latencyMs: 0,
        reason: decision.reason,
      };
    }

    const preferred = this.adapters.get(decision.selected.transport);
    if (preferred && (await preferred.available())) {
      return preferred.send(packet, decision.selected.peerId);
    }

    const fallbackOrder: TransportKind[] = [
      "ble",
      "wifi-lan",
      "webrtc",
      "internet-api",
      "store-forward",
      "simulation",
    ];

    for (const kind of fallbackOrder) {
      const adapter = this.adapters.get(kind);
      if (!adapter) continue;
      if (!(await adapter.available())) continue;

      const result = await adapter.send(packet, decision.selected.peerId);
      if (result.ok) return result;
    }

    return {
      ok: false,
      transport: "store-forward",
      latencyMs: 0,
      reason: "No available hybrid transport could deliver packet.",
    };
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function createSimulationAdapter(): TransportAdapter {
  return {
    kind: "simulation",
    available: () => true,
    send: async (_packet: MeshPacket, _peerId: string): Promise<TransportSendResult> => {
      const started = Date.now();
      await sleep(30);
      return {
        ok: true,
        transport: "simulation",
        latencyMs: Date.now() - started,
        reason: "Simulation transport delivered packet locally. Not real BLE.",
      };
    },
  };
}

export function createStoreForwardAdapter(queue: MeshPacket[]): TransportAdapter {
  return {
    kind: "store-forward",
    available: () => true,
    send: async (packet: MeshPacket, _peerId: string): Promise<TransportSendResult> => {
      queue.push(packet);
      return {
        ok: false,
        transport: "store-forward",
        latencyMs: 0,
        reason: "Packet stored for later route availability.",
      };
    },
  };
}
