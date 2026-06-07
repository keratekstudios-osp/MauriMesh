import type { MeshPacket } from "./maurimesh-intelligent-contract";

/**
 * Maximum characters allowed in a single fragment's `chunk` field.
 * Conservative limit: accounts for BLE MTU (512 bytes typical) minus the
 * FragmentEnvelope JSON wrapper overhead (~120 chars). Tunable constant.
 */
export const FRAGMENT_CHUNK_MAX = 160;

/** Partial fragment sets older than this are evicted and logged as drops. */
export const FRAGMENT_TTL_MS = 60_000;

/**
 * Fragment envelope — one slice of a serialized MeshPacket.
 * Sent as a BleMessage.payload (JSON-stringified).
 * Distinguished from a full MeshPacket by the `f: 1` marker.
 *
 * Design rules (enforced by the caller, not this file):
 *  - ACK packets are NEVER fragmented.
 *  - Fragmentation happens AFTER the full packet (routePath, reversePath,
 *    ttl, hopCount) is finalized — every fragment carries the same routing
 *    metadata via the reassembled packet.
 *  - Reassembly happens BEFORE relay or ACK logic — fragments are never
 *    forwarded individually.
 */
export interface FragmentEnvelope {
  /** Marker: always 1. Distinguishes envelopes from full MeshPackets. */
  f: 1;
  /** packetId of the original MeshPacket being fragmented. */
  packetId: string;
  /** fromNodeId of the original packet — for peer resolution at each hop. */
  fromNodeId: string;
  /** 0-based position of this chunk in the sequence. */
  fragmentIndex: number;
  /** Total number of chunks for this packetId. */
  fragmentCount: number;
  /** Total character length of the serialized original packet. */
  totalBytes: number;
  /**
   * Integrity checksum of the full reassembled JSON string (djb2-style).
   * Verified by FragmentCollector after reassembly before parsing.
   */
  checksum: string;
  /** This fragment's slice of the serialized MeshPacket JSON. */
  chunk: string;
}

/** Type-guard: true when `obj` is a FragmentEnvelope, not a MeshPacket. */
export function isFragmentEnvelope(obj: unknown): obj is FragmentEnvelope {
  return (
    typeof obj === "object" &&
    obj !== null &&
    (obj as Record<string, unknown>).f === 1 &&
    typeof (obj as FragmentEnvelope).packetId === "string" &&
    typeof (obj as FragmentEnvelope).fragmentIndex === "number" &&
    typeof (obj as FragmentEnvelope).chunk === "string"
  );
}

function computeChecksum(s: string): string {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  }
  return (h >>> 0).toString(16);
}

/**
 * Serialize `packet` and split it into fragment envelopes when needed.
 *
 * Returns `null` when the serialized form fits within FRAGMENT_CHUNK_MAX chars
 * (no fragmentation needed — caller sends a plain BleMessage).
 *
 * Returns an ordered array of FragmentEnvelopes otherwise. The caller sends
 * each envelope as a separate BleMessage to the same BLE device.
 *
 * CALLER RESPONSIBILITY: never call this for ACK packets.
 */
export function fragmentPacket(packet: MeshPacket): FragmentEnvelope[] | null {
  const serialized = JSON.stringify(packet);
  if (serialized.length <= FRAGMENT_CHUNK_MAX) {
    return null;
  }
  const cs = computeChecksum(serialized);
  const chunks: string[] = [];
  for (let i = 0; i < serialized.length; i += FRAGMENT_CHUNK_MAX) {
    chunks.push(serialized.slice(i, i + FRAGMENT_CHUNK_MAX));
  }
  return chunks.map((chunk, idx): FragmentEnvelope => ({
    f: 1,
    packetId: packet.packetId,
    fromNodeId: packet.fromNodeId,
    fragmentIndex: idx,
    fragmentCount: chunks.length,
    totalBytes: serialized.length,
    checksum: cs,
    chunk,
  }));
}

interface PartialSet {
  chunks: Map<number, string>;
  fragmentCount: number;
  checksum: string;
  firstSeenAt: number;
}

/**
 * Accumulates FragmentEnvelopes and reassembles them into full MeshPackets.
 *
 * Guarantees:
 *  - Duplicate fragments (same packetId + fragmentIndex) are silently ignored.
 *  - Out-of-order arrival is supported (indexed map, sorted on completion).
 *  - Partial sets expire after `ttlMs` and are logged as [FragmentDrop].
 *  - Checksum mismatch after reassembly logs [FragmentDrop] and returns null.
 *  - No routing, relay, or ACK logic — purely a data-collection primitive.
 */
export class FragmentCollector {
  private readonly sets = new Map<string, PartialSet>();
  private readonly ttlMs: number;

  constructor(ttlMs = FRAGMENT_TTL_MS) {
    this.ttlMs = ttlMs;
  }

  /**
   * Register one fragment envelope.
   *
   * Returns the reassembled MeshPacket when all fragments have arrived and
   * the checksum passes. Returns `null` in all other cases (incomplete set,
   * duplicate, checksum failure, or parse error).
   */
  addFragment(env: FragmentEnvelope): MeshPacket | null {
    this.evictExpired();

    const { packetId, fragmentIndex, fragmentCount, checksum: cs, chunk } = env;

    let set = this.sets.get(packetId);
    if (!set) {
      set = {
        chunks: new Map(),
        fragmentCount,
        checksum: cs,
        firstSeenAt: Date.now(),
      };
      this.sets.set(packetId, set);
    }

    if (set.chunks.has(fragmentIndex)) return null; // duplicate — ignore silently
    set.chunks.set(fragmentIndex, chunk);

    if (set.chunks.size < set.fragmentCount) return null; // still incomplete

    // All fragments present — join in index order.
    const parts: string[] = [];
    for (let i = 0; i < set.fragmentCount; i++) {
      const c = set.chunks.get(i);
      if (c === undefined) return null; // gap (shouldn't happen; guard anyway)
      parts.push(c);
    }
    const serialized = parts.join("");
    this.sets.delete(packetId);

    if (computeChecksum(serialized) !== cs) {
      console.log(
        `[MauriMesh][FragmentDrop] checksum mismatch packetId=${packetId}`
      );
      return null;
    }

    try {
      return JSON.parse(serialized) as MeshPacket;
    } catch {
      console.log(
        `[MauriMesh][FragmentDrop] JSON parse error packetId=${packetId}`
      );
      return null;
    }
  }

  /** Number of packetIds with in-progress fragment sets. */
  pendingCount(): number {
    return this.sets.size;
  }

  private evictExpired(): void {
    const now = Date.now();
    for (const [packetId, set] of this.sets) {
      if (now - set.firstSeenAt > this.ttlMs) {
        console.log(
          `[MauriMesh][FragmentDrop] expired packetId=${packetId}` +
          ` received=${set.chunks.size}/${set.fragmentCount}`
        );
        this.sets.delete(packetId);
      }
    }
  }
}
