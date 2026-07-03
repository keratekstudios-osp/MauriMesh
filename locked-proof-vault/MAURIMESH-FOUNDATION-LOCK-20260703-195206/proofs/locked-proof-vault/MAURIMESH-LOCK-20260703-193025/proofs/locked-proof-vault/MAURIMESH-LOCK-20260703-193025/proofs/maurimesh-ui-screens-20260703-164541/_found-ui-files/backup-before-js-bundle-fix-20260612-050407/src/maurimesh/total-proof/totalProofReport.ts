import {
  proofBuildIdentity,
  threeHopProof,
  twoHopProof,
} from "./totalProofEngine";

export function generateTotalProofSummary() {
  return {
    generatedAt: proofBuildIdentity.generatedAt,
    twoHop: {
      proofId: twoHopProof.proofId,
      packetId: twoHopProof.packetId,
      routeId: twoHopProof.routeId,
      path: twoHopProof.path,
      requiredStages: twoHopProof.requiredStages,
      physicalRequirement: "2 phones: PHONE_A hotspot/gateway + PHONE_B client/sender",
      proofLevel: "APP_LOG_READY; PHYSICAL_DEVICE_LOGCAT_REQUIRED",
    },
    threeHop: {
      proofId: threeHopProof.proofId,
      packetId: threeHopProof.packetId,
      routeId: threeHopProof.routeId,
      path: threeHopProof.path,
      ackPath: threeHopProof.ackPath,
      requiredStages: threeHopProof.requiredStages,
      physicalRequirement: "3 phones: PHONE_A sender + PHONE_B relay + PHONE_C receiver",
      proofLevel: "APP_LOG_READY; PHYSICAL_3_DEVICE_LOGCAT_REQUIRED",
    },
  };
}
