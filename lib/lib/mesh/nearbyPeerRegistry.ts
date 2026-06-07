/**
 * nearbyPeerRegistry — in-memory + AsyncStorage store for discovered mesh peers
 * that carry a publicKey (required for friend-invite flows).
 *
 * This is the authoritative source for `searchNearbyFriendNodes()`.
 * The BLE scanner should call `addDiscoveredPeer()` whenever it resolves a
 * peer's publicKey from a friend-invite beacon advertisement.
 *
 * Out of scope for this module: eviction, TTL, BLE wiring (next task).
 */

import AsyncStorage from "@react-native-async-storage/async-storage";

export interface NearbyPeer {
  nodeId: string;
  publicKey: string;
  displayName?: string;
  rssi?: number;
  lastSeenAt: number;
}

const STORAGE_KEY = "@maurimesh/nearbyPeers";
const MAX_PEERS = 100;

// In-memory map — keyed by nodeId for O(1) upsert/dedup.
const peerMap = new Map<string, NearbyPeer>();

// Single-flight hydration promise — all concurrent callers await the same load.
let hydratePromise: Promise<void> | null = null;

function hydrateIfNeeded(): Promise<void> {
  if (hydratePromise) return hydratePromise;
  hydratePromise = (async () => {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      if (!raw) return;
      const peers = JSON.parse(raw) as NearbyPeer[];
      for (const p of peers) {
        if (p.nodeId && p.publicKey) {
          peerMap.set(p.nodeId, p);
        }
      }
    } catch {
      // non-fatal — continue with empty in-memory state
    }
  })();
  return hydratePromise;
}

function pruneMemory(): void {
  if (peerMap.size <= MAX_PEERS) return;
  // Evict oldest entries to stay within MAX_PEERS
  const sorted = [...peerMap.values()].sort(
    (a, b) => b.lastSeenAt - a.lastSeenAt
  );
  peerMap.clear();
  for (const p of sorted.slice(0, MAX_PEERS)) {
    peerMap.set(p.nodeId, p);
  }
}

async function persist(): Promise<void> {
  try {
    const all = [...peerMap.values()]
      .sort((a, b) => b.lastSeenAt - a.lastSeenAt)
      .slice(0, MAX_PEERS);
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(all));
  } catch {
    // non-fatal
  }
}

/**
 * Upsert a discovered peer. Newer entries overwrite older ones for the same
 * nodeId. Persists to AsyncStorage asynchronously.
 */
export async function addDiscoveredPeer(peer: NearbyPeer): Promise<void> {
  await hydrateIfNeeded();
  const existing = peerMap.get(peer.nodeId);
  peerMap.set(peer.nodeId, {
    ...existing,
    ...peer,
    rssi: peer.rssi ?? existing?.rssi,
  });
  pruneMemory();
  await persist();
}

/**
 * Return all currently known nearby peers (loaded from memory after hydration).
 */
export async function getDiscoveredPeers(): Promise<NearbyPeer[]> {
  await hydrateIfNeeded();
  return [...peerMap.values()];
}
