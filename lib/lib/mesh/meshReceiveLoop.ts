import { getMeshInbox } from "./maurimeshMessengerAdapter";

export type MeshReceivedMessage = {
  id: string;
  senderId: string;
  recipientId: string;
  payload: string;
  priority: "LOW" | "NORMAL" | "HIGH" | "EMERGENCY";
  hopCount: number;
  timestamp: number;
};

export type MeshReceiveLoopParams = {
  myNodeId: string;
  onTextMessage: (msg: MeshReceivedMessage) => void;
  onCallInvite?: (invite: Record<string, unknown>, raw: MeshReceivedMessage) => void;
  onBridgeStatus?: (online: boolean) => void;
  intervalMs?: number;
};

/**
 * Starts a 1 s polling loop that fetches the MauriMesh inbox for `myNodeId`,
 * deduplicates by message ID, and dispatches to the appropriate callback:
 *
 *   - CALL_INVITE JSON payloads  → onCallInvite (skipped from onTextMessage)
 *   - ACK:-prefixed payloads     → silently dropped (transport control frames)
 *   - All other payloads         → onTextMessage
 *
 * Returns a cleanup function — call it from useEffect's return to stop the loop.
 */
export function startMeshReceiveLoop(params: MeshReceiveLoopParams): () => void {
  const seen = new Set<string>();
  const intervalMs = params.intervalMs ?? 1000;

  const timer = setInterval(async () => {
    try {
      const inbox = await getMeshInbox(params.myNodeId);
      params.onBridgeStatus?.(true);

      for (const msg of inbox) {
        if (seen.has(msg.id)) continue;
        seen.add(msg.id);

        // JSON control envelope detection
        if (msg.payload.startsWith("{")) {
          try {
            const parsed = JSON.parse(msg.payload) as Record<string, unknown>;

            if (parsed?.type === "CALL_INVITE") {
              params.onCallInvite?.(parsed, msg);
              continue;
            }
          } catch {
            // invalid JSON — fall through to text handling
          }
        }

        // Drop transport-level ACK frames (not chat content)
        if (msg.payload.startsWith("ACK:")) continue;

        params.onTextMessage(msg);
      }
    } catch (err) {
      params.onBridgeStatus?.(false);
      console.error("MauriMesh receive loop error:", err);
    }
  }, intervalMs);

  return () => clearInterval(timer);
}
