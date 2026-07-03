import { nativeBlePacketLogSafe } from "../src/maurimesh/native/nativeBlePacketLogger";
import AsyncStorage from "@react-native-async-storage/async-storage";
export { default } from "./3-device-proof";


function mauriMeshNativePacketProofLog(stage: string, packetId: string, detail?: string) {
  nativeBlePacketLogSafe({
    role: "PHONE_PROOF",
    stage,
    packetId,
    transport: "BRIDGE_LOG_ONLY",
    detail: detail || stage,
  });
}
// MAURIMESH_NATIVE_BLE_PACKET_PATCH_MARKER


/*
MAURIMESH_NATIVE_BLE_PACKET_REQUIRED_STAGE_MAP

When proof stage buttons/log events fire, call:

nativeBlePacketLogSafe({
  role: "A06_PHONE_A" | "S10_PHONE_B" | "A16_PHONE_C",
  stage: "GATT_WRITE_PACKET" | "GATT_READ_PACKET" | "RELAY_PACKET_NATIVE" | "ACK_PACKET_NATIVE" | "GATT_CHARACTERISTIC_CHANGED",
  packetId,
  transport: "BRIDGE_LOG_ONLY",
  detail: "TX_A06_TO_S10" | "RX_S10_FROM_A06" | "RELAY_S10_TO_A16" | "RX_A16_FROM_S10" | "ACK_A16_TO_S10" | "ACK_RELAY_S10_TO_A06" | "ACK_RECEIVED_A06"
});

This patch does not claim real BLE/GATT proof.
Real native PASS requires transport=BLE_GATT inside Android Bluetooth/GATT callbacks.
*/



/* MAURIMESH_BLE_THREE_DEVICE_RELAY_PROOF_VAULT_STORAGE_V1_START */
async function mauriMeshSaveBleThreeDeviceProofToVault(packetId: string, proofLog: string) {
  try {
    const safePacketId = String(packetId || "NO_PACKET_ID").trim();
    const key = `maurimesh_proof_ble_3_device_${safePacketId}`;
    const payload = {
      type: "BLE_THREE_DEVICE_RELAY_PROOF",
      packetId: safePacketId,
      truthClass: "APK_PROOF_SCREEN_WORKFLOW",
      nativeBleGattPacketBoundPass: false,
      savedAt: new Date().toISOString(),
      proofLog,
      warning:
        "Native BLE/GATT packet-bound PASS is not claimed unless the same packetId appears inside native BLE/GATT transport logs.",
    };

    await AsyncStorage.setItem(key, JSON.stringify(payload));

    console.log(
      `MAURIMESH_PROOF_VAULT_SAVE | BLE_THREE_DEVICE_RELAY_PROOF | packetId=${safePacketId} | key=${key} | truthClass=APK_PROOF_SCREEN_WORKFLOW | nativeBleGattPacketBoundPass=false`
    );
  } catch (err) {
    console.log(
      `MAURIMESH_PROOF_VAULT_SAVE_ERROR | BLE_THREE_DEVICE_RELAY_PROOF | packetId=${packetId || "NO_PACKET_ID"} | error=${
        err instanceof Error ? err.message : "UNKNOWN"
      }`
    );
  }
}
/* MAURIMESH_BLE_THREE_DEVICE_RELAY_PROOF_VAULT_STORAGE_V1_END */



/*
MAURIMESH_BLE_THREE_DEVICE_RELAY_PROOF_VAULT_SAVE_CALL_RULE

When this proof reaches EXAM_APPROVED or final completion, call:

void mauriMeshSaveBleThreeDeviceProofToVault(packetId, proofLogText);

Saved key format:

maurimesh_proof_ble_3_device_<packetId>

Truth:
This stores APK proof-screen workflow evidence only.
It does not claim native BLE/GATT packet-bound proof.
*/

