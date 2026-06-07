// maurimesh-bridge-contract.ts

export type MeshPriority = "LOW" | "NORMAL" | "HIGH" | "EMERGENCY";

export type MeshNodeId = string;

export interface MeshStats {
  totalNodes: number;
  totalMessagesDelivered: number;
  totalAcksDelivered: number;
  avgHopCount: number;
  maxHopCount: number;
  totalPendingAcks: number;
  totalQueueDepth: number;
  totalRoutingEntries: number;
  round: number;
  messagesInjected: number;
  uptimeMs: number;
}

export interface MeshMessage {
  id: string;
  senderId: MeshNodeId;
  recipientId: MeshNodeId | "BROADCAST";
  payload: string;
  priority: MeshPriority;
  hopCount: number;
  maxHops: number;
  prevHopId?: MeshNodeId;
  requiresAck: boolean;
  timestamp: number;
  isExpired: boolean;
}

export interface MeshNodeStatus {
  nodeId: MeshNodeId;
  neighbours: MeshNodeId[];
  receivedMessages: MeshMessage[];
  pendingAcks: number;
  queueDepth: number;
  routingTable: Record<MeshNodeId, MeshNodeId>;
}

export interface MeshInjectRequest {
  fromNode: MeshNodeId;
  toNode: MeshNodeId | "BROADCAST";
  message: string;
  priority: MeshPriority;
}

export interface MeshInjectResponse {
  ok: boolean;
  messageId: string;
  from: MeshNodeId;
  to: MeshNodeId | "BROADCAST";
  priority: MeshPriority;
}