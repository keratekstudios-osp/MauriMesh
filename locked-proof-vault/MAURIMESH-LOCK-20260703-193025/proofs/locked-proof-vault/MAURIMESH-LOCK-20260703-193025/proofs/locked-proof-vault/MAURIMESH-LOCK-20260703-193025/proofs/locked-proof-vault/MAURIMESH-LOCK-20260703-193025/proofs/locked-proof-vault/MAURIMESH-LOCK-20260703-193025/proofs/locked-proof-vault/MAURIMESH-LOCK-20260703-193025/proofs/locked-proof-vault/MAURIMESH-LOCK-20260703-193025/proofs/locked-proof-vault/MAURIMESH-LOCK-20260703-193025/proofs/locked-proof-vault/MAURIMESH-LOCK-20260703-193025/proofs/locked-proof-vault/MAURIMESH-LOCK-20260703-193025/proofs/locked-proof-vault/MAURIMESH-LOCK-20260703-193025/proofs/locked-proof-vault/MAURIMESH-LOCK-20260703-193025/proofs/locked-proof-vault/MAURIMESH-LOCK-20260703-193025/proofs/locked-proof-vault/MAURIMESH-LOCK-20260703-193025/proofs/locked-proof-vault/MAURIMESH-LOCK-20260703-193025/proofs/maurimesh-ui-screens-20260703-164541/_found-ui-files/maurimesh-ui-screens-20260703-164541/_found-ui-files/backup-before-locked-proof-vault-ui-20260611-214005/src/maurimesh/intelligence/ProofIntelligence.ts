import { ProofDecision } from "./types";

function scoreBool(value: boolean, weight: number) {
  return value ? weight : 0;
}

export function evaluateProof(input?: Partial<ProofDecision>): ProofDecision {
  const proof = {
    packetId: input?.packetId || "MM-INTEL-PROOF-UI-001",
    hashPresent: input?.hashPresent ?? true,
    ackPresent: input?.ackPresent ?? true,
    routePresent: input?.routePresent ?? true,
    timestampPresent: input?.timestampPresent ?? true,
    deviceLogPresent: input?.deviceLogPresent ?? false,
    confidence: 0,
    truth: "",
  };

  const confidence =
    scoreBool(proof.hashPresent, 22) +
    scoreBool(proof.ackPresent, 22) +
    scoreBool(proof.routePresent, 18) +
    scoreBool(proof.timestampPresent, 14) +
    scoreBool(proof.deviceLogPresent, 24);

  return {
    ...proof,
    confidence,
    truth: proof.deviceLogPresent
      ? "Device proof present. Real APK/logcat evidence can be reviewed."
      : "UI proof confidence only. Real BLE proof still requires APK/device logcat evidence.",
  };
}
