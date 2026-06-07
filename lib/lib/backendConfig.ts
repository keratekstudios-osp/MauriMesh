import AsyncStorage from "@react-native-async-storage/async-storage";

const STORAGE_KEY = "maurimesh_backend_url_v1";

export function normalizeUrl(raw: string): string {
  return raw.trim().replace(/\/+$/, "");
}

export async function getStoredBackendUrl(): Promise<string | null> {
  try {
    return await AsyncStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
}

export async function saveBackendUrl(url: string): Promise<void> {
  try {
    await AsyncStorage.setItem(STORAGE_KEY, normalizeUrl(url));
  } catch {}
}

export async function clearStoredBackendUrl(): Promise<void> {
  try {
    await AsyncStorage.removeItem(STORAGE_KEY);
  } catch {}
}

export interface PingResult {
  ok: boolean;
  latencyMs?: number;
  error?: string;
  version?: string;
}

export async function pingBackend(url: string, timeoutMs = 8000): Promise<PingResult> {
  const base = normalizeUrl(url);
  if (!base) return { ok: false, error: "No URL provided" };

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  const start = Date.now();

  try {
    const res = await fetch(`${base}/api/healthz`, {
      method: "GET",
      signal: controller.signal,
      headers: { Accept: "application/json" },
    });
    clearTimeout(timer);
    const latencyMs = Date.now() - start;
    if (!res.ok) return { ok: false, error: `HTTP ${res.status}`, latencyMs };
    let version: string | undefined;
    try {
      const body = await res.json();
      version = body?.version ?? body?.v ?? undefined;
    } catch {}
    return { ok: true, latencyMs, version };
  } catch (err) {
    clearTimeout(timer);
    const msg = err instanceof Error ? err.message : "Connection failed";
    const isTimeout = msg.includes("abort") || msg.toLowerCase().includes("timeout");
    return { ok: false, error: isTimeout ? "Request timed out — check host and port" : msg };
  }
}
