import { NativeEventEmitter, NativeModules, Platform } from "react-native";
import { recordProofMetricEvent } from "./proofMetricsSpine";
import {
  MAURIMESH_RAW_PACKET_PROOF_EVENT_NAME,
  TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
} from "./nativeProofEventBridgeConstants";

type NativeProofEvent = {
  marker?: string;
  type?: string;
  packetId?: string;
  peerAddress?: string;
  payloadBytes?: number;
  ok?: boolean;
  at?: number;
  transport?: string;
  detail?: string | null;
};

let subscription: { remove: () => void } | null = null;
let started = false;

function normalizeType(type?: string) {
  if (type === "rx_packet") return "rx_packet";
  if (type === "ack_sent") return "ack_sent";
  if (type === "ack_received") return "ack_received";
  if (type === "delivery_failed") return "delivery_failed";
  if (type === "send_submitted") return "send_submitted";
  return "rx_packet";
}

export function startNativeProofEventBridge() {
  if (Platform.OS !== "android") {
    return {
      ok: false,
      marker: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
      reason: "Android only",
    };
  }

  if (started) {
    return {
      ok: true,
      marker: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
      reason: "already_started",
    };
  }

  const native = NativeModules.MauriMeshBle;
  if (!native) {
    return {
      ok: false,
      marker: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
      reason: "MauriMeshBle native module unavailable",
    };
  }

  const emitter = new NativeEventEmitter(native);

  subscription = emitter.addListener(
    MAURIMESH_RAW_PACKET_PROOF_EVENT_NAME,
    async (event: NativeProofEvent) => {
      const packetId =
        event.packetId ||
        `MM-NATIVE-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`;

      const eventType = normalizeType(event.type);

      await recordProofMetricEvent({
        type: event.ok === false ? "delivery_failed" : eventType,
        packetId,
        fromNode: event.peerAddress || "native-peer",
        toNode: "local-device",
        peerId: event.peerAddress,
        transport: "BLE",
        payloadBytes: event.payloadBytes || 0,
        reason: event.detail || undefined,
        raw: event,
      });
    }
  );

  started = true;

  return {
    ok: true,
    marker: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
    reason: "started",
  };
}

export function stopNativeProofEventBridge() {
  subscription?.remove();
  subscription = null;
  started = false;

  return {
    ok: true,
    marker: TASK_192_NATIVE_PROOF_EVENT_BRIDGE_MARKER,
    reason: "stopped",
  };
}
