import { mauriMeshBridge } from "../maurimesh-client";
import type { MeshReceivedMessage } from "./meshReceiveLoop";

/**
 * Fetches the inbox for `myNodeId` from the MauriMesh HTTP bridge and maps
 * the wire-format MeshMessage into the richer MeshReceivedMessage shape.
 *
 * Fields not present in the bridge response are given sensible defaults:
 *   - recipientId: myNodeId
 *   - priority: "NORMAL"
 *   - hopCount: 1 (bridge path = single hop from relay to recipient)
 */
export async function getMeshInbox(
  myNodeId: string
): Promise<MeshReceivedMessage[]> {
  const nodes = await mauriMeshBridge.nodes();
  const myNode = nodes.find((n) => n.nodeId === myNodeId);
  if (!myNode) return [];

  return myNode.receivedMessages
    .filter((msg) => msg.senderId !== myNodeId)
    .map((msg) => ({
      id: msg.id,
      senderId: msg.senderId,
      recipientId: myNodeId,
      payload: msg.payload,
      priority: "NORMAL" as const,
      hopCount: 1,
      timestamp: msg.timestamp,
    }));
}
