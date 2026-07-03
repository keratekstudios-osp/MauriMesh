import { describe, it, expect } from "vitest";
import {
  normalizeProofEvidence,
  TWO_PHONE_EVIDENCE_TYPE,
  MAX_EVIDENCE_BYTES,
} from "../../server/proofEvidence";

describe("normalizeProofEvidence — hardware proof evidence persistence", () => {
  it("uses the canonical two-phone hardware evidence type", () => {
    expect(TWO_PHONE_EVIDENCE_TYPE).toBe("two_phone_hardware_evidence");
  });

  it("shapes a raw evidence object into a proofLedger row", () => {
    const row = normalizeProofEvidence({ runResult: "ack-ok", tx: 4, rx: 4 });
    expect(row.eventType).toBe(TWO_PHONE_EVIDENCE_TYPE);
    expect(row.source).toBe("mobile_two_phone_proof");
  });

  it("never marks server-stored evidence as verified or real_native", () => {
    const row = normalizeProofEvidence({ runResult: "ack-ok" });
    // Truth boundary: the server cannot prove BLE, so it must not attest it.
    expect(row.verified).toBe(false);
    expect(row.runtimeMode).toBe("client_submitted_evidence");
    expect(row.runtimeMode).not.toContain("real_native");
  });

  it("accepts an { evidence: {...} } envelope as well as a raw object", () => {
    const wrapped = normalizeProofEvidence({ evidence: { runResult: "ok" } });
    const raw = normalizeProofEvidence({ runResult: "ok" });
    expect(JSON.parse(wrapped.rawLogExcerpt!)).toEqual({ runResult: "ok" });
    expect(JSON.parse(raw.rawLogExcerpt!)).toEqual({ runResult: "ok" });
  });

  it("stores the full evidence JSON verbatim in rawLogExcerpt", () => {
    const evidence = {
      deviceId: "phone-A",
      peerId: "phone-B",
      packetId: "pkt-1",
      routeId: "route-1",
      ackId: "ack-1",
      log: ["tx", "rx", "ack"],
    };
    const row = normalizeProofEvidence(evidence);
    expect(JSON.parse(row.rawLogExcerpt!)).toEqual(evidence);
  });

  it("lifts known identifiers out of the evidence into columns", () => {
    const row = normalizeProofEvidence({
      deviceId: "phone-A",
      peerId: "phone-B",
      packetId: "pkt-1",
      routeId: "route-1",
      ackId: "ack-1",
    });
    expect(row.deviceId).toBe("phone-A");
    expect(row.peerId).toBe("phone-B");
    expect(row.packetId).toBe("pkt-1");
    expect(row.routeId).toBe("route-1");
    expect(row.ackId).toBe("ack-1");
  });

  it("leaves identifier columns undefined when absent", () => {
    const row = normalizeProofEvidence({ runResult: "ok" });
    expect(row.deviceId).toBeUndefined();
    expect(row.ackId).toBeUndefined();
  });

  it("rejects a missing, empty, or non-object payload", () => {
    expect(() => normalizeProofEvidence(undefined)).toThrow();
    expect(() => normalizeProofEvidence({})).toThrow();
    expect(() => normalizeProofEvidence({ evidence: {} })).toThrow();
    expect(() => normalizeProofEvidence([1, 2, 3])).toThrow();
  });

  it("rejects an oversized payload to protect the ledger", () => {
    const huge = { blob: "x".repeat(MAX_EVIDENCE_BYTES + 1) };
    expect(() => normalizeProofEvidence(huge)).toThrow(/byte limit/);
    // A payload just under the cap is still accepted.
    const ok = { blob: "x".repeat(1000) };
    expect(() => normalizeProofEvidence(ok)).not.toThrow();
  });
});
