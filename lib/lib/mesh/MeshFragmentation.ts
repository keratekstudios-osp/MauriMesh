/**
 * MeshFragmentation — split and reassemble large BLE payloads.
 *
 * BLE ATT MTU is 23–517 bytes. After GATT overhead a safe user payload is
 * ~244 bytes. JSON messages easily exceed this, so we fragment before
 * writing and reassemble after receiving.
 *
 * Fragment wire format (each fragment is itself sent as a JSON string):
 *   { messageId, from, to, index, total, payload }
 *
 * The payload field carries a chunk of the original message as a base64
 * string so binary-safe transport is guaranteed.
 */

export interface MeshFragment {
  messageId: string;
  from:      string;
  to:        string;
  index:     number;   // 0-based
  total:     number;
  payload:   string;   // base64 chunk of the original JSON
}

const DEFAULT_MAX_BYTES = 244;

// ── Encoding helpers ──────────────────────────────────────────────────────────

function toBase64(str: string): string {
  // btoa is available globally in React Native 0.70+
  return btoa(unescape(encodeURIComponent(str)));
}

function fromBase64(b64: string): string {
  return decodeURIComponent(escape(atob(b64)));
}

// ── Split ─────────────────────────────────────────────────────────────────────

/**
 * Fragment a JSON string into BLE-safe chunks.
 *
 * @param json      The full JSON message string to fragment.
 * @param from      Sender node ID (embedded in every fragment).
 * @param to        Recipient node ID (embedded in every fragment).
 * @param messageId Stable ID for this message (used to reassemble).
 * @param maxBytes  Maximum byte length per fragment payload (default 244).
 */
export function fragmentMessage(
  json: string,
  from: string,
  to: string,
  messageId: string,
  maxBytes: number = DEFAULT_MAX_BYTES
): MeshFragment[] {
  const b64 = toBase64(json);
  const chunks: string[] = [];
  for (let i = 0; i < b64.length; i += maxBytes) {
    chunks.push(b64.slice(i, i + maxBytes));
  }

  return chunks.map((chunk, index) => ({
    messageId,
    from,
    to,
    index,
    total: chunks.length,
    payload: chunk,
  }));
}

/**
 * Check whether the given string looks like a serialised MeshFragment.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function isMeshFragment(value: any): value is MeshFragment {
  return (
    value &&
    typeof value === "object" &&
    typeof value.messageId === "string" &&
    typeof value.from === "string" &&
    typeof value.to === "string" &&
    typeof value.index === "number" &&
    typeof value.total === "number" &&
    typeof value.payload === "string"
  );
}

// ── Reassemble ────────────────────────────────────────────────────────────────

/**
 * Accumulate fragments and return the original JSON string once all arrive.
 * Returns null while still waiting for more fragments.
 *
 * Usage: create one `FragmentReassembler` per active incoming message ID.
 */
export class FragmentReassembler {
  private readonly buffers = new Map<string, string[]>();

  /**
   * Feed one fragment.  Returns the reassembled JSON if this was the last
   * piece, or null if more fragments are still expected.
   */
  feed(fragment: MeshFragment): string | null {
    const { messageId, index, total, payload } = fragment;

    if (!this.buffers.has(messageId)) {
      this.buffers.set(messageId, new Array(total).fill(""));
    }

    const buf = this.buffers.get(messageId)!;
    buf[index] = payload;

    if (buf.some((chunk) => chunk === "")) return null;

    this.buffers.delete(messageId);
    try {
      return fromBase64(buf.join(""));
    } catch {
      return null;
    }
  }

  /** Discard state for a given message (e.g. on timeout). */
  discard(messageId: string): void {
    this.buffers.delete(messageId);
  }

  /** Active in-progress message IDs. */
  pending(): string[] {
    return [...this.buffers.keys()];
  }
}

/**
 * One-shot reassembly for cases where all fragments are already available.
 * Returns null if fragments are incomplete or out of range.
 */
export function reassembleFragments(fragments: MeshFragment[]): string | null {
  if (!fragments.length) return null;

  const { messageId, total } = fragments[0];
  if (fragments.length !== total) return null;
  if (fragments.some((f) => f.messageId !== messageId)) return null;

  const sorted = [...fragments].sort((a, b) => a.index - b.index);
  const b64 = sorted.map((f) => f.payload).join("");

  try {
    return fromBase64(b64);
  } catch {
    return null;
  }
}
