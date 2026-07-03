import {
  shapeTwoPhoneHardwareEvidenceRow,
  TWO_PHONE_HARDWARE_EVIDENCE_TYPE,
} from "../../server/proofEvidence";

const evidence = {
  packetId: "MM-HW-PROOF-001",
  fromNode: "PHONE_A",
  toNode: "PHONE_B",
  transport: "BLE",
  status: "RX_ACK_CONFIRMED",
  events: [
    { stage: "TX_RAW_PACKET", at: "2026-06-08T00:00:00.000Z" },
    { stage: "RX_RAW_PACKET", at: "2026-06-08T00:00:01.000Z" },
    { stage: "ACK_SENT", at: "2026-06-08T00:00:02.000Z" },
  ],
};

const row = shapeTwoPhoneHardwareEvidenceRow(evidence);

if (row.eventType !== TWO_PHONE_HARDWARE_EVIDENCE_TYPE) {
  throw new Error("Wrong eventType");
}

if (row.packetId !== "MM-HW-PROOF-001") {
  throw new Error("Wrong packetId");
}

if (!row.proofHash || row.proofHash.length < 32) {
  throw new Error("Missing proof hash");
}

if ((row.evidenceJson as any).events.length !== 3) {
  throw new Error("Evidence JSON was not preserved");
}

console.log("PASS: TASK_189B_PROOF_EVIDENCE_SHAPE_TEST_20260608_A");
