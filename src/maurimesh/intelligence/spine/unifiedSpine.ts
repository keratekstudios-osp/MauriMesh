import { MauriMeshProofSignal } from "../types";
import { mauriMeshRunUnifiedExam } from "../exam/examEngine";

export function mauriMeshUnifiedSpine(input: {
  packetId: string;
  proofType: "3_DEVICE" | "STORE_FORWARD" | "NATIVE_BLE_GATT";
  signals: MauriMeshProofSignal[];
  vaultStored: boolean;
  dashboardStable: boolean;
  userApprovedExam: boolean;
}) {
  const exam = mauriMeshRunUnifiedExam({
    packetId: input.packetId,
    proofType: input.proofType,
    signals: input.signals,
    vaultStored: input.vaultStored,
    dashboardStable: input.dashboardStable,
    userApprovedExam: input.userApprovedExam,
  });

  return {
    system: "MAURIMESH_UNIFIED_INTELLIGENCE_SPINE_V1",
    generatedAt: new Date().toISOString(),
    packetId: input.packetId,
    proofType: input.proofType,
    exam,
    lockable: exam.passed && exam.decision === "APPROVED",
    nativeBleGattPacketBoundPass: exam.truthClass === "NATIVE_BLE_GATT_PACKET_BOUND",
    truth:
      "All layers work together, but native BLE/GATT packet-bound PASS is only true when the same packetId appears inside native BLE/GATT transport logs.",
  };
}
