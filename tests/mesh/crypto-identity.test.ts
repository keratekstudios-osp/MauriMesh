// Ported from lib/lib/mesh/__tests__/crypto-identity.test.ts (Jest) into the root
// Vitest QA suite so the crypto identity layer is covered by `pnpm qa:run` and the
// dashboard. The real tweetnacl primitives are exercised (aliased in vitest.config.ts);
// only AsyncStorage is mocked. Source module is imported as-is — no production change.
//
// TRUTH BOUNDARY: Ed25519 signatures prove packet authenticity/integrity. They are
// NOT transport encryption and these tests do NOT prove any live BLE behaviour.

import { describe, test, expect, beforeEach, vi } from "vitest";

// ── AsyncStorage mock (default export) ───────────────────────────────────────

const mockStorage: Record<string, string> = {};

vi.mock("@react-native-async-storage/async-storage", () => ({
  default: {
    getItem: vi.fn(async (key: string) => mockStorage[key] ?? null),
    setItem: vi.fn(async (key: string, value: string) => {
      mockStorage[key] = value;
    }),
  },
}));

import {
  generateCryptoIdentity,
  loadOrCreateCryptoIdentity,
  resetCryptoIdentityCache,
  buildStableBody,
  signPacketBody,
  verifyPacketSignature,
  ReplayCache,
  KeyBindingStore,
} from "../../lib/lib/mesh/MeshCryptoIdentity";
import type { NodeCryptoIdentity } from "../../lib/lib/mesh/MeshCryptoIdentity";
import type { MeshPacket } from "../../lib/lib/mesh/maurimesh-intelligent-contract";

beforeEach(() => {
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
  } as MeshPacket;
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

  test("same nodeId still yields a fresh, distinct keypair each call", () => {
    const first = generateCryptoIdentity("node-SAME");
    const second = generateCryptoIdentity("node-SAME");
    expect(second.nodeId).toBe(first.nodeId);
    expect(second.publicKey).not.toBe(first.publicKey);
  });
});

// ── 2 & 3. Persistent identity ───────────────────────────────────────────────

describe("loadOrCreateCryptoIdentity", () => {
  test("creates and persists identity on first call", async () => {
    const id = await loadOrCreateCryptoIdentity("node-A");
    expect(id.nodeId).toBe("node-A");
    expect(id.publicKey.length).toBeGreaterThan(0);
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

// ── 5. Signature verification ────────────────────────────────────────────────

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

  test("malformed base64 public key / signature fails verification (no throw)", () => {
    const id = generateCryptoIdentity("node-A");
    const badKey = signedPacket(id);
    badKey.fromPublicKey = "!!!not-base64!!!";
    expect(verifyPacketSignature(badKey)).toBe(false);

    const badSig = signedPacket(id);
    badSig.signature = "@@@also-not-base64@@@";
    expect(verifyPacketSignature(badSig)).toBe(false);
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

  test("re-signing a tampered packet with the matching key makes it verify again", () => {
    // Anti-tautology guard: prove verification tracks the body, not a constant.
    // A tampered packet fails, but re-signing the new body with the same key
    // (whose public key travels with the packet) must verify — signature alone
    // binds key↔body, while nodeId↔key binding is KeyBindingStore's responsibility.
    const id = generateCryptoIdentity("node-A");
    const pkt = signedPacket(id);
    pkt.payload = "rewritten by the holder of the private key";
    expect(verifyPacketSignature(pkt)).toBe(false);
    pkt.signature = signPacketBody(pkt, id.privateKey);
    expect(verifyPacketSignature(pkt)).toBe(true);
  });
});

// ── 10-11. Stable body excludes mutable relay fields ─────────────────────────

describe("buildStableBody", () => {
  test("same packet produces identical stable body regardless of relay mutations", () => {
    const id = generateCryptoIdentity("node-A");
    const original = signedPacket(id);

    const relayed = { ...original };
    relayed.routePath = ["node-A", "node-B", "node-C"];
    relayed.ttl = 5;
    relayed.hopCount = 2;
    relayed.reversePathIndex = 1;

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

  test("stable body DOES include the immutable identity/content fields", () => {
    const body = JSON.parse(buildStableBody(makePacket())) as Record<string, unknown>;
    expect(body).toHaveProperty("packetId");
    expect(body).toHaveProperty("fromNodeId");
    expect(body).toHaveProperty("toNodeId");
    expect(body).toHaveProperty("payload");
  });

  test("changing payload changes the stable body; changing ttl does not", () => {
    const base = makePacket();
    const sameTtlMoved = makePacket({ ttl: 1, hopCount: 9 });
    const differentPayload = makePacket({ payload: "different" });
    expect(buildStableBody(sameTtlMoved)).toBe(buildStableBody(base));
    expect(buildStableBody(differentPayload)).not.toBe(buildStableBody(base));
  });

  test("fragmentation safety: signature survives reassembly (same packet = same body)", () => {
    const id = generateCryptoIdentity("node-A");
    const original = signedPacket(id);
    const reassembled = JSON.parse(JSON.stringify(original)) as MeshPacket;
    expect(verifyPacketSignature(reassembled)).toBe(true);
  });
});

// ── 12-14. ReplayCache (real timers; TTL impl is Date.now()-based) ───────────

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

  test("expired entry is not considered a replay", async () => {
    const cache = new ReplayCache(1); // 1 ms TTL
    cache.markSeen("node-A", "pkt-001");
    await new Promise((r) => setTimeout(r, 10));
    expect(cache.hasSeen("node-A", "pkt-001")).toBe(false);
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

  test("evictExpired removes stale entries", async () => {
    const cache = new ReplayCache(1); // 1 ms TTL
    cache.markSeen("node-A", "pkt-001");
    await new Promise((r) => setTimeout(r, 10));
    cache.evictExpired();
    expect(cache.size()).toBe(0);
  });

  test("a non-expired entry survives evictExpired", () => {
    const cache = new ReplayCache(10 * 60 * 1_000); // long TTL
    cache.markSeen("node-A", "pkt-001");
    cache.evictExpired();
    expect(cache.size()).toBe(1);
    expect(cache.hasSeen("node-A", "pkt-001")).toBe(true);
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
    expect(store.get("mm-node-A")).toBe("keyA");
  });

  test("seed establishes a binding without overwriting a learned one", () => {
    const store = new KeyBindingStore();
    store.reconcile("mm-node-A", "keyLEARNED");
    store.seed("mm-node-A", "keySEED");
    expect(store.get("mm-node-A")).toBe("keyLEARNED");
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

  test("fingerprint pseudo-keys never bind (advertisement poisoning guard)", () => {
    const store = new KeyBindingStore();
    store.seed("mm-node-A", "fp:AAAAAAAAAAA=");
    expect(store.get("mm-node-A")).toBeUndefined();
    expect(store.reconcile("mm-node-A", "fp:AAAAAAAAAAA=")).toBe("conflict");
    expect(store.size()).toBe(0);
    expect(store.reconcile("mm-node-A", "realFullKey")).toBe("first-seen");
  });
});
