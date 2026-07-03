import {
  TASK_190_PROOF_METRICS_SPINE_MARKER,
  makeProofPacketId,
} from "../../src/maurimesh/live/proofMetricsSpine";

if (TASK_190_PROOF_METRICS_SPINE_MARKER !== "TASK_190_PROOF_METRICS_SPINE_20260608_A") {
  throw new Error("Wrong metrics marker");
}

const packetId = makeProofPacketId("MM-TEST");

if (!packetId.startsWith("MM-TEST-")) {
  throw new Error("Packet id generator failed");
}

console.log("PASS: TASK_190_PROOF_METRICS_SPINE_STATIC_TEST_20260608_A");
