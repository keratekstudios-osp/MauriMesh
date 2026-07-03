export type LockedProofStatus = "PASSED" | "PENDING" | "FAILED";

export type LockedProof = {
  proofId: string;
  name: string;
  status: LockedProofStatus;
  packetId: string;
  route: string;
  proofClass: string;
  locked: boolean;
  lockedUtc: string;
  devices: Record<string, string>;
  stages: string[];
  evidence: string[];
  truthRule: string;
};

export const MAURIMESH_LOCKED_PROOF_VAULT_BUILD =
  "LOCKED_PROOF_VAULT_UI_20260612";

export const lockedProofs: LockedProof[] = [
  {
    proofId: "MM-PROOF-002-2HOP",
    name: "MauriMesh 2-Hop Device Proof",
    status: "PASSED",
    packetId: "MM-MQ94C3HX-VOZO1H",
    route: "PHONE_A/A06 -> PHONE_B/S10 relay -> ACK_BACK_TO_PHONE_A",
    proofClass: "Physical APK/device proof",
    locked: true,
    lockedUtc: "2026-06-12T00:00:00Z",
    devices: {
      PHONE_A: "A06 / Sender",
      PHONE_B: "S10 / Relay + ACK return",
    },
    stages: [
      "PACKET_ID_GENERATED",
      "TX_A06_TO_S10",
      "RX_S10_FROM_A06",
      "ACK_BACK_TO_PHONE_A",
    ],
    evidence: [
      "APK screen proof",
      "2-hop lit button proof",
      "proof archive screenshots",
      "packetId locked as MM-MQ94C3HX-VOZO1H",
    ],
    truthRule:
      "PASS only when the same packetId appears across sender, relay, and ACK return evidence.",
  },
  {
    proofId: "MM-PROOF-003-3DEVICE-HOP",
    name: "MauriMesh 3-Device Hop Relay Proof",
    status: "PASSED",
    packetId: "MM3-JSY73G-JKDXYR",
    route: "A06 -> S10 -> A16 -> S10 -> A06 ACK",
    proofClass: "Physical APK/logcat 3-device relay proof",
    locked: true,
    lockedUtc: "2026-06-12T00:00:00Z",
    devices: {
      PHONE_A: "A06 / Sender / Wi-Fi ADB",
      PHONE_B: "S10 / Relay / Wi-Fi ADB",
      PHONE_C: "A16 / Receiver + ACK / USB Debugging",
    },
    stages: [
      "PHONE_A / A06 | PACKET_ID_GENERATED",
      "PHONE_A / A06 | TX_A06_TO_S10",
      "PHONE_B / S10 | RX_S10_FROM_A06",
      "PHONE_B / S10 | RELAY_S10_TO_A16",
      "PHONE_C / A16 | RX_A16_FROM_S10",
      "PHONE_C / A16 | ACK_A16_TO_S10",
      "PHONE_B / S10 | ACK_RELAY_S10_TO_A06",
      "PHONE_A / A06 | ACK_RECEIVED_A06",
    ],
    evidence: [
      "APK proof screen",
      "logcat proof",
      "same packetId across PHONE_A, PHONE_B, PHONE_C",
      "packetId locked as MM3-JSY73G-JKDXYR",
    ],
    truthRule:
      "PASS only when the same packetId appears across PHONE_A, PHONE_B, PHONE_C, all relay stages, ACK relay, and final A06 ACK.",
  },
  {
    proofId: "MM-PROOF-004-STORE-FORWARD",
    name: "MauriMesh Store-Forward Delay Proof",
    status: "PASSED",
    packetId: "MMSF-KVM5AQ-ZK423E",
    route:
      "A06 -> S10 STORE -> A16 OFFLINE -> A16 RETURNS -> S10 FORWARD -> A16 ACK -> S10 -> A06 ACK",
    proofClass: "Physical APK/logcat store-forward delay proof",
    locked: true,
    lockedUtc: "2026-06-12T00:00:00Z",
    devices: {
      PHONE_A: "A06 / Sender",
      PHONE_B: "S10 / Store-Forward Relay",
      PHONE_C: "A16 / Delayed Receiver + ACK",
    },
    stages: [
      "PHONE_A / A06 | PACKET_ID_CONFIRMED",
      "PHONE_A / A06 | TX_A06_TO_S10_STORE_REQUEST",
      "PHONE_B / S10 | S10_STORE_PACKET",
      "PHONE_C / A16 | A16_OFFLINE_CONFIRMED",
      "PHONE_B / S10 | S10_HOLD_DELAY",
      "PHONE_C / A16 | A16_RETURNS",
      "PHONE_B / S10 | S10_FORWARD_STORED_TO_A16",
      "PHONE_C / A16 | RX_A16_STORED_PACKET",
      "PHONE_C / A16 | ACK_A16_TO_S10_STORED",
      "PHONE_B / S10 | ACK_RELAY_S10_TO_A06_STORED",
      "PHONE_A / A06 | ACK_RECEIVED_A06_STORED",
    ],
    evidence: [
      "APK proof screen",
      "logcat proof",
      "sequence complete YES",
      "approval APPROVED",
      "all 11 stages DONE",
      "packetId locked as MMSF-KVM5AQ-ZK423E",
    ],
    truthRule:
      "PASS only when the same packetId appears across store, hold, offline/return, forward, receiver RX, ACK relay, and final A06 stored ACK.",
  },
];

export function getProofVaultSummary() {
  const passed = lockedProofs.filter((proof) => proof.status === "PASSED").length;
  const locked = lockedProofs.filter((proof) => proof.locked).length;

  return {
    build: MAURIMESH_LOCKED_PROOF_VAULT_BUILD,
    total: lockedProofs.length,
    passed,
    locked,
    nextProofTarget: "MM-PROOF-005-SELF-HEALING-FAILURE-RECOVERY",
  };
}

export function createLockedProofReport() {
  const summary = getProofVaultSummary();

  return [
    "MAURIMESH LOCKED PROOF VAULT",
    `Build: ${summary.build}`,
    `Total proofs: ${summary.total}`,
    `Passed proofs: ${summary.passed}`,
    `Locked proofs: ${summary.locked}`,
    "",
    ...lockedProofs.flatMap((proof) => [
      "============================================================",
      `${proof.proofId}`,
      `${proof.name}`,
      `Status: ${proof.status}`,
      `Locked: ${proof.locked ? "YES" : "NO"}`,
      `Packet ID: ${proof.packetId}`,
      `Route: ${proof.route}`,
      `Proof class: ${proof.proofClass}`,
      "",
      "Devices:",
      ...Object.entries(proof.devices).map(([role, device]) => `${role}: ${device}`),
      "",
      "Stages:",
      ...proof.stages.map((stage, index) => `${index + 1}. ${stage}`),
      "",
      "Evidence:",
      ...proof.evidence.map((item) => `- ${item}`),
      "",
      `Truth rule: ${proof.truthRule}`,
      "",
    ]),
    "============================================================",
    `Next proof target: ${summary.nextProofTarget}`,
  ].join("\n");
}
