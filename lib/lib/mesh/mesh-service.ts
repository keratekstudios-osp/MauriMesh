// Mesh Service — central relay engine
//
// This module owns the singleton IntelligentMeshRouter and StoreForwardQueue.
// Both useMeshTransport and any future service entry-points use the SAME
// exported `router` instance so route-scoring state (RSSI, success/failure
// counters, node registry) is shared across the entire session.
//
// handleIncomingPacket() is the designated relay orchestration entry-point.
// For transit packets it:
//   1. Uses selectBestRoute(toNodeId, "BLE", packet.routePath) to obtain the
//      highest-scored next-hop while explicitly excluding every node ID that
//      is already in the packet's routePath (loop prevention).
//   2. Calls prepareRelayPacket(packet, myNodeId) — appending THIS node to
//      routePath and decrementing TTL — so the relay origin is recorded
//      correctly (not the next-hop's ID).
//   3. Calls markDelivered AFTER forwarding, so a duplicate arrival on
//      another path is correctly dropped without blocking the first relay.

import {
  IntelligentMeshRouter,
  StoreForwardQueue,
  packetPriority,
  type MeshPacket,
  type MeshNode,
} from "./maurimesh-intelligent-contract";

// ── Singleton router & queue ─────────────────────────────────────────────────
// Exported so useMeshTransport (and any future consumer) can share state.

export const router = new IntelligentMeshRouter();
const queue = new StoreForwardQueue();

// Stable device ID for this session (used when callers don't supply myNodeId)
const DEVICE_ID =
  "device-" + Date.now().toString(36) + Math.random().toString(36).slice(2, 7);

export { DEVICE_ID };

export function registerNode(node: MeshNode): void {
  router.registerNode(node);
}

export function getKnownNodes(): MeshNode[] {
  return router.allNodes();
}

function newPacketId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 9);
}

export function createMessagePacket(
  toNodeId: string,
  message: string,
  fromNodeId: string = DEVICE_ID
): MeshPacket {
  return {
    packetId: newPacketId(),
    type: "CHAT_MESSAGE",
    fromNodeId,
    toNodeId,
    routePath: [fromNodeId],
    lane: "BLE",
    ttl: 6,
    createdAt: Date.now(),
    priority: packetPriority("CHAT_MESSAGE", toNodeId),
    payload: message,
    checksum: "",
  };
}

/**
 * Incoming packet handler — call this whenever raw BLE data arrives.
 *
 * @param packet   - The decoded MeshPacket.
 * @param sendFn   - Async fn invoked with the relay packet; returns true on
 *                   success. For transit packets, markDelivered is only called
 *                   on success; failures enqueue the packet for retry.
 * @param myNodeId - This device's node ID (defaults to module-level DEVICE_ID).
 *
 * Relay algorithm for transit packets (toNodeId ≠ myNodeId, ≠ BROADCAST):
 *   1. selectBestRoute with routePath exclusion picks the highest-scored
 *      next-hop that is NOT already in the route chain.
 *   2. prepareRelayPacket(packet, myNodeId) decrements TTL and records THIS
 *      node (not the next-hop) as the relay origin in routePath.
 *   3. sendFn is awaited; markDelivered only on success. Failure → enqueue.
 */
export async function handleIncomingPacket(
  packet: MeshPacket,
  sendFn: (p: MeshPacket) => Promise<boolean>,
  myNodeId: string = DEVICE_ID
): Promise<void> {
  if (!router.shouldAcceptPacket(packet)) return;

  // ── Packet addressed to this node ─────────────────────────────────────────
  if (packet.toNodeId === myNodeId || packet.toNodeId === "BROADCAST") {
    router.markDelivered(packet.packetId);

    if (packet.type === "CHAT_MESSAGE") {
      messageListeners.forEach((cb) => cb(packet));

      const ack: MeshPacket = {
        packetId: newPacketId(),
        type: "ACK",
        fromNodeId: myNodeId,
        toNodeId: packet.fromNodeId,
        routePath: [myNodeId],
        lane: packet.lane,
        ttl: 4,
        createdAt: Date.now(),
        priority: packetPriority("ACK"),
        payload: packet.packetId,
        checksum: "",
      };
      await sendFn(ack);
    }

    return;
  }

  // ── Transit relay ─────────────────────────────────────────────────────────
  // Use route-score algorithm with routePath exclusion to pick the best next-hop.
  const route = router.selectBestRoute(packet.toNodeId, "BLE", packet.routePath);
  if (!route) {
    queue.enqueue(packet);
    return;
  }

  const relay = router.prepareRelayPacket(packet, myNodeId);
  if (relay) {
    const sent = await sendFn(relay);
    if (sent) {
      // Mark delivered only on confirmed forward — prevents silent packet loss
      router.markDelivered(packet.packetId);
      router.recordRouteSuccess(route.nodeId);
    } else {
      // Forward failed: enqueue for retry when a route becomes available
      router.recordRouteFailure(route.nodeId);
      queue.enqueue(packet);
    }
  }
}

/** Send a chat message to toNodeId through the mesh. */
export function sendMessage(
  toNodeId: string,
  message: string,
  sendFn: (p: MeshPacket) => void,
  fromNodeId: string = DEVICE_ID
): MeshPacket {
  const packet = createMessagePacket(toNodeId, message, fromNodeId);
  const route = router.selectBestRoute(toNodeId, "BLE", [fromNodeId]);

  if (!route) {
    queue.enqueue(packet);
  } else {
    sendFn(packet);
  }

  return packet;
}

/** Retry all queued packets — call periodically (e.g. every 3 s). */
export function flushQueue(sendFn: (p: MeshPacket) => void): void {
  for (const packet of [...queue.queue]) {
    const route = router.selectBestRoute(packet.toNodeId, "BLE", packet.routePath);
    if (route) {
      sendFn(packet);
      queue.remove(packet.packetId);
    }
  }
}

// ─── In-app message listener registry ────────────────────────────────────────

type MessageListener = (packet: MeshPacket) => void;
const messageListeners = new Set<MessageListener>();

/** Register a callback to be called when a CHAT_MESSAGE arrives for this device. */
export function onMessageReceived(cb: MessageListener): () => void {
  messageListeners.add(cb);
  return () => messageListeners.delete(cb);
}
