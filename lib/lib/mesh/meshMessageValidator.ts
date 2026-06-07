/**
 * meshMessageValidator — guards the BLE receive pipeline.
 *
 * Any packet arriving over the air is untrusted. This module validates the
 * wire-format MeshMessage before it enters the routing or inbox layer.
 */

import type { MeshPacketType } from "./maurimesh-intelligent-contract";

// Wire-format message (matches the checklist spec + Rust types.rs shape)
export interface MeshMessage {
  id: string;
  from: string;
  to: string;
  type: MeshPacketType | string;
  body?: string;
  timestamp: number;
  ttl: number;
  hopCount: number;
  route?: string[];
}

const VALID_TYPES: readonly string[] = [
  "text",
  "ack",
  "call_invite",
  "call_accept",
  "call_reject",
  "route_probe",
  "route_announce",
  "system",
  // legacy internal packet types (used by the router layer)
  "CHAT_MESSAGE",
  "ACK",
  "ROUTE_BEACON",
  "NODE_DISCOVERY",
  "STORE_FORWARD",
  "PIXEL_FRAME",
  "CALL_INVITE",
];

/**
 * Returns true when `value` is a structurally valid MeshMessage.
 * Does NOT throw — always returns a boolean.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function isValidMeshMessage(value: any): value is MeshMessage {
  if (!value || typeof value !== "object") return false;
  if (typeof value.id !== "string" || !value.id) return false;
  if (typeof value.from !== "string" || !value.from) return false;
  if (typeof value.to !== "string" || !value.to) return false;
  if (typeof value.timestamp !== "number") return false;
  if (typeof value.ttl !== "number" || value.ttl < 0) return false;
  if (typeof value.hopCount !== "number" || value.hopCount < 0) return false;
  if (typeof value.type !== "string" || !value.type) return false;
  if (value.body !== undefined && typeof value.body !== "string") return false;
  if (value.route !== undefined && !Array.isArray(value.route)) return false;
  // Body length guard — reject unreasonably large payloads
  if (value.body && value.body.length > 8192) return false;
  return true;
}

/**
 * Parse a raw JSON string into a validated MeshMessage.
 * Returns null on any parse or validation failure.
 */
export function parseMeshMessage(raw: string): MeshMessage | null {
  try {
    const parsed = JSON.parse(raw);
    return isValidMeshMessage(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

/**
 * Check whether the packet type is a known wire type.
 */
export function isKnownType(type: string): boolean {
  return VALID_TYPES.includes(type);
}
