import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";
import {
  clearStoredBackendUrl,
  getStoredBackendUrl,
  normalizeUrl,
  pingBackend,
  saveBackendUrl,
  type PingResult,
} from "@/lib/backendConfig";
import { setRuntimeApiBase } from "@/src/lib/api";

export type BackendStatus = "idle" | "checking" | "connected" | "error";

export interface BackendConfigState {
  url: string;
  status: BackendStatus;
  latencyMs: number | null;
  version: string | null;
  errorMessage: string;
  isConfigured: boolean;
  saveAndConnect: (rawUrl: string) => Promise<PingResult>;
  disconnect: () => Promise<void>;
  retest: () => Promise<void>;
}

const DEFAULT_STATE: BackendConfigState = {
  url: "",
  status: "idle",
  latencyMs: null,
  version: null,
  errorMessage: "",
  isConfigured: false,
  saveAndConnect: async () => ({ ok: false, error: "Not ready" }),
  disconnect: async () => {},
  retest: async () => {},
};

const BackendConfigContext = createContext<BackendConfigState>(DEFAULT_STATE);

export function BackendConfigProvider({ children }: { children: React.ReactNode }) {
  const [url, setUrl] = useState("");
  const [status, setStatus] = useState<BackendStatus>("idle");
  const [latencyMs, setLatencyMs] = useState<number | null>(null);
  const [version, setVersion] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState("");

  const applyUrl = useCallback(async (target: string): Promise<PingResult> => {
    if (!target) {
      setRuntimeApiBase("");
      setStatus("idle");
      setLatencyMs(null);
      setVersion(null);
      setErrorMessage("");
      return { ok: false, error: "No URL" };
    }
    setRuntimeApiBase(target);
    setStatus("checking");
    setLatencyMs(null);
    setVersion(null);
    setErrorMessage("");
    const result = await pingBackend(target);
    if (result.ok) {
      setStatus("connected");
      setLatencyMs(result.latencyMs ?? null);
      setVersion(result.version ?? null);
      setErrorMessage("");
    } else {
      setStatus("error");
      setLatencyMs(null);
      setVersion(null);
      setErrorMessage(result.error ?? "Connection failed");
    }
    return result;
  }, []);

  useEffect(() => {
    getStoredBackendUrl().then((stored) => {
      if (stored) {
        setUrl(stored);
        applyUrl(stored);
      }
    });
  }, []);

  const saveAndConnect = useCallback(async (rawUrl: string): Promise<PingResult> => {
    const normalized = normalizeUrl(rawUrl);
    setUrl(normalized);
    if (normalized) {
      await saveBackendUrl(normalized);
    } else {
      await clearStoredBackendUrl();
    }
    return applyUrl(normalized);
  }, [applyUrl]);

  const disconnect = useCallback(async () => {
    await clearStoredBackendUrl();
    setUrl("");
    setRuntimeApiBase("");
    setStatus("idle");
    setLatencyMs(null);
    setVersion(null);
    setErrorMessage("");
  }, []);

  const retest = useCallback(async () => {
    if (url) await applyUrl(url);
  }, [url, applyUrl]);

  return (
    <BackendConfigContext.Provider
      value={{
        url,
        status,
        latencyMs,
        version,
        errorMessage,
        isConfigured: status === "connected",
        saveAndConnect,
        disconnect,
        retest,
      }}
    >
      {children}
    </BackendConfigContext.Provider>
  );
}

export function useBackendConfig(): BackendConfigState {
  return useContext(BackendConfigContext);
}
