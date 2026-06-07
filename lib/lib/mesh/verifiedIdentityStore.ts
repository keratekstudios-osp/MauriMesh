/**
 * verifiedIdentityStore — durable nodeId → Ed25519 publicKey bindings that are
 * established ONLY from packets whose signature has already been verified.
 *
 * This is deliberately separate from `nearbyPeerRegistry`. The nearby-peer
 * registry is populated by unauthenticated BLE advertisements (friend-invite
 * beacons, and a manufacturer-data path that stores `fp:<fingerprint>` pseudo
 * keys), so it must NEVER be used as a trust authority — an attacker in BLE
 * range could advertise a victim's nodeId bound to an attacker key and poison
 * the binding before any signed packet is seen.
 *
 * Entries here are first-write-wins: once a nodeId has a verified key, later
 * writes with a different key are ignored so an attacker cannot clobber a
 * previously established identity.
 */

import AsyncStorage from "@react-native-async-storage/async-storage";

export interface VerifiedIdentity {
  nodeId: string;
  /** Base64-encoded full Ed25519 public key (never an `fp:` fingerprint). */
  publicKey: string;
  /** Timestamp the binding was first established. */
  boundAt: number;
}

const STORAGE_KEY = "@maurimesh/verifiedIdentities/v1";
const MAX_ENTRIES = 200;

const identityMap = new Map<string, VerifiedIdentity>();
let hydratePromise: Promise<void> | null = null;

/**
 * A full Ed25519 public key is 32 bytes → 44 base64 chars. Reject anything that
 * is empty or carries the `fp:` fingerprint prefix used by the legacy
 * manufacturer-data advertisement path.
 */
export function isFullEd25519Key(key: string | undefined): key is string {
  return (
    typeof key === "string" &&
    key.length >= 40 &&
    !key.startsWith("fp:")
  );
}

function hydrateIfNeeded(): Promise<void> {
  if (hydratePromise) return hydratePromise;
  hydratePromise = (async () => {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      if (!raw) return;
      const entries = JSON.parse(raw) as VerifiedIdentity[];
      for (const e of entries) {
        if (e.nodeId && isFullEd25519Key(e.publicKey) && !identityMap.has(e.nodeId)) {
          identityMap.set(e.nodeId, e);
        }
      }
    } catch {
      // non-fatal — continue with empty in-memory state
    }
  })();
  return hydratePromise;
}

async function persist(): Promise<void> {
  try {
    const all = [...identityMap.values()]
      .sort((a, b) => b.boundAt - a.boundAt)
      .slice(0, MAX_ENTRIES);
    await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(all));
  } catch {
    // non-fatal
  }
}

/** All verified bindings (loaded from storage after hydration). */
export async function loadVerifiedIdentities(): Promise<VerifiedIdentity[]> {
  await hydrateIfNeeded();
  return [...identityMap.values()];
}

/**
 * Record a verified nodeId → publicKey binding. First-write-wins: an existing
 * binding (same or different key) is never overwritten. The caller MUST only
 * invoke this for packets whose signature has already been verified.
 */
export async function recordVerifiedIdentity(
  nodeId: string,
  publicKey: string
): Promise<void> {
  if (!nodeId || !isFullEd25519Key(publicKey)) return;
  await hydrateIfNeeded();
  if (identityMap.has(nodeId)) return; // first-write-wins
  identityMap.set(nodeId, { nodeId, publicKey, boundAt: Date.now() });
  await persist();
}
