type NodeStatus = "ONLINE" | "OFFLINE_LOGGED_OUT" | "OFFLINE";

const nodeState: Record<string, NodeStatus> = {};

export async function markLocalNodeOffline(nodeId: string): Promise<void> {
  nodeState[nodeId] = "OFFLINE_LOGGED_OUT";
}

export function getNodeStatus(nodeId: string): NodeStatus | undefined {
  return nodeState[nodeId];
}
