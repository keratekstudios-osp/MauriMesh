import {
  getAndroidBleRuntimeBridgeState,
  getAndroidBleRuntimeProofSnapshot,
  startAndroidBleRuntimeBridge,
} from "../bridges/androidBleRuntimeBridge";

export function getBleRuntimeBridgeDashboardData() {
  const started = startAndroidBleRuntimeBridge();
  const snapshot = getAndroidBleRuntimeProofSnapshot();

  return {
    started,
    bridge: getAndroidBleRuntimeBridgeState(),
    summary: snapshot.summary,
    events: snapshot.events,
    acceptance: {
      nativeModulePresent: snapshot.bridge.nativeModulePresent,
      eventListenerActive: snapshot.bridge.listening,
      hasProofEvents: snapshot.summary.total > 0,
      readyForPhysicalProof:
        snapshot.bridge.nativeModulePresent && snapshot.bridge.listening,
    },
  };
}
