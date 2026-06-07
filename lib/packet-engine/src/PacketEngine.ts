import {
  CanonicalMeshPacketSchema,
  PACKET_FIELD_DESCRIPTIONS,
  PACKET_TYPE_DESCRIPTIONS,
  PacketTypeSchema,
  PayloadTypeSchema,
  PROTOCOL_VERSION,
  type CanonicalMeshPacket,
  type PacketType,
  type PayloadType,
} from "./schema";
import { sha256Hex } from "./sha256";

const DEFAULT_TTL = 7;
const DEFAULT_TTL_SECONDS = 86_400; // 24 hours

const ACK_REQUIRED_TYPES: ReadonlySet<PacketType> = new Set<PacketType>([
  "message",
  "proof_event",
]);

export interface BuildOptions {
  packetType: PacketType;
  fromPeerId: string;
  toPeerId: string;
  payload?: string;
  payloadType?: PayloadType;
  ttl?: number;
  ttlSeconds?: number;
  ackRequired?: boolean;
  routeId?: string;
  nextHopId?: string;
  previousHopId?: string;
}

export type ValidateResult =
  | { ok: true; packet: CanonicalMeshPacket }
  | { ok: false; error: string };

function generateUUID(): string {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

export class PacketEngine {
  /**
   * Build a new canonical MauriMesh packet with a fresh UUID, timestamps,
   * payloadHash (SHA-256 of the payload string), and all mandatory fields.
   *
   * `signature` is left undefined — it is populated by the E2E encryption task.
   */
  static build(opts: BuildOptions): CanonicalMeshPacket {
    const now     = Date.now();
    const ttl     = opts.ttl ?? DEFAULT_TTL;
    const ttlMs   = (opts.ttlSeconds ?? DEFAULT_TTL_SECONDS) * 1000;
    const payload = opts.payload ?? "";
    return {
      protocolVersion: PROTOCOL_VERSION,
      packetId:        generateUUID(),
      packetType:      opts.packetType,
      fromPeerId:      opts.fromPeerId,
      toPeerId:        opts.toPeerId,
      routeId:         opts.routeId,
      ttl,
      hopIndex:        0,
      createdAt:       now,
      expiresAt:       now + ttlMs,
      payloadType:     opts.payloadType ?? "text",
      payload,
      payloadHash:     sha256Hex(payload),
      signature:       null, // null placeholder until E2E encryption task
      ackRequired:     opts.ackRequired ?? ACK_REQUIRED_TYPES.has(opts.packetType),
      previousHopId:   opts.previousHopId,
      nextHopId:       opts.nextHopId,
    };
  }

  /**
   * Validate a plain object against the canonical packet schema, then verify
   * payload integrity: payloadHash must equal sha256Hex(payload).
   *
   * Returns the typed packet on success, or a descriptive error string on failure.
   */
  static validate(raw: unknown): ValidateResult {
    const result = CanonicalMeshPacketSchema.safeParse(raw);
    if (!result.success) {
      return {
        ok:    false,
        error: result.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; "),
      };
    }
    // Payload integrity check — guard against tampered or corrupted packets.
    const expected = sha256Hex(result.data.payload);
    if (expected !== result.data.payloadHash) {
      return {
        ok:    false,
        error: `payloadHash integrity failure — computed ${expected.slice(0, 16)}… but received ${result.data.payloadHash.slice(0, 16)}…`,
      };
    }
    return { ok: true, packet: result.data };
  }

  /**
   * Parse a JSON string and validate against the canonical packet schema.
   * Includes payload integrity verification (payloadHash must match SHA-256 of payload).
   */
  static parse(json: string): ValidateResult {
    let parsed: unknown;
    try {
      parsed = JSON.parse(json);
    } catch {
      return { ok: false, error: "Invalid JSON" };
    }
    return PacketEngine.validate(parsed);
  }

  /**
   * Returns true if the packet's expiresAt timestamp is in the past.
   */
  static isExpired(packet: CanonicalMeshPacket): boolean {
    return Date.now() >= packet.expiresAt;
  }

  /**
   * Returns true if the packet should be dropped:
   *   - TTL has reached 0, OR
   *   - The packet has expired (expiresAt in the past).
   */
  static shouldDrop(packet: CanonicalMeshPacket): boolean {
    return packet.ttl === 0 || PacketEngine.isExpired(packet);
  }

  /**
   * Return a new packet with TTL decremented by 1 and hopIndex incremented by 1.
   *
   * @param packet       The packet being relayed.
   * @param relayNodeId  The node ID of the node DOING the relaying (i.e. `myNodeId`
   *                     in the relay path). This is recorded as `previousHopId` so
   *                     downstream nodes know which node last forwarded the packet.
   *                     Must NOT be the packet's original `fromPeerId`.
   * @param nextHopId    Optional: the node this packet will be forwarded to next.
   *
   * Does NOT mutate the original packet.
   */
  static decrement(
    packet: CanonicalMeshPacket,
    relayNodeId: string,
    nextHopId?: string
  ): CanonicalMeshPacket {
    return {
      ...packet,
      ttl:           Math.max(0, packet.ttl - 1),
      hopIndex:      packet.hopIndex + 1,
      previousHopId: relayNodeId,
      nextHopId:     nextHopId ?? packet.nextHopId,
    };
  }

  /**
   * Build an ACK packet in response to a received packet.
   * ACKs expire in 5 minutes and have a shorter TTL (3 hops).
   * Payload JSON: { "ackFor": "<original packetId>" }
   */
  static makeAck(original: CanonicalMeshPacket, fromPeerId: string): CanonicalMeshPacket {
    return PacketEngine.build({
      packetType:  "ack",
      fromPeerId,
      toPeerId:    original.fromPeerId,
      payload:     JSON.stringify({ ackFor: original.packetId }),
      payloadType: "json",
      ackRequired: false,
      routeId:     original.routeId,
      ttl:         3,
      ttlSeconds:  300,
    });
  }

  /**
   * Build a discovery packet so a peer can announce itself to the mesh.
   */
  static makeDiscovery(opts: {
    fromPeerId: string;
    displayName?: string;
    publicKey?: string;
  }): CanonicalMeshPacket {
    return PacketEngine.build({
      packetType:  "discovery",
      fromPeerId:  opts.fromPeerId,
      toPeerId:    "BROADCAST",
      payload:     JSON.stringify({
        displayName: opts.displayName ?? opts.fromPeerId,
        publicKey:   opts.publicKey ?? "",
      }),
      payloadType: "json",
      ackRequired: false,
      ttl:         5,
      ttlSeconds:  60,
    });
  }

  /**
   * Returns the schema definition used by GET /packet-schema.
   */
  static schemaDefinition(): object {
    return {
      protocolVersion:   PROTOCOL_VERSION,
      packetTypes:       PacketTypeSchema.options,
      payloadTypes:      PayloadTypeSchema.options,
      defaultTtl:        DEFAULT_TTL,
      defaultTtlSeconds: DEFAULT_TTL_SECONDS,
      fields:            PACKET_FIELD_DESCRIPTIONS,
      packetTypeDetails: PACKET_TYPE_DESCRIPTIONS,
    };
  }
}
