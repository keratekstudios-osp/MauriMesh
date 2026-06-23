import { NativeModules, Platform } from "react-native";

export const TASK_165_RAW_PACKET_CLIENT_MARKER =
  "TASK_165_RAW_PACKET_CLIENT_20260608_ACTIVE_ANDROID_A";

type MauriMeshBleRawPacketModule = {
  sendRawPacket?: (nodeId: string, base64Payload: string) => Promise<boolean>;
  broadcastRawPacket?: (base64Payload: string) => Promise<number>;
  getRawPacketPeerCount?: () => Promise<number>;
};

function toBase64(bytes: Uint8Array): string {
  const chars = Array.from(bytes, (byte) => String.fromCharCode(byte)).join("");

  if (typeof btoa === "function") {
    return btoa(chars);
  }

  const BufferCtor = (globalThis as any).Buffer;
  if (BufferCtor) {
    return BufferCtor.from(bytes).toString("base64");
  }

  throw new Error("Base64 encoder unavailable");
}

function getNative(): MauriMeshBleRawPacketModule | null {
  return (NativeModules.MauriMeshBle as MauriMeshBleRawPacketModule | undefined) || null;
}

export async function sendRawPacketToNode(
  nodeId: string,
  bytes: Uint8Array
): Promise<boolean> {
  if (Platform.OS !== "android") return false;

  const native = getNative();

  if (!native?.sendRawPacket) {
    throw new Error("MauriMeshBle.sendRawPacket is unavailable");
  }

  return Boolean(await native.sendRawPacket(nodeId, toBase64(bytes)));
}

export async function broadcastRawPacketToPeers(bytes: Uint8Array): Promise<number> {
  if (Platform.OS !== "android") return 0;

  const native = getNative();

  if (!native?.broadcastRawPacket) {
    throw new Error("MauriMeshBle.broadcastRawPacket is unavailable");
  }

  return Number(await native.broadcastRawPacket(toBase64(bytes)));
}

export async function getRawPacketPeerCount(): Promise<number> {
  if (Platform.OS !== "android") return 0;

  const native = getNative();

  if (!native?.getRawPacketPeerCount) {
    return 0;
  }

  return Number(await native.getRawPacketPeerCount());
}
