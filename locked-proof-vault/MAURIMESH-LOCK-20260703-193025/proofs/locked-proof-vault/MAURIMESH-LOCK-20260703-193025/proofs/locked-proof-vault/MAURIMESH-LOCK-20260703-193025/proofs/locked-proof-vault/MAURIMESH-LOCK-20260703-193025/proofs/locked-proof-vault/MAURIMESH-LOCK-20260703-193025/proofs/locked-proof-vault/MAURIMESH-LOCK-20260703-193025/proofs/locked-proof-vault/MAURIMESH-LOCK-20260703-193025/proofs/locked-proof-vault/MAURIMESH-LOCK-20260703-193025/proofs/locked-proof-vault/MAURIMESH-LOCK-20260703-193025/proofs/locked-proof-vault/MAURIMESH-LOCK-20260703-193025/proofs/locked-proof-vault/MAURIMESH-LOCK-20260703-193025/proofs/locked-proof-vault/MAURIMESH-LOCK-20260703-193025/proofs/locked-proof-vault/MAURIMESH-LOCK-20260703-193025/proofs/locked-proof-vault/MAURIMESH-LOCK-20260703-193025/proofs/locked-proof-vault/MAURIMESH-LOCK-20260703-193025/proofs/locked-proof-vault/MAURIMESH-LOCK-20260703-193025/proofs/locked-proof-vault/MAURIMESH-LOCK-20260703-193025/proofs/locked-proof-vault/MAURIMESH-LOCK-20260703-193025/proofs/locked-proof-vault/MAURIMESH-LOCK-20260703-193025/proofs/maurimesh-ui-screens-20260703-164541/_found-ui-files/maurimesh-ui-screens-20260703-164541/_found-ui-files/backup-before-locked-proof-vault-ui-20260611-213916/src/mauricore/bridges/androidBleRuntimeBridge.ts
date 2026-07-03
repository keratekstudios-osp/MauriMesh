import { NativeEventEmitter, NativeModules, Platform } from "react-native";
import {
  BleProofEvent,
  getBleProofEvents,
  getBleProofSummary,
  ingestBleProofEvent,
} from "./bleProofEventStore";

type BridgeState = {
  platform: string;
  nativeModulePresent: boolean;
  listening: boolean;
  eventName: string;
  lastError?: string;
};

const EVENT_NAME = "MauriMeshRawPacketProofEvent";

let subscription: { remove: () => void } | null = null;

function getNativeBleModule(): unknown {
  return (
    NativeModules.MauriMeshBleModule ??
    NativeModules.MauriMeshBLEModule ??
    NativeModules.MauriMeshNativeBleModule ??
    null
  );
}

const state: BridgeState = {
  platform: Platform.OS,
  nativeModulePresent: Boolean(getNativeBleModule()),
  listening: false,
  eventName: EVENT_NAME,
};

export function getAndroidBleRuntimeBridgeState(): BridgeState {
  state.nativeModulePresent = Boolean(getNativeBleModule());
  return { ...state };
}

export function startAndroidBleRuntimeBridge(): BridgeState {
  const nativeModule = getNativeBleModule();

  state.nativeModulePresent = Boolean(nativeModule);

  if (Platform.OS !== "android") {
    state.lastError = "Bridge is designed for Android native BLE runtime.";
    return getAndroidBleRuntimeBridgeState();
  }

  if (!nativeModule) {
    state.lastError = "MauriMeshBleModule is not available in NativeModules.";
    return getAndroidBleRuntimeBridgeState();
  }

  if (subscription) {
    state.listening = true;
    return getAndroidBleRuntimeBridgeState();
  }

  try {
    const emitter = new NativeEventEmitter(nativeModule as never);

    subscription = emitter.addListener(EVENT_NAME, (payload: Record<string, unknown>) => {
      ingestBleProofEvent(payload ?? {});
    });

    state.listening = true;
    state.lastError = undefined;
  } catch (error) {
    state.listening = false;
    state.lastError = error instanceof Error ? error.message : String(error);
  }

  return getAndroidBleRuntimeBridgeState();
}

export function stopAndroidBleRuntimeBridge(): BridgeState {
  if (subscription) {
    subscription.remove();
    subscription = null;
  }

  state.listening = false;
  return getAndroidBleRuntimeBridgeState();
}

export async function requestNativeBleStatus(): Promise<Record<string, unknown>> {
  const nativeModule = getNativeBleModule() as
    | {
        getStatus?: () => Promise<Record<string, unknown>>;
        getBleStatus?: () => Promise<Record<string, unknown>>;
        startScan?: () => Promise<Record<string, unknown>>;
      }
    | null;

  if (!nativeModule) {
    return {
      ok: false,
      reason: "MauriMeshBleModule not available.",
    };
  }

  try {
    if (typeof nativeModule.getStatus === "function") {
      return await nativeModule.getStatus();
    }

    if (typeof nativeModule.getBleStatus === "function") {
      return await nativeModule.getBleStatus();
    }

    return {
      ok: true,
      reason: "Native module present, but no status method exposed.",
    };
  } catch (error) {
    return {
      ok: false,
      reason: error instanceof Error ? error.message : String(error),
    };
  }
}

export function getAndroidBleRuntimeProofSnapshot(): {
  bridge: BridgeState;
  summary: ReturnType<typeof getBleProofSummary>;
  events: BleProofEvent[];
} {
  return {
    bridge: getAndroidBleRuntimeBridgeState(),
    summary: getBleProofSummary(),
    events: getBleProofEvents().slice(0, 50),
  };
}
