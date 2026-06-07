import { mauriMeshBridge } from "../maurimesh-client";

export interface InboxMessage {
  id: string;
  senderId: string;
  payload: string;
  timestamp: number;
}

export interface InboxListenerOptions {
  intervalMs?: number;
  onBridgeStatus?: (online: boolean) => void;
}

/**
 * Polls the MauriMesh HTTP bridge every `intervalMs` ms (default 1 s) for
 * messages addressed to `myNodeId`. Deduplicates by message ID. Skips
 * echo messages from myNodeId itself. Calls `onBridgeStatus` on every poll
 * so the caller can reflect connectivity in the UI.
 *
 * Returns a cleanup function — call it from useEffect's return to stop polling.
 *
 * Usage:
 *   const stop = startMeshInboxListener(myNodeId, (msg) => {
 *     console.log("NEW MESSAGE", msg);
 *   }, { onBridgeStatus: (online) => setStatus(online) });
 *   // later:
 *   stop();
 */
export function startMeshInboxListener(
  myNodeId: string,
  onMessage: (msg: InboxMessage) => void,
  options: InboxListenerOptions = {},
): () => void {
  const { intervalMs = 1000, onBridgeStatus } = options;
  const seen = new Set<string>();
  let active = true;

  async function poll() {
    if (!active) return;
    try {
      const nodes = await mauriMeshBridge.nodes();
      if (!active) return;
      onBridgeStatus?.(true);

      const myNode = nodes.find((n) => n.nodeId === myNodeId);
      if (!myNode) return;

      for (const msg of myNode.receivedMessages) {
        if (!active) return;
        if (msg.senderId === myNodeId) continue;
        if (seen.has(msg.id)) continue;
        seen.add(msg.id);
        onMessage({
          id: msg.id,
          senderId: msg.senderId,
          payload: msg.payload,
          timestamp: msg.timestamp,
        });
      }
    } catch {
      if (active) onBridgeStatus?.(false);
    }
  }

  poll();
  const timerId = setInterval(poll, intervalMs);

  return () => {
    active = false;
    clearInterval(timerId);
  };
}
