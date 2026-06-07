const MESH_API_BASE =
  process.env.EXPO_PUBLIC_MESH_API_BASE ?? "https://mauri-mesh-messenger.replit.app/api";

export interface MeshNode {
  nodeId: string;
  receivedMessages: MeshMessage[];
}

export interface MeshMessage {
  id: string;
  senderId: string;
  payload: string;
  timestamp: number;
}

async function nodes(): Promise<MeshNode[]> {
  const res = await fetch(`${MESH_API_BASE}/mesh/nodes`);
  if (!res.ok) throw new Error(`Failed to fetch nodes: ${res.status}`);
  return res.json();
}

async function sendMessengerText(params: {
  fromNode: string;
  toNode: string;
  text: string;
}): Promise<void> {
  const res = await fetch(`${MESH_API_BASE}/messenger/send`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(params),
  });
  if (!res.ok) throw new Error(`Send failed: ${res.status}`);
}

export const mauriMeshBridge = { nodes, sendMessengerText };
