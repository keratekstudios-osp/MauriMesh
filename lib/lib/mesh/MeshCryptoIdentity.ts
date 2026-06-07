/**
 * Cryptographic node identity for MauriMesh.
 *
 * Uses Ed25519 (tweetnacl) for key generation and signing.
 * Keys are stored in AsyncStorage; the identity is created once on first launch
 * and reused for the lifetime of the installation.
 *
 * Signing covers only the "stable body" — fields that do not change during
 * multi-hop relay (routePath, reversePath, reversePathIndex, ttl, hopCount
 * are all mutable relay state and are intentionally excluded from the signature).
 */

import AsyncStorage from "@react-native-async-storage/async-storage";
import * as nacl from "tweetnacl";
import { encodeBase64, decodeBase64, decodeUTF8 } from "tweetnacl-util";
import type { MeshPacket } from "./maurimesh-intelligent-contract";

// ── Public API types ─────────────────────────────────────────────────────────

export interface NodeCryptoIdentity {
  /** Mesh node ID (matches the persistent device node ID from deviceIdentity.ts). */
  nodeId: string;
  /** Base64-encoded Ed25519 public key (32 bytes → 44 chars). */
  publicKey: string;
  /** Base64-encoded Ed25519 secret key (64 bytes → 88 chars). */
  privateKey: string;
  createdAt: number;
  identityVersion: 1;
}

// ── Storage ──────────────────────────────────────────────────────────────────

const STORAGE_KEY = "@maurimesh/crypto_identity/v1";
let _cached: NodeCryptoIdentity | null = null;

/**
 * Generate a fresh Ed25519 keypair bound to `nodeId`.
 * Does not persist — use `loadOrCreateCryptoIdentity` for persistence.
 */
export function generateCryptoIdentity(nodeId: string): NodeCryptoIdentity {
  const kp = nacl.sign.keyPair();
  return {
    nodeId,
    publicKey: encodeBase64(kp.publicKey),
    privateKey: encodeBase64(kp.secretKey),
    createdAt: Date.now(),
    identityVersion: 1,
  };
}

/**
 * Load the persisted crypto identity for `nodeId` from AsyncStorage.
 * Creates and stores a new one when:
 *   - no stored identity exists, OR
 *   - the stored identity belongs to a different nodeId (device reset).
 *
 * The result is cached in-process; subsequent calls with the same nodeId
 * return immediately without touching storage.
 */
export async function loadOrCreateCryptoIdentity(
  nodeId: string
): Promise<NodeCryptoIdentity> {
  if (_cached && _cached.nodeId === nodeId) return _cached;

  const stored = await AsyncStorage.getItem(STORAGE_KEY);
  if (stored) {
    const parsed = JSON.parse(stored) as NodeCryptoIdentity;
    if (parsed.nodeId === nodeId) {
      _cached = parsed;
      return _cached;
    }
  }

  const identity = generateCryptoIdentity(nodeId);
  await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(identity));
  _cached = identity;
  return identity;
}

/** Synchronous read of the in-process cache (null until the async load resolves). */
export function getCachedIdentity(): NodeCryptoIdentity | null {
  return _cached;
}

/** Reset the in-process cache. For testing only. */
export function resetCryptoIdentityCache(): void {
  _cached = null;
}

// ── Stable body (fields covered by the signature) ───────────────────────────

/**
 * Build the canonical JSON string that is signed.
 *
 * Only stable fields are included — those that do not change as the packet
 * travels through relay hops:
 *   ✔ packetId, type, fromNodeId, toNodeId, payload, createdAt, fromPublicKey
 *   ✗ routePath, reversePath, reversePathIndex, ttl, hopCount, maxHops, lane,
 *     priority, checksum (all mutable relay state)
 */
export function buildStableBody(packet: MeshPacket): string {
  return JSON.stringify({
    packetId: packet.packetId,
    type: packet.type,
    fromNodeId: packet.fromNodeId,
    toNodeId: packet.toNodeId,
    payload: packet.payload,
    createdAt: packet.createdAt,
    fromPublicKey: packet.fromPublicKey ?? "",
  });
}

// ── Signing ──────────────────────────────────────────────────────────────────

/**
 * Compute a base64 Ed25519 signature for `packet`'s stable body.
 * `privateKeyB64` is the base64 secret key from NodeCryptoIdentity.privateKey.
 *
 * Caller must set `packet.fromPublicKey` BEFORE signing (it is included in the
 * stable body to bind the key to the content).
 */
export function signPacketBody(
  packet: MeshPacket,
  privateKeyB64: string
): string {
  const body = buildStableBody(packet);
  const message = decodeUTF8(body);
  const secretKey = decodeBase64(privateKeyB64);
  const signature = nacl.sign.detached(message, secretKey);
  return encodeBase64(signature);
}

// ── Verification ─────────────────────────────────────────────────────────────

/**
 * Verify `packet.signature` against `packet.fromPublicKey` for the stable body.
 *
 * Returns false when:
 *   - fromPublicKey or signature is missing
 *   - base64 decode fails (malformed key or signature)
 *   - Ed25519 detached-verify returns false (content was tampered)
 */
export function verifyPacketSignature(packet: MeshPacket): boolean {
  if (!packet.fromPublicKey || !packet.signature) return false;
  try {
    const body = buildStableBody(packet);
    const message = decodeUTF8(body);
    const publicKey = decodeBase64(packet.fromPublicKey);
    const signature = decodeBase64(packet.signature);
    return nacl.sign.detached.verify(message, signature, publicKey);
  } catch {
    return false;
  }
}

// ── Replay protection ────────────────────────────────────────────────────────

/**
 * Tracks (fromNodeId, packetId) pairs to detect replayed packets.
 *
 * Only signed packets are subject to replay protection — unsigned
 * infrastructure packets (ROUTE_BEACON) bypass this check entirely.
 *
 * Uses lazy eviction: stale entries are purged when the cache exceeds
 * MAX_SIZE or explicitly via evictExpired().
 */
export class ReplayCache {
  private readonly cache = new Map<string, number>(); // key → expiresAt (ms)
  private readonly ttlMs: number;
  private static readonly MAX_SIZE = 2_000;

  constructor(ttlMs = 10 * 60 * 1_000) {
    this.ttlMs = ttlMs;
  }

  /** Returns true when this (fromNodeId, packetId) pair has been seen recently. */
  hasSeen(fromNodeId: string, packetId: string): boolean {
    const expiry = this.cache.get(`${fromNodeId}:${packetId}`);
    return expiry !== undefined && expiry > Date.now();
  }

  /**
   * Record that this (fromNodeId, packetId) has been seen.
   * Triggers lazy eviction when cache exceeds MAX_SIZE.
   */
  markSeen(fromNodeId: string, packetId: string): void {
    this.cache.set(`${fromNodeId}:${packetId}`, Date.now() + this.ttlMs);
    if (this.cache.size > ReplayCache.MAX_SIZE) {
      this.evictExpired();
    }
  }

  /** Explicit eviction of all expired entries. */
  evictExpired(): void {
    const now = Date.now();
    for (const [key, expiry] of this.cache) {
      if (expiry <= now) this.cache.delete(key);
    }
  }

  /** Number of tracked entries (including expired but not yet evicted). */
  size(): number {
    return this.cache.size;
  }
}
