import { NativeModules, Platform } from "react-native";
import { sendRawPacketToNode } from "./rawPacketClient";

export const TASK_165B_RAW_PACKET_PROOF_CLIENT_MARKER =
  "TASK_165B_RAW_PACKET_PROOF_CLIENT_20260608_A";

export type RawPacketReceiverStatus = {
  ok?: boolean;
  marker?: string;
  serverMarker?: string;
  running?: boolean;
  receivedCount?: number;
  lastFromAddress?: string | null;
  lastPacketSize?: number;
  lastReceivedAtMs?: number;
  lastError?: string | null;
  serviceUuid?: string | null;
  characteristicUuid?: string | null;
  ackCount?: number;
  lastAckTarget?: string | null;
  lastAckSentAtMs?: number;
  peerCount?: number;
};

type RawPacketReceiverNative = {
  startRawPacketReceiver?: () => Promise<RawPacketReceiverStatus>;
  stopRawPacketReceiver?: () => Promise<RawPacketReceiverStatus>;
  getRawPacketReceiverStatus?: () => Promise<RawPacketReceiverStatus>;
  sendRawPacketUtf8?: (nodeId: string, text: string) => Promise<boolean>;
};

function native(): RawPacketReceiverNative | null {
  return (NativeModules.MauriMeshBle as RawPacketReceiverNative | undefined) || null;
}

export async function startRawPacketReceiver(): Promise<RawPacketReceiverStatus> {
  if (Platform.OS !== "android") return { ok: false, lastError: "Android only" };
  const n = native();
  if (!n?.startRawPacketReceiver) {
    throw new Error("MauriMeshBle.startRawPacketReceiver unavailable");
  }
  return n.startRawPacketReceiver();
}

export async function stopRawPacketReceiver(): Promise<RawPacketReceiverStatus> {
  if (Platform.OS !== "android") return { ok: false, lastError: "Android only" };
  const n = native();
  if (!n?.stopRawPacketReceiver) {
    throw new Error("MauriMeshBle.stopRawPacketReceiver unavailable");
  }
  return n.stopRawPacketReceiver();
}

export async function getRawPacketReceiverStatus(): Promise<RawPacketReceiverStatus> {
  if (Platform.OS !== "android") return { ok: false, lastError: "Android only" };
  const n = native();
  if (!n?.getRawPacketReceiverStatus) {
    throw new Error("MauriMeshBle.getRawPacketReceiverStatus unavailable");
  }
  return n.getRawPacketReceiverStatus();
}

export async function sendRawPacketUtf8(nodeId: string, text: string): Promise<boolean> {
  if (Platform.OS !== "android") return false;
  const n = native();
  if (n?.sendRawPacketUtf8) {
    return Boolean(await n.sendRawPacketUtf8(nodeId, text));
  }

  const bytes = new TextEncoder().encode(text);
  return sendRawPacketToNode(nodeId, bytes);
}

export function makeProofPayload(label: string): string {
  return `MAURIMESH_RAW_PROOF|${label}|${Date.now()}`;
}
