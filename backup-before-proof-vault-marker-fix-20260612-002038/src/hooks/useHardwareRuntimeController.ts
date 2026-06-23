import { useEffect, useState } from "react";
import {
  BleRuntimeTuning,
  createBleRuntimeTuning,
  createProofRuntimeTuning,
  evaluateHardwareRuntimeController,
  HardwareRuntimeControllerState,
  ProofRuntimeTuning,
} from "../maurimesh/device-hardware";

export type HardwareRuntimeHookState = {
  loading: boolean;
  state: HardwareRuntimeControllerState | null;
  ble: BleRuntimeTuning | null;
  proof: ProofRuntimeTuning | null;
  refresh: () => Promise<void>;
};

export function useHardwareRuntimeController(): HardwareRuntimeHookState {
  const [loading, setLoading] = useState(true);
  const [state, setState] = useState<HardwareRuntimeControllerState | null>(null);
  const [ble, setBle] = useState<BleRuntimeTuning | null>(null);
  const [proof, setProof] = useState<ProofRuntimeTuning | null>(null);

  async function refresh() {
    setLoading(true);
    const next = await evaluateHardwareRuntimeController();
    setState(next);
    setBle(createBleRuntimeTuning(next));
    setProof(createProofRuntimeTuning(next));
    setLoading(false);
  }

  useEffect(() => {
    refresh();
  }, []);

  return {
    loading,
    state,
    ble,
    proof,
    refresh,
  };
}
