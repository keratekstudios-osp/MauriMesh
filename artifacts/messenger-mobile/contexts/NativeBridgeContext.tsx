import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import {
  sendNativeRuntimeAttestation,
  TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER,
} from "../src/lib/nativeRuntimeAttestationClient";

type NativeBridgeContextValue = {
  marker: string;
  attempted: boolean;
  accepted: boolean;
  proofCapable: boolean;
  error?: string;
  refresh: () => Promise<void>;
};

const NativeBridgeContext = createContext<NativeBridgeContextValue>({
  marker: TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER,
  attempted: false,
  accepted: false,
  proofCapable: false,
  refresh: async () => {},
});

export function NativeBridgeProvider({ children }: { children: React.ReactNode }) {
  const [attempted, setAttempted] = useState(false);
  const [accepted, setAccepted] = useState(false);
  const [proofCapable, setProofCapable] = useState(false);
  const [error, setError] = useState<string | undefined>();

  async function refresh() {
    setAttempted(true);
    const result = await sendNativeRuntimeAttestation();
    setAccepted(Boolean(result.accepted));
    setProofCapable(Boolean(result.proofCapable));
    setError(result.error);
  }

  useEffect(() => {
    refresh();
    const timer = setInterval(refresh, 30000);
    return () => clearInterval(timer);
  }, []);

  const value = useMemo(
    () => ({
      marker: TASK_223_NATIVE_ATTESTATION_CLIENT_MARKER,
      attempted,
      accepted,
      proofCapable,
      error,
      refresh,
    }),
    [attempted, accepted, proofCapable, error]
  );

  return (
    <NativeBridgeContext.Provider value={value}>
      {children}
    </NativeBridgeContext.Provider>
  );
}

export function useNativeBridgeAttestation() {
  return useContext(NativeBridgeContext);
}
