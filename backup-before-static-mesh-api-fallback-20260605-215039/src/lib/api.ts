const DEFAULT_TIMEOUT_MS = 6000;

export type ApiResult<T> =
  | { ok: true; data: T; source: "live" }
  | { ok: false; error: string; source: "unavailable" };

function getApiBase(): string {
  const envBase =
    process.env.EXPO_PUBLIC_MESH_API_URL ||
    process.env.EXPO_PUBLIC_API_BASE_URL ||
    process.env.EXPO_PUBLIC_BACKEND_BASE_URL ||
    process.env.VITE_API_BASE_URL ||
    process.env.VITE_BACKEND_BASE_URL ||
    process.env.API_BASE_URL ||
    process.env.BACKEND_BASE_URL ||
    "";

  if (envBase) return envBase;

  if (typeof window !== "undefined" && window.location?.origin) {
    return window.location.origin;
  }

  return "";
}

export const API_BASE = getApiBase();

export async function apiGet<T>(
  path: string,
  timeoutMs = DEFAULT_TIMEOUT_MS
): Promise<ApiResult<T>> {
  if (!API_BASE) {
    return {
      ok: false,
      error: "Mesh API URL is not configured.",
      source: "unavailable"
    };
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const cleanBase = API_BASE.replace(/\/$/, "");
    const cleanPath = path.startsWith("/") ? path : `/${path}`;

    const res = await fetch(`${cleanBase}${cleanPath}`, {
      method: "GET",
      signal: controller.signal
    });

    clearTimeout(timeout);

    if (!res.ok) {
      return {
        ok: false,
        error: `Mesh API returned HTTP ${res.status}.`,
        source: "unavailable"
      };
    }

    const data = (await res.json()) as T;
    return { ok: true, data, source: "live" };
  } catch (err) {
    clearTimeout(timeout);
    return {
      ok: false,
      error: err instanceof Error ? err.message : "Unknown API error.",
      source: "unavailable"
    };
  }
}
