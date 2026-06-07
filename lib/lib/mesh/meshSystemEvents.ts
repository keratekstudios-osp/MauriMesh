import { mauriMeshBridge } from "../maurimesh-client";

export interface MeshSystemEvent {
  id: string;
  type: string;
  from: string;
  to: string;
  body: string;
  timestamp: number;
  ttl: number;
  hopCount: number;
}

export async function sendMeshSystemEvent(event: MeshSystemEvent): Promise<void> {
  await mauriMeshBridge.sendMessengerText({
    fromNode: event.from,
    toNode: event.to,
    text: JSON.stringify({ eventType: event.type, body: event.body }),
  });
}
