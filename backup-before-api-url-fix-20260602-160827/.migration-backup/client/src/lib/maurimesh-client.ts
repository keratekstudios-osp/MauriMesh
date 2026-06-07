// maurimesh-client.ts

import type {
  MeshStats,
  MeshNodeStatus,
  MeshInjectRequest,
  MeshInjectResponse,
} from "./maurimesh-bridge-contract";

const MESH_API_BASE =
  import.meta.env.VITE_MESH_API_BASE ?? "http://127.0.0.1:4300";

async function api<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${MESH_API_BASE}${path}`, init);

  if (!res.ok) {
    throw new Error(`MauriMesh API failed: ${res.status} ${path}`);
  }

  return res.json() as Promise<T>;
}

export const mauriMeshBridge = {
  stats(): Promise<MeshStats> {
    return api<MeshStats>("/mesh/stats");
  },

  nodes(): Promise<MeshNodeStatus[]> {
    return api<MeshNodeStatus[]>("/mesh/nodes");
  },

  inject(body: MeshInjectRequest): Promise<MeshInjectResponse> {
    return api<MeshInjectResponse>("/mesh/inject", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
  },

  sendMessengerText(params: {
    fromNode: string;
    toNode: string;
    text: string;
    emergency?: boolean;
  }): Promise<MeshInjectResponse> {
    return this.inject({
      fromNode: params.fromNode,
      toNode: params.toNode,
      message: params.text,
      priority: params.emergency ? "EMERGENCY" : "NORMAL",
    });
  },

  broadcast(params: {
    fromNode: string;
    text: string;
    emergency?: boolean;
  }): Promise<MeshInjectResponse> {
    return this.inject({
      fromNode: params.fromNode,
      toNode: "BROADCAST",
      message: params.text,
      priority: params.emergency ? "EMERGENCY" : "HIGH",
    });
  },
};