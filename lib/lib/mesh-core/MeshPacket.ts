import { PacketType, type MeshPacket } from "./types";

const DEFAULT_TTL = 6;
const DEFAULT_LIFETIME_MS = 5 * 60 * 1000;

let _counter = 0;

function newId(): string {
  _counter = (_counter + 1) % 1_000_000;
  return `pkt-${Date.now().toString(36)}-${_counter.toString(36).padStart(4, "0")}-${Math.random().toString(36).slice(2, 7)}`;
}

export interface PacketOptions {
  type?: PacketType;
  toNodeId?: string;
  payload?: string;
  ttl?: number;
  lifetimeMs?: number;
  fragmentIndex?: number;
  fragmentTotal?: number;
}

export function createPacket(
  fromNodeId: string,
  opts: PacketOptions = {}
): MeshPacket {
  const now = Date.now();
  return {
    id: newId(),
    type: opts.type ?? PacketType.CHAT,
    fromNodeId,
    toNodeId: opts.toNodeId ?? "BROADCAST",
    routePath: [fromNodeId],
    ttl: opts.ttl ?? DEFAULT_TTL,
    createdAt: now,
    expiresAt: now + (opts.lifetimeMs ?? DEFAULT_LIFETIME_MS),
    payload: opts.payload ?? "",
    ...(opts.fragmentIndex !== undefined ? { fragmentIndex: opts.fragmentIndex } : {}),
    ...(opts.fragmentTotal !== undefined ? { fragmentTotal: opts.fragmentTotal } : {}),
  };
}

export function isExpired(packet: MeshPacket): boolean {
  return Date.now() > packet.expiresAt || packet.ttl <= 0;
}

export function decrementTtl(packet: MeshPacket): MeshPacket {
  return { ...packet, ttl: packet.ttl - 1 };
}

export function appendRoute(packet: MeshPacket, nodeId: string): MeshPacket {
  return {
    ...packet,
    routePath: [...packet.routePath, nodeId],
  };
}
