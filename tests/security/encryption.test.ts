import { describe, it, expect, beforeEach } from "vitest";
import { createHmac, randomBytes, createCipheriv, createDecipheriv } from "crypto";

// ── Key management utilities ──────────────────────────────────────────────────

interface KeyPair {
  publicKey: string;  // hex-encoded 32-byte public key (simulated)
  privateKey: string; // hex-encoded 32-byte private key
  id: string;         // key fingerprint (first 8 hex chars of public key)
  createdAt: number;
}

interface EncryptedEnvelope {
  keyId: string;
  iv: string;       // hex
  ciphertext: string; // hex
  tag: string;      // HMAC-SHA256 hex
}

function generateKeyPair(nowMs = Date.now()): KeyPair {
  const priv = randomBytes(32).toString("hex");
  const pub  = randomBytes(32).toString("hex");
  return { privateKey: priv, publicKey: pub, id: pub.slice(0, 8), createdAt: nowMs };
}

function keyFingerprint(keyPair: KeyPair): string {
  return keyPair.publicKey.slice(0, 8);
}

function isKeyExpired(keyPair: KeyPair, maxAgeMs: number, nowMs = Date.now()): boolean {
  return nowMs - keyPair.createdAt > maxAgeMs;
}

function rotateKey(current: KeyPair, nowMs = Date.now()): KeyPair {
  return generateKeyPair(nowMs);
}

function encryptEnvelope(plaintext: string, keyHex: string, nowMs = Date.now()): EncryptedEnvelope {
  const keyBuf = Buffer.from(keyHex.slice(0, 32).padEnd(32, "0"), "utf8");
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-cbc", Buffer.concat([keyBuf], 32), Buffer.alloc(16));
  const enc = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
  const tag = createHmac("sha256", keyBuf).update(enc).digest("hex");
  return {
    keyId: keyHex.slice(0, 8),
    iv: iv.toString("hex"),
    ciphertext: enc.toString("hex"),
    tag,
  };
}

function verifyTag(envelope: EncryptedEnvelope, keyHex: string): boolean {
  const keyBuf = Buffer.from(keyHex.slice(0, 32).padEnd(32, "0"), "utf8");
  const cipherBuf = Buffer.from(envelope.ciphertext, "hex");
  const expected = createHmac("sha256", keyBuf).update(cipherBuf).digest("hex");
  return expected === envelope.tag;
}

function decryptEnvelope(envelope: EncryptedEnvelope, keyHex: string): string {
  if (!verifyTag(envelope, keyHex)) throw new Error("Tag mismatch — message tampered");
  const keyBuf = Buffer.from(keyHex.slice(0, 32).padEnd(32, "0"), "utf8");
  const cipherBuf = Buffer.from(envelope.ciphertext, "hex");
  const decipher = createDecipheriv("aes-256-cbc", Buffer.concat([keyBuf], 32), Buffer.alloc(16));
  return Buffer.concat([decipher.update(cipherBuf), decipher.final()]).toString("utf8");
}

function selectActiveKey(keys: KeyPair[], maxAgeMs: number, nowMs = Date.now()): KeyPair | null {
  const live = keys.filter((k) => !isKeyExpired(k, maxAgeMs, nowMs));
  if (live.length === 0) return null;
  return live.reduce((newest, k) => (k.createdAt > newest.createdAt ? k : newest));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const NOW = 1_700_000_000_000;

describe("generateKeyPair", () => {
  it("produces a public and private key", () => {
    const kp = generateKeyPair(NOW);
    expect(kp.publicKey).toBeTruthy();
    expect(kp.privateKey).toBeTruthy();
  });
  it("public key length is 64 hex chars (32 bytes)", () => {
    const kp = generateKeyPair(NOW);
    expect(kp.publicKey).toHaveLength(64);
  });
  it("id is the first 8 chars of public key", () => {
    const kp = generateKeyPair(NOW);
    expect(kp.id).toBe(kp.publicKey.slice(0, 8));
  });
  it("two generated pairs are different", () => {
    const kp1 = generateKeyPair(NOW);
    const kp2 = generateKeyPair(NOW);
    expect(kp1.publicKey).not.toBe(kp2.publicKey);
  });
});

describe("keyFingerprint", () => {
  it("returns the first 8 chars of the public key", () => {
    const kp = generateKeyPair(NOW);
    expect(keyFingerprint(kp)).toBe(kp.publicKey.slice(0, 8));
  });
  it("fingerprint is 8 characters long", () => {
    const kp = generateKeyPair(NOW);
    expect(keyFingerprint(kp)).toHaveLength(8);
  });
});

describe("isKeyExpired", () => {
  it("key is not expired within maxAge", () => {
    const kp = generateKeyPair(NOW);
    expect(isKeyExpired(kp, 86_400_000, NOW + 1000)).toBe(false);
  });
  it("key is expired past maxAge", () => {
    const kp = generateKeyPair(NOW);
    expect(isKeyExpired(kp, 1000, NOW + 2000)).toBe(true);
  });
  it("key is not expired at exact boundary", () => {
    const kp = generateKeyPair(NOW);
    expect(isKeyExpired(kp, 1000, NOW + 1000)).toBe(false);
  });
  it("newly created key is never expired", () => {
    const kp = generateKeyPair(NOW);
    expect(isKeyExpired(kp, 60_000, NOW)).toBe(false);
  });
});

describe("rotateKey", () => {
  it("produces a different key from the current one", () => {
    const current = generateKeyPair(NOW);
    const rotated = rotateKey(current, NOW + 1000);
    expect(rotated.publicKey).not.toBe(current.publicKey);
  });
  it("rotated key has the given creation time", () => {
    const current = generateKeyPair(NOW);
    const rotated = rotateKey(current, NOW + 5000);
    expect(rotated.createdAt).toBe(NOW + 5000);
  });
  it("rotated key has all required fields", () => {
    const current = generateKeyPair(NOW);
    const rotated = rotateKey(current, NOW + 1);
    expect(rotated.publicKey).toBeTruthy();
    expect(rotated.privateKey).toBeTruthy();
    expect(rotated.id).toBeTruthy();
  });
});

describe("encryptEnvelope + decryptEnvelope", () => {
  it("decrypted plaintext matches original", () => {
    const key = randomBytes(16).toString("hex");
    const env = encryptEnvelope("hello mesh", key, NOW);
    expect(decryptEnvelope(env, key)).toBe("hello mesh");
  });
  it("envelope contains a keyId", () => {
    const key = randomBytes(16).toString("hex");
    const env = encryptEnvelope("test", key, NOW);
    expect(env.keyId).toBeTruthy();
  });
  it("envelope ciphertext differs from plaintext", () => {
    const key = randomBytes(16).toString("hex");
    const env = encryptEnvelope("secret", key, NOW);
    expect(env.ciphertext).not.toContain("secret");
  });
  it("tag is present and non-empty", () => {
    const key = randomBytes(16).toString("hex");
    const env = encryptEnvelope("data", key, NOW);
    expect(env.tag).toBeTruthy();
    expect(env.tag).toHaveLength(64);
  });
  it("different plaintexts produce different ciphertexts", () => {
    const key = randomBytes(16).toString("hex");
    const e1 = encryptEnvelope("message A", key, NOW);
    const e2 = encryptEnvelope("message B", key, NOW);
    expect(e1.ciphertext).not.toBe(e2.ciphertext);
  });
  it("encrypts empty string without error", () => {
    const key = randomBytes(16).toString("hex");
    const env = encryptEnvelope("", key, NOW);
    expect(decryptEnvelope(env, key)).toBe("");
  });
});

describe("verifyTag", () => {
  it("returns true for authentic envelope", () => {
    const key = randomBytes(16).toString("hex");
    const env = encryptEnvelope("authentic", key, NOW);
    expect(verifyTag(env, key)).toBe(true);
  });
  it("returns false when tag is tampered", () => {
    const key = randomBytes(16).toString("hex");
    const env = encryptEnvelope("authentic", key, NOW);
    const tampered = { ...env, tag: "0".repeat(64) };
    expect(verifyTag(tampered, key)).toBe(false);
  });
  it("returns false when ciphertext is tampered", () => {
    const key = randomBytes(16).toString("hex");
    const env = encryptEnvelope("authentic", key, NOW);
    const tampered = { ...env, ciphertext: env.ciphertext.slice(0, -2) + "ff" };
    expect(verifyTag(tampered, key)).toBe(false);
  });
  it("returns false with wrong key", () => {
    const key1 = randomBytes(16).toString("hex");
    const key2 = randomBytes(16).toString("hex");
    const env = encryptEnvelope("authentic", key1, NOW);
    expect(verifyTag(env, key2)).toBe(false);
  });
  it("decryptEnvelope throws on tampered tag", () => {
    const key = randomBytes(16).toString("hex");
    const env = encryptEnvelope("authentic", key, NOW);
    const tampered = { ...env, tag: "a".repeat(64) };
    expect(() => decryptEnvelope(tampered, key)).toThrow("Tag mismatch");
  });
});

describe("selectActiveKey", () => {
  it("returns null when all keys are expired", () => {
    const keys = [generateKeyPair(NOW - 100_000)];
    expect(selectActiveKey(keys, 1000, NOW)).toBeNull();
  });
  it("returns the newest non-expired key", () => {
    const k1 = generateKeyPair(NOW);
    const k2 = generateKeyPair(NOW + 500);
    const result = selectActiveKey([k1, k2], 10_000, NOW + 1000);
    expect(result?.createdAt).toBe(NOW + 500);
  });
  it("returns null for empty key list", () => {
    expect(selectActiveKey([], 10_000, NOW)).toBeNull();
  });
});
