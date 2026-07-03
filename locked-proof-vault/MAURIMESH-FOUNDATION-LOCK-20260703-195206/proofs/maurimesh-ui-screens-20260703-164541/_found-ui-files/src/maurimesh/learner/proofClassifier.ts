import { ProofClass } from "./types";

const nativeGattMarkers = [
  "BluetoothGatt",
  "BtGatt",
  "GattService",
  "onScanResult",
  "AdvertiseCallback",
  "AdvertisingSet",
  "writeCharacteristic",
  "readCharacteristic",
  "onCharacteristicWrite",
  "onCharacteristicRead",
  "onCharacteristicChanged",
  "onServicesDiscovered",
  "connectGatt",
  "transport=BLE_GATT",
];

const bridgeMarkers = [
  "MAURIMESH_NATIVE_BLE_PACKET",
  "MauriMeshNativeBlePacket",
  "BRIDGE_LOG_ONLY",
];

const reactMarkers = [
  "ReactNativeJS",
  "MAURIMESH_3_DEVICE_PROOF",
  "MAURIMESH_STORE_FORWARD_PROOF",
  "MAURIMESH_2_HOP_PROOF",
];

const workflowMarkers = [
  "EXAM_APPROVED",
  "TX_A06_TO_S10",
  "RX_S10_FROM_A06",
  "RELAY_S10_TO_A16",
  "RX_A16_FROM_S10",
  "ACK_A16_TO_S10",
  "ACK_RELAY_S10_TO_A06",
  "ACK_RECEIVED_A06",
  "STORE_PACKET",
  "STORED",
];

export function classifyProofLine(line: string, packetId?: string): ProofClass {
  const hasPacket = packetId ? line.includes(packetId) : /packetId=|MM3-|MMSF-|MM-/.test(line);
  if (!hasPacket) return "NO_PACKET_FOUND";

  if (nativeGattMarkers.some((m) => line.includes(m))) {
    return "NATIVE_BLE_GATT_PACKET_BOUND";
  }

  if (bridgeMarkers.some((m) => line.includes(m))) {
    if (line.includes("transport=BLE_GATT")) return "NATIVE_BLE_GATT_PACKET_BOUND";
    return "BRIDGE_LOG_ONLY";
  }

  if (reactMarkers.some((m) => line.includes(m))) {
    return "REACTNATIVEJS_MONITOR_PROOF";
  }

  if (workflowMarkers.some((m) => line.includes(m))) {
    return "APK_WORKFLOW_PROOF";
  }

  return "INCONCLUSIVE";
}

export function classConfidence(proofClass: ProofClass): number {
  switch (proofClass) {
    case "NATIVE_BLE_GATT_PACKET_BOUND":
      return 0.95;
    case "REACTNATIVEJS_MONITOR_PROOF":
      return 0.78;
    case "APK_WORKFLOW_PROOF":
      return 0.7;
    case "BRIDGE_LOG_ONLY":
      return 0.55;
    case "INCONCLUSIVE":
      return 0.25;
    case "NO_PACKET_FOUND":
      return 0;
  }
}
