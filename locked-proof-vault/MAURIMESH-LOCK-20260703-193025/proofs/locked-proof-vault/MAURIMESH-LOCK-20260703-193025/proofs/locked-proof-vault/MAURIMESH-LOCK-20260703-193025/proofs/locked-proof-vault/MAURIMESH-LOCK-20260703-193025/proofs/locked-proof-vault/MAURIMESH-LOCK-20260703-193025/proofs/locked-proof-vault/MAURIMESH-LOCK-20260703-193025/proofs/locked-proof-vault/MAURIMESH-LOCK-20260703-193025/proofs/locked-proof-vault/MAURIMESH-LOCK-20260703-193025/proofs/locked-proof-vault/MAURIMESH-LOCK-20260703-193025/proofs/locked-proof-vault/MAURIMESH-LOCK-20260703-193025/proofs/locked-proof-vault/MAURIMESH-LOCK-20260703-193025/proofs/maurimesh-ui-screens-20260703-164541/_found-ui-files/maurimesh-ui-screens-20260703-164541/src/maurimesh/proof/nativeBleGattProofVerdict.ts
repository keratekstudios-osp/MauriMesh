export type NativeBleGattVerdict = {
  verdict:
    | "NATIVE_BLE_GATT_PACKET_BOUND_PASS"
    | "APK_WORKFLOW_ONLY_NATIVE_NOT_CONFIRMED"
    | "NO_PACKET_FOUND";
  packetId: string;
  nativeTransportHits: number;
  workflowHits: number;
  explanation: string;
};

const nativeTransportMarkers = [
  "BluetoothGatt",
  "BtGatt",
  "GATT",
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
  "MAURIMESH_NATIVE_BLE_PACKET",
  "transport=BLE_GATT",
];

const workflowMarkers = [
  "ReactNativeJS",
  "MAURIMESH_3_DEVICE_PROOF",
  "MAURIMESH_STORE_FORWARD_PROOF",
  "EXAM_APPROVED",
];

export function evaluateNativeBleGattPacketProof(
  logText: string,
  packetId: string
): NativeBleGattVerdict {
  const lines = logText.split(/\r?\n/);
  const packetLines = lines.filter((line) => line.includes(packetId));

  if (packetLines.length === 0) {
    return {
      verdict: "NO_PACKET_FOUND",
      packetId,
      nativeTransportHits: 0,
      workflowHits: 0,
      explanation: "No lines were found for this packetId.",
    };
  }

  const nativeTransportHits = packetLines.filter((line) =>
    nativeTransportMarkers.some((marker) => line.includes(marker))
  ).length;

  const workflowHits = packetLines.filter((line) =>
    workflowMarkers.some((marker) => line.includes(marker))
  ).length;

  if (nativeTransportHits > 0) {
    return {
      verdict: "NATIVE_BLE_GATT_PACKET_BOUND_PASS",
      packetId,
      nativeTransportHits,
      workflowHits,
      explanation:
        "The packetId appears in native BLE/GATT transport-marked lines. Validate role/path continuity before final lock.",
    };
  }

  return {
    verdict: "APK_WORKFLOW_ONLY_NATIVE_NOT_CONFIRMED",
    packetId,
    nativeTransportHits,
    workflowHits,
    explanation:
      "The packetId appears in app/workflow logs but not in native BLE/GATT transport-marked lines.",
  };
}
