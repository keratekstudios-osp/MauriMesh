import { NativeModules, Platform } from "react-native";

export type NativeBleTransport =
  | "BLE_GATT"
  | "BLE_ADVERTISE"
  | "BLE_SCAN"
  | "BRIDGE_LOG_ONLY"
  | "REACT_NATIVE_FALLBACK"
  | "UNKNOWN";

export type NativeBlePacketStage =
  | "BLE_ADVERTISE_START"
  | "BLE_ADVERTISE_PAYLOAD"
  | "BLE_SCAN_START"
  | "BLE_SCAN_RESULT"
  | "GATT_CONNECT_START"
  | "GATT_CONNECTED"
  | "GATT_SERVICE_DISCOVERED"
  | "GATT_WRITE_PACKET"
  | "GATT_WRITE_ACK"
  | "GATT_CHARACTERISTIC_CHANGED"
  | "GATT_READ_PACKET"
  | "RELAY_PACKET_NATIVE"
  | "ACK_PACKET_NATIVE"
  | "GATT_DISCONNECT"
  | "BLE_ERROR"
  | string;

export type NativeBleDeviceRole =
  | "A06_PHONE_A"
  | "S10_PHONE_B"
  | "A16_PHONE_C"
  | "PHONE_A"
  | "PHONE_B"
  | "PHONE_C"
  | string;

export type NativeBlePacketLogInput = {
  role: NativeBleDeviceRole;
  stage: NativeBlePacketStage;
  packetId: string;
  transport: NativeBleTransport;
  detail: string;
};

const MODULE_NAME = "MauriMeshNativeBlePacket";

function clean(value: unknown): string {
  return String(value ?? "")
    .replace(/\s+/g, "_")
    .replace(/[|]/g, "/")
    .trim();
}

export function formatNativeBlePacketLine(input: NativeBlePacketLogInput): string {
  const role = clean(input.role);
  const stage = clean(input.stage);
  const packetId = clean(input.packetId || "NO_PACKET_ID");
  const transport = clean(input.transport || "UNKNOWN");
  const detail = clean(input.detail);

  return `MAURIMESH_NATIVE_BLE_PACKET | role=${role} | stage=${stage} | packetId=${packetId} | transport=${transport} | detail=${detail}`;
}

export async function nativeBlePacketLog(input: NativeBlePacketLogInput): Promise<void> {
  const line = formatNativeBlePacketLine(input);
  const nativeModule = NativeModules?.[MODULE_NAME];

  if (nativeModule?.logPacketEvent) {
    await nativeModule.logPacketEvent({
      role: input.role,
      stage: input.stage,
      packetId: input.packetId,
      transport: input.transport,
      detail: input.detail,
      line,
      platform: Platform.OS,
    });
    return;
  }

  console.log(
    `MAURIMESH_NATIVE_BLE_PACKET_FALLBACK | role=${clean(input.role)} | stage=${clean(
      input.stage
    )} | packetId=${clean(input.packetId)} | transport=REACT_NATIVE_FALLBACK | detail=${clean(
      input.detail
    )}`
  );
}

export function nativeBlePacketLogSafe(input: NativeBlePacketLogInput): void {
  void nativeBlePacketLog(input).catch((err) => {
    console.log(
      `MAURIMESH_NATIVE_BLE_PACKET_FALLBACK | role=${clean(input.role)} | stage=${clean(
        input.stage
      )} | packetId=${clean(input.packetId)} | transport=REACT_NATIVE_FALLBACK | detail=LOGGER_ERROR_${
        err instanceof Error ? clean(err.message) : "UNKNOWN"
      }`
    );
  });
}

export const NativeBlePacketStages = {
  BLE_ADVERTISE_START: "BLE_ADVERTISE_START",
  BLE_ADVERTISE_PAYLOAD: "BLE_ADVERTISE_PAYLOAD",
  BLE_SCAN_START: "BLE_SCAN_START",
  BLE_SCAN_RESULT: "BLE_SCAN_RESULT",
  GATT_CONNECT_START: "GATT_CONNECT_START",
  GATT_CONNECTED: "GATT_CONNECTED",
  GATT_SERVICE_DISCOVERED: "GATT_SERVICE_DISCOVERED",
  GATT_WRITE_PACKET: "GATT_WRITE_PACKET",
  GATT_WRITE_ACK: "GATT_WRITE_ACK",
  GATT_CHARACTERISTIC_CHANGED: "GATT_CHARACTERISTIC_CHANGED",
  GATT_READ_PACKET: "GATT_READ_PACKET",
  RELAY_PACKET_NATIVE: "RELAY_PACKET_NATIVE",
  ACK_PACKET_NATIVE: "ACK_PACKET_NATIVE",
  GATT_DISCONNECT: "GATT_DISCONNECT",
  BLE_ERROR: "BLE_ERROR",
} as const;
