import { z } from "zod";

export const PROTOCOL_VERSION = 1 as const;

/**
 * All first-class packet types in the MauriMesh protocol.
 *
 * discovery        — peer announces its presence on the mesh
 * message          — user chat / data payload
 * ack              — delivery acknowledgement for a prior packet
 * route_probe      — ICMP-ping-style hop-count / latency test
 * route_reply      — response to a route_probe
 * trust_event      — trust-record update (ban / vouch / decay)
 * mesh_notification — system-level alert (battery, congestion, OTA)
 * audio_frame      — real-time audio chunk (codec defined in payload)
 * governance_event — route decision logged by RouteSafetyEngine
 * proof_event      — two-phone BLE proof packet
 */
export const PacketTypeSchema = z.enum([
  "discovery",
  "message",
  "ack",
  "route_probe",
  "route_reply",
  "trust_event",
  "mesh_notification",
  "audio_frame",
  "governance_event",
  "proof_event",
]);

export type PacketType = z.infer<typeof PacketTypeSchema>;

/**
 * Encoding convention for the `payload` string field.
 *
 * text       — UTF-8 plaintext
 * binary     — base64-encoded binary blob
 * json       — JSON-serialised object (must be valid JSON)
 * audio_opus — base64-encoded Opus frame
 * empty      — payload is meaningless / omitted (use for pure-control packets)
 */
export const PayloadTypeSchema = z.enum([
  "text",
  "binary",
  "json",
  "audio_opus",
  "empty",
]);

export type PayloadType = z.infer<typeof PayloadTypeSchema>;

/**
 * Canonical MauriMesh packet — the authoritative wire format.
 *
 * Every packet sent over BLE, WiFi-LAN, WebRTC, or store-forward MUST
 * conform to this schema.  The Rust JNI engine validates the same fields
 * (using Serde) and the TypeScript PacketEngine validates at the API layer.
 */
export const CanonicalMeshPacketSchema = z.object({
  protocolVersion: z.literal(1)
    .describe("Protocol schema version. Currently 1."),

  packetId: z.string().uuid()
    .describe("UUID v4. Unique per packet; used for deduplication and ACK correlation."),

  packetType: PacketTypeSchema
    .describe("One of the 10 defined packet types."),

  fromPeerId: z.string().min(1)
    .describe("Node ID of the originating peer."),

  toPeerId: z.string().min(1)
    .describe("Node ID of the destination peer, or 'BROADCAST' for flood packets."),

  routeId: z.string().optional()
    .describe("Optional route identifier assigned by the routing engine."),

  ttl: z.number().int().min(0).max(255)
    .describe("Time-to-live hop counter. Decremented at each relay. Dropped at 0."),

  hopIndex: z.number().int().min(0)
    .describe("Number of hops taken so far. Incremented at each relay."),

  createdAt: z.number().int().positive()
    .describe("Unix timestamp (ms) when the packet was first created."),

  expiresAt: z.number().int().positive()
    .describe("Unix timestamp (ms) after which the packet MUST be dropped."),

  payloadType: PayloadTypeSchema
    .describe("Encoding hint for the payload field."),

  payload: z.string()
    .describe("Packet body. Interpretation depends on payloadType and packetType."),

  payloadHash: z.string()
    .describe("SHA-256 hex digest of the raw payload string. Always present; computed by PacketEngine.build()."),

  signature: z.string().nullable()
    .describe("Ed25519 signature. null until the encryption task populates it."),

  ackRequired: z.boolean()
    .describe("If true, the destination MUST send an ack packet on delivery."),

  previousHopId: z.string().optional()
    .describe("Node ID of the peer that forwarded this packet to us."),

  nextHopId: z.string().optional()
    .describe("Node ID of the peer this packet will be forwarded to next."),
});

export type CanonicalMeshPacket = z.infer<typeof CanonicalMeshPacketSchema>;

export const PACKET_FIELD_DESCRIPTIONS: Record<keyof CanonicalMeshPacket, string> = {
  protocolVersion: "Protocol schema version. Currently 1.",
  packetId:        "UUID v4. Unique per packet; used for deduplication and ACK correlation.",
  packetType:      "One of the 10 defined packet types.",
  fromPeerId:      "Node ID of the originating peer.",
  toPeerId:        "Node ID of the destination peer, or 'BROADCAST' for flood packets.",
  routeId:         "Optional route identifier assigned by the routing engine.",
  ttl:             "Time-to-live hop counter. Decremented at each relay. Dropped at 0.",
  hopIndex:        "Number of hops taken so far. Incremented at each relay.",
  createdAt:       "Unix timestamp (ms) when the packet was first created.",
  expiresAt:       "Unix timestamp (ms) after which the packet MUST be dropped.",
  payloadType:     "Encoding hint for the payload field.",
  payload:         "Packet body. Interpretation depends on payloadType and packetType.",
  payloadHash:     "SHA-256 hex digest of the raw payload string. Always present; computed by PacketEngine.build().",
  signature:       "Ed25519 signature. null until the encryption task populates it.",
  ackRequired:     "If true, the destination MUST send an ack packet on delivery.",
  previousHopId:   "Node ID of the peer that forwarded this packet to us.",
  nextHopId:       "Node ID of the peer this packet will be forwarded to next.",
};

export const PACKET_TYPE_DESCRIPTIONS: Record<PacketType, string> = {
  discovery:         "Peer announces its presence and public identity on the mesh.",
  message:           "User-originated chat or data payload. ackRequired = true.",
  ack:               "Delivery acknowledgement. Payload JSON: { ackFor: packetId }.",
  route_probe:       "ICMP-ping-style test. Receiver replies with route_reply.",
  route_reply:       "Response to a route_probe. Carries RTT and hop metadata.",
  trust_event:       "Trust record update: ban, vouch, decay, or verify.",
  mesh_notification: "System-level alert: battery critical, congestion, OTA available.",
  audio_frame:       "Real-time audio chunk. payloadType = 'audio_opus'.",
  governance_event:  "Route decision logged by RouteSafetyEngine.",
  proof_event:       "Two-phone BLE proof packet used in TwoPhoneProofMode.",
};
