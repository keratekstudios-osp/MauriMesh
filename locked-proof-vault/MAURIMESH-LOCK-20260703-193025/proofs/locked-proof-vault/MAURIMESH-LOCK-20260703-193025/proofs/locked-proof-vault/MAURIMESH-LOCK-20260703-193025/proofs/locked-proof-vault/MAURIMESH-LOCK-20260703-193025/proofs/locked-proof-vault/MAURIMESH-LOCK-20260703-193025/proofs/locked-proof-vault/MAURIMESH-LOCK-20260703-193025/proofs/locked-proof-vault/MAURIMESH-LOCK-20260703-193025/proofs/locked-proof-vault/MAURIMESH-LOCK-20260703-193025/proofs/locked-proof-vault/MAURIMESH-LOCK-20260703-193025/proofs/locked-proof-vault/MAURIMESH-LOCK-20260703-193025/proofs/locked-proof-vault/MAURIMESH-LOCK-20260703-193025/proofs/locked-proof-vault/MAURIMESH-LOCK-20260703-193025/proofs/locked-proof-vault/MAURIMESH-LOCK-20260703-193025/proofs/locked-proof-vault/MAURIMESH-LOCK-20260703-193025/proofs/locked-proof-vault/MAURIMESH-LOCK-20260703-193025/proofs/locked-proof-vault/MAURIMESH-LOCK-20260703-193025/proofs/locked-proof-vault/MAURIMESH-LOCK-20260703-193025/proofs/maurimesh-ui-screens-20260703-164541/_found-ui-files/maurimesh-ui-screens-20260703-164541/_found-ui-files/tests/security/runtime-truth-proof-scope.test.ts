import { describe, it, expect } from "vitest";
import {
  markRealNative,
  getRuntimeTruthState,
  runtimeTruthEngine,
  type NativeRuntimeAttestation,
} from "../../artifacts/api-server/src/runtime/RuntimeTruthEngine";

const validAttestation: NativeRuntimeAttestation = {
  source: "native-android-bridge",
  platform: "android",
  nativeModulePresent: true,
  features: ["native_bridge", "ble_scan"],
};

// Regression guard for the proof-scope self-promotion bypass:
// proof scope ("real_native") must ONLY be reachable via a validated native
// attestation. No code path may promote without one.
describe("RuntimeTruthEngine proof-scope promotion guard", () => {
  it("does NOT promote to real_native when called with no attestation", () => {
    const state = markRealNative(["native_bridge", "ble_scan"]);
    expect(state.mode).not.toBe("real_native");
    expect(state.proofCapable).toBe(false);
    expect(getRuntimeTruthState().proofCapable).toBe(false);
  });

  it("does NOT promote with a simulation-sourced attestation", () => {
    const bad: NativeRuntimeAttestation = {
      source: "simulation",
      platform: "android",
      nativeModulePresent: true,
      features: ["native_bridge"],
    };
    const state = markRealNative(["native_bridge"], bad);
    expect(state.mode).not.toBe("real_native");
    expect(state.proofCapable).toBe(false);
  });

  it("does NOT promote when the attestation lacks the native_bridge feature", () => {
    const bad: NativeRuntimeAttestation = {
      source: "native",
      platform: "android",
      nativeModulePresent: true,
      features: ["ble_scan"],
    };
    const state = markRealNative(["ble_scan"], bad);
    expect(state.proofCapable).toBe(false);
  });

  it("verify() alone never promotes proof scope", () => {
    const state = runtimeTruthEngine.verify("native_bridge");
    expect(state.mode).not.toBe("real_native");
    expect(state.proofCapable).toBe(false);
  });

  it("promotes to real_native ONLY with a valid native attestation", () => {
    const state = runtimeTruthEngine.acceptNativeAttestation(validAttestation);
    expect(state.mode).toBe("real_native");
    expect(state.proofCapable).toBe(true);
  });
});
