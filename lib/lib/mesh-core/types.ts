export enum NodeStatus {
  SELF = "SELF",
  TRUSTED = "TRUSTED",
  RELAY = "RELAY",
  UNKNOWN = "UNKNOWN",
  DEGRADED = "DEGRADED",
}

export enum PacketType {
  CHAT = "CHAT",
  ACK = "ACK",
  PING = "PING",
  PONG = "PONG",
  PULSE = "PULSE",
  STORE_FORWARD = "STORE_FORWARD",
}

export interface MeshPacket {
  id: string;
  type: PacketType;
  fromNodeId: string;
  toNodeId: string;
  routePath: string[];
  ttl: number;
  createdAt: number;
  expiresAt: number;
  payload: string;
  fragmentIndex?: number;
  fragmentTotal?: number;
}

export interface MeshNode {
  nodeId: string;
  displayName: string;
  status: NodeStatus;
  rssi?: number;
  lastSeenAt: number;
  trustScore: number;
}

export interface RouteEntry {
  toNodeId: string;
  viaNodeId: string;
  hopCount: number;
  score: number;
  updatedAt: number;
}

export interface TrustRecord {
  nodeId: string;
  score: number;
  successCount: number;
  failureCount: number;
  lastAckAt: number;
}

export interface AckRecord {
  packetId: string;
  ackedAt: number;
  fromNodeId: string;
}
