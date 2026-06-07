import { getOrCreateNodeId } from "../mesh/deviceIdentity";
import { getDiscoveredPeers } from "../mesh/nearbyPeerRegistry";
import type { FriendInvitePayload } from "./friendTypes";

/**
 * How long a peer entry is considered "live" after its last advertisement.
 * Peers older than this are excluded from results so the Nearby Devices list
 * only shows nodes that are physically present in the current session.
 *
 * The BLE stale-peer sweep in useBleTransport removes scanner-level peers after
 * 30 s, but nearbyPeerRegistry deliberately persists across restarts. Without
 * this TTL the Add Friend screen would surface nodes seen days ago.
 */
const NEARBY_PEER_TTL_MS = 5 * 60 * 1_000; // 5 minutes

/**
 * Search for nearby MauriMesh nodes that have broadcast a friend-invite beacon.
 *
 * Reads from nearbyPeerRegistry — the authoritative store for peers that carry
 * a publicKey. The BLE scanner populates this registry via addDiscoveredPeer()
 * whenever it resolves a peer's publicKey from a FRIEND_INVITE_SERVICE_UUID
 * advertisement (see useBleTransport → parseFriendBeacon).
 *
 * Filtering:
 *   - Drops peers not seen within the last NEARBY_PEER_TTL_MS (5 min).
 *   - Drops this device's own persistent mesh node entry (mm-* from AsyncStorage).
 *   - Drops peers missing nodeId or publicKey.
 *   - Deduplicates by nodeId (registry already guarantees this, but enforced here
 *     as a safety net).
 *   - Sorts strongest/most-recent first: descending lastSeenAt, then descending rssi.
 */
export async function searchNearbyFriendNodes(): Promise<FriendInvitePayload[]> {
  const [selfNodeId, peers] = await Promise.all([
    getOrCreateNodeId(),
    getDiscoveredPeers(),
  ]);

  const cutoff = Date.now() - NEARBY_PEER_TTL_MS;
  const seen = new Set<string>();
  const results: FriendInvitePayload[] = [];

  // Sort: most recently seen first, then strongest RSSI as tiebreaker.
  const sorted = [...peers].sort((a, b) => {
    const timeDiff = b.lastSeenAt - a.lastSeenAt;
    if (timeDiff !== 0) return timeDiff;
    return (b.rssi ?? -100) - (a.rssi ?? -100);
  });

  for (const peer of sorted) {
    if (!peer.nodeId || !peer.publicKey) continue;
    // Drop entries whose lastSeenAt is missing, zero, or non-finite — these are
    // legacy records that pre-date the timestamp field and cannot be age-checked.
    if (!Number.isFinite(peer.lastSeenAt) || peer.lastSeenAt <= 0) continue;
    if (peer.lastSeenAt < cutoff) continue;
    if (peer.nodeId === selfNodeId) continue;
    if (seen.has(peer.nodeId)) continue;
    seen.add(peer.nodeId);

    results.push({
      type: "MAURIMESH_FRIEND_INVITE",
      version: 1,
      userId: peer.nodeId,
      displayName: peer.displayName ?? peer.nodeId,
      nodeId: peer.nodeId,
      publicKey: peer.publicKey,
      createdAt: peer.lastSeenAt,
    });
  }

  return results;
}
