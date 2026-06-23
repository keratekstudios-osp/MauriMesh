import type { LiveMeshState, MeshNodeRecord, NativeBleScanStatus } from "./types";

export type MeshEvent =
  | {
      type: "native_status";
      createdAt: string;
      status: NativeBleScanStatus;
    }
  | {
      type: "node_seen";
      createdAt: string;
      node: MeshNodeRecord;
    }
  | {
      type: "state_updated";
      createdAt: string;
      state: LiveMeshState;
    }
  | {
      type: "error";
      createdAt: string;
      message: string;
      source: string;
    };

type Listener = (event: MeshEvent) => void;

const listeners = new Set<Listener>();

export function subscribeMeshEvents(listener: Listener): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function publishMeshEvent(event: MeshEvent): void {
  for (const listener of listeners) {
    try {
      listener(event);
    } catch {
      // Never let one screen crash the live mesh event bus.
    }
  }
}
