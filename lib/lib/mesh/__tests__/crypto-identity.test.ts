/**
 * Unit tests for MeshCryptoIdentity.
 *
 * Run with: pnpm --filter @workspace/messenger-mobile test
 *
 * Tests:
 *  1. generateCryptoIdentity produces unique identities with correct fields
 *  2. loadOrCreateCryptoIdentity creates and persists on first call
 *  3. loadOrCreateCryptoIdentity returns cached identity on subsequent calls
 *  4. loadOrCreateCryptoIdentity regenerates when stored identity has different nodeId
 *  5. Valid signed packet verifies successfully
 *  6. Tampered payload fails signature verification
 *  7. Tampered fromNodeId fails signature verification
 *  8. Missing fromPublicKey returns false
 *  9. Missing signature returns false
 * 10. buildStableBody excludes mutable relay fields (routePath, ttl, hopCount, etc.)
 * 11. Fragmentation safety: stable body is computed AFTER reassembly (same packet = same body)
 * 12. ReplayCache: first occurrence passes, duplicate is caught
 * 13. ReplayCache: expired entry passes again
 * 14. ReplayCache: different nodeId with same packetId is NOT considered a replay
 */

import {
  generateCryptoIdentity,
  loadOrCreateCryptoIdentity,
  resetCryptoIdentityCache,
  buildStableBody,
  signPacketBody,
  verifyPacketSignature,
  ReplayCache,
  KeyBindingStore,
} from "../MeshCryptoIdentity";
import type { NodeCryptoIdentity } from "../MeshCryptoIdentity";
import type { MeshPacket } from "../maurimesh-intelligent-contract";

// ── AsyncStorage mock ────────────────────────────────────────────────────────

const mockStorage: Record<string, string> = {};

jest.mock("@react-native-async-storage/async-storage", () => ({
  getItem: jest.fn(async (key: string) => mockStorage[key] ?? null),
  setItem: jest.fn(async (key: string, value: string) => {
    mockStorage[key] = value;
  }),
}));

beforeEach(() => {
  // Clear in-memory cache and fake storage before every test.
  resetCryptoIdentityCache();
  for (const key of Object.keys(mockStorage)) {
    delete mockStorage[key];
  }
});

// ── Helpers ──────────────────────────────────────────────────────────────────

function makePacket(overrides: Partial<MeshPacket> = {}): MeshPacket {
  return {
    packetId: "pkt-001",
    type: "CHAT_MESSAGE",
    fromNodeId: "mm-node-A",
    toNodeId: "mm-node-B",
    routePath: ["mm-node-A"],
    lane: "BLE",
    ttl: 7,
    createdAt: 1_700_000_000_000,
    priority: 5,
    payload: "hello mesh",
    checksum: "",
    ...overrides,
  };
}

function signedPacket(identity: NodeCryptoIdentity, overrides: Partial<MeshPacket> = {}): MeshPacket {
  const pkt = makePacket({ fromNodeId: identity.nodeId, fromPublicKey: identity.publicKey, ...overrides });
  pkt.signature = signPacketBody(pkt, identity.privateKey);
  return pkt;
}

// ── 1. Identity generation ───────────────────────────────────────────────────

describe("generateCryptoIdentity", () => {
  test("produces an identity with all required fields", () => {
    const id = generateCryptoIdentity("node-X");
    expect(id.nodeId).toBe("node-X");
    expect(typeof id.publicKey).toBe("string");
    expect(typeof id.privateKey).toBe("string");
    expect(id.publicKey.length).toBeGreaterThan(0);
    expect(id.privateKey.length).toBeGreaterThan(0);
    expect(typeof id.createdAt).toBe("number");
    expect(id.identityVersion).toBe(1);
  });

  test("generates unique keypairs on each call", () => {
    const a = generateCryptoIdentity("node-A");
    const b = generateCryptoIdentity("node-B");
    expect(a.publicKey).not.toBe(b.publicKey);
    expect(a.privateKey).not.toBe(b.privateKey);
  });
});

// ── 2 & 3. Persistent identity ───────────────────────────────────────────────

describe("loadOrCreateCryptoIdentity", () => {
  test("creates and persists identity on first call", async () => {
    const id = await loadOrCreateCryptoIdentity("node-A");
    expect(id.nodeId).toBe("node-A");
    expect(id.publicKey.length).toBeGreaterThan(0);
    // Storage must have been written.
    expect(mockStorage["@maurimesh/crypto_identity/v1"]).toBeTruthy();
    const stored = JSON.parse(mockStorage["@maurimesh/crypto_identity/v1"]) as NodeCryptoIdentity;
    expect(stored.nodeId).toBe("node-A");
    expect(stored.publicKey).toBe(id.publicKey);
  });

  test("returns identical identity on second call (in-process cache)", async () => {
    const first = await loadOrCreateCryptoIdentity("node-A");
    const second = await loadOrCreateCryptoIdentity("node-A");
    expect(second.publicKey).toBe(first.publicKey);
    expect(second.privateKey).toBe(first.privateKey);
  });

  test("returns same identity after simulated restart (reads from storage)", async () => {
    const first = await loadOrCreateCryptoIdentity("node-A");
    // Simulate restart: clear in-process cache but keep storage.
    resetCryptoIdentityCache();
    const second = await loadOrCreateCryptoIdentity("node-A");
    expect(second.publicKey).toBe(first.publicKey);
    expect(second.privateKey).toBe(first.privateKey);
  });

  test("regenerates when stored identity has a different nodeId (device reset)", async () => {
    const first = await loadOrCreateCryptoIdentity("node-OLD");
    resetCryptoIdentityCache();
    const second = await loadOrCreateCryptoIdentity("node-NEW");
    expect(second.nodeId).toBe("node-NEW");
    expect(second.publicKey).not.toBe(first.publicKey);
  });
});

// ── 5. Valid signature verification ─────────────────────────────────────────

describe("verifyPacketSignature", () => {
  test("valid signed packet verifies successfully", () => {
    const id = generateCryptoIdentity("node-A");
    const pkt = signedPacket(id);
    expect(verifyPacketSignature(pkt)).toBe(true);
  });

  test("tampered payload fails verification", () => {
    const id = generateCryptoIdentity("node-A");
    const pkt = signedPacket(id);
    pkt.payload = "TAMPERED PAYLOAD";
    expect(verifyPacketSignature(pkt)).toBe(false);
  });

  test("tampered fromNodeId fails verification", () => {
    const id = generateCryptoIdentity("node-A");
    const pkt = signedPacket(id);
    pkt.fromNodeId = "node-EVIL";
    expect(verifyPacketSignature(pkt)).toBe(false);
  });

  test("tampered toNodeId fails verification", () => {
    const id = generateCryptoIdentity("node-A");
    const pkt = signedPacket(id);
    pkt.toNodeId = "node-EVIL";
    expect(verifyPacketSignature(pkt)).toBe(false);
  });

  test("missing fromPublicKey returns false", () => {
    const id = generateCryptoIdentity("node-A");
    const pkt = signedPacket(id);
    delete pkt.fromPublicKey;
    expect(verifyPacketSignature(pkt)).toBe(false);
  });

  test("missing signature returns false", () => {
    const id = generateCryptoIdentity("node-A");
    const pkt = makePacket({ fromNodeId: id.nodeId, fromPublicKey: id.publicKey });
    expect(verifyPacketSignature(pkt)).toBe(false);
  });

  test("wrong public key fails verification", () => {
    const idA = generateCryptoIdentity("node-A");
    const idB = generateCryptoIdentity("node-B");
    const pkt = makePacket({
      fromNodeId: idA.nodeId,
      fromPublicKey: idB.publicKey, // wrong key
    });
    pkt.signature = signPacketBody(pkt, idA.privateKey);
    expect(verifyPacketSignature(pkt)).toBe(false);
  });
});

// ── 10. Stable body excludes mutable relay fields ───────────────────────────

describe("buildStableBody", () => {
  test("same packet produces identical stable body regardless of relay mutations", () => {
    const id = generateCryptoIdentity("node-A");
    const original = signedPacket(id);

    // Simulate relay mutations (these happen at each hop).
    const relayed = { ...original };
    relayed.routePath = ["node-A", "node-B", "node-C"]; // path grew
    relayed.ttl = 5;                                      // ttl decremented
    relayed.hopCount = 2;                                 // hopCount incremented
    relayed.reversePathIndex = 1;                         // index moved

    // Stable body must be identical — signature must still verify.
    expect(buildStableBody(relayed)).toBe(buildStableBody(original));
    expect(verifyPacketSignature(relayed)).toBe(true);
  });

  test("stable body does NOT include routePath, ttl, hopCount, reversePathIndex", () => {
    const pkt = makePacket();
    const body = JSON.parse(buildStableBody(pkt)) as Record<string, unknown>;
    expect(body).not.toHaveProperty("routePath");
    expect(body).not.toHaveProperty("ttl");
    expect(body).not.toHaveProperty("hopCount");
    expect(body).not.toHaveProperty("maxHops");
    expect(body).not.toHaveProperty("reversePathIndex");
    expect(body).not.toHaveProperty("reversePath");
    expect(body).not.toHaveProperty("lane");
    expect(body).not.toHaveProperty("priority");
  });

  test("fragmentation safety: signature survives reassembly (same packet = same body)", () => {
    const id = generateCryptoIdentity("node-A");
    // Simulate: original packet is signed, then serialized/fragmented/reassembled.
    const original = signedPacket(id);
    const reassembled = JSON.parse(JSON.stringify(original)) as MeshPacket;
    expect(verifyPacketSignature(reassembled)).toBe(true);
  });
});

// ── 12-14. ReplayCache ───────────────────────────────────────────────────────

describe("ReplayCache", () => {
  test("first occurrence is not a replay", () => {
    const cache = new ReplayCache();
    expect(cache.hasSeen("node-A", "pkt-001")).toBe(false);
  });

  test("marks and detects duplicate packetId from same node", () => {
    const cache = new ReplayCache();
    cache.markSeen("node-A", "pkt-001");
    expect(cache.hasSeen("node-A", "pkt-001")).toBe(true);
  });

  test("expired entry is not considered a replay", () => {
    const cache = new ReplayCache(1); // 1 ms TTL
    cache.markSeen("node-A", "pkt-001");
    // Wait for expiry.
    jest.useFakeTimers();
    jest.advanceTimersByTime(10);
    expect(cache.hasSeen("node-A", "pkt-001")).toBe(false);
    jest.useRealTimers();
  });

  test("different nodeId with same packetId is NOT a replay", () => {
    const cache = new ReplayCache();
    cache.markSeen("node-A", "pkt-001");
    expect(cache.hasSeen("node-B", "pkt-001")).toBe(false);
  });

  test("same nodeId with different packetId is NOT a replay", () => {
    const cache = new ReplayCache();
    cache.markSeen("node-A", "pkt-001");
    expect(cache.hasSeen("node-A", "pkt-002")).toBe(false);
  });

  test("evictExpired removes stale entries", () => {
    const cache = new ReplayCache(1); // 1 ms TTL
    cache.markSeen("node-A", "pkt-001");
    jest.useFakeTimers();
    jest.advanceTimersByTime(10);
    cache.evictExpired();
    expect(cache.size()).toBe(0);
    jest.useRealTimers();
  });
});

// ── KeyBindingStore (nodeId → publicKey TOFU) ────────────────────────────────

describe("KeyBindingStore", () => {
  test("first packet for a node binds its key (first-seen)", () => {
    const store = new KeyBindingStore();
    expect(store.reconcile("mm-node-A", "keyA")).toBe("first-seen");
    expect(store.get("mm-node-A")).toBe("keyA");
  });

  test("same key for a known node matches", () => {
    const store = new KeyBindingStore();
    store.reconcile("mm-node-A", "keyA");
    expect(store.reconcile("mm-node-A", "keyA")).toBe("match");
  });

  test("different key for a known node conflicts (impersonation)", () => {
    const store = new KeyBindingStore();
    store.reconcile("mm-node-A", "keyA");
    expect(store.reconcile("mm-node-A", "keyEVIL")).toBe("conflict");
    // The original binding is preserved — the attacker cannot overwrite it.
    expect(store.get("mm-node-A")).toBe("keyA");
  });

  test("seed establishes a binding without overwriting a learned one", () => {
    const store = new KeyBindingStore();
    store.reconcile("mm-node-A", "keyLEARNED");
    store.seed("mm-node-A", "keySEED"); // must not clobber the learned key
    expect(store.get("mm-node-A")).toBe("keyLEARNED");
    // A seeded key for an unknown node then conflicts with a different key.
    store.seed("mm-node-B", "keyB");
    expect(store.reconcile("mm-node-B", "keyOTHER")).toBe("conflict");
  });

  test("distinct nodes hold independent bindings", () => {
    const store = new KeyBindingStore();
    expect(store.reconcile("mm-node-A", "keyA")).toBe("first-seen");
    expect(store.reconcile("mm-node-B", "keyB")).toBe("first-seen");
    expect(store.reconcile("mm-node-A", "keyA")).toBe("match");
    expect(store.size()).toBe(2);
  });

  test("empty nodeId or key is treated as a conflict (never bound)", () => {
    const store = new KeyBindingStore();
    expect(store.reconcile("", "keyA")).toBe("conflict");
    expect(store.reconcile("mm-node-A", "")).toBe("conflict");
    expect(store.size()).toBe(0);
  });

  test("fp: fingerprint pseudo-keys never bind (advertisement poisoning guard)", () => {
    const store = new KeyBindingStore();
    // A fingerprint from the legacy manufacturer-data advertisement path.
    store.seed("mm-node-A", "fp:AAAAAAAAAAA=");
    expect(store.get("mm-node-A")).toBeUndefined();
    expect(store.reconcile("mm-node-A", "fp:AAAAAAAAAAA=")).toBe("conflict");
    expect(store.size()).toBe(0);
    // A subsequent real verified key still binds cleanly.
    expect(store.reconcile("mm-node-A", "realFullKey")).toBe("first-seen");
  });
});
