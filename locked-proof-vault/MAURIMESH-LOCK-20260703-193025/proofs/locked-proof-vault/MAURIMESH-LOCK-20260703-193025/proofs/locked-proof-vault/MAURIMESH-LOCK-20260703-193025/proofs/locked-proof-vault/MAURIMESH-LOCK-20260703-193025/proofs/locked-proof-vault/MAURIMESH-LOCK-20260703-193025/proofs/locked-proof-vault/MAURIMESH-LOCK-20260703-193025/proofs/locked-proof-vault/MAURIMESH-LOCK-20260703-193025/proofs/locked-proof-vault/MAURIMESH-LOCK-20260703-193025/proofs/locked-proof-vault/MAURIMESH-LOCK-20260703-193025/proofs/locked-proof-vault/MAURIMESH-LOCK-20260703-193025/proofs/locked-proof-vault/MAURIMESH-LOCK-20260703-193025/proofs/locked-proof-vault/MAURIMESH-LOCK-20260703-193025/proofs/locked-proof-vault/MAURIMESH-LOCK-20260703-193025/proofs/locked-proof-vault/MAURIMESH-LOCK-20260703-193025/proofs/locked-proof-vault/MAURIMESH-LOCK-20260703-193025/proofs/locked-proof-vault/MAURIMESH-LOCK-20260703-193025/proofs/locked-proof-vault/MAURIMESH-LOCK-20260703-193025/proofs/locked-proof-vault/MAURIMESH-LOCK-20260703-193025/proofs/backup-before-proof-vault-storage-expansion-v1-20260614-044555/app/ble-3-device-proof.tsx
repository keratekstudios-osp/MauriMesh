import { nativeBlePacketLogSafe } from "../src/maurimesh/native/nativeBlePacketLogger";
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
