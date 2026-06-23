const DEFAULT_TIMEOUT_MS = 6000;

export type ApiResult<T> =
  | { ok: true; data: T; source: "live" }
  | { ok: false; error: string; source: "unavailable" };

export const API_BASE =
  process.env.EXPO_PUBLIC_MESH_API_URL ||
  process.env.REACT_APP_MESH_API_URL ||
  "";

export async function apiGet<T>(
  path: string,
  timeoutMs = DEFAULT_TIMEOUT_MS
): Promise<ApiResult<T>> {
  if (!API_BASE) {
    return {
      ok: false,
      error: "Mesh API URL is not configured.",
      source: "unavailable",
    };
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const res = await fetch(`${API_BASE}${path}`, {
      method: "GET",
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!res.ok) {
      return {
        ok: false,
        error: `Mesh API returned HTTP ${res.status}.`,
        source: "unavailable",
      };
    }

    const data = (await res.json()) as T;
    return { ok: true, data, source: "live" };
  } catch (err) {
    clearTimeout(timeout);
    return {
      ok: false,
      error: err instanceof Error ? err.message : "Unknown API error.",
      source: "unavailable",
    };
  }
}

export async function apiPost<T>(
  path: string,
  body: unknown,
  timeoutMs = DEFAULT_TIMEOUT_MS
): Promise<ApiResult<T>> {
  if (!API_BASE) {
    return {
      ok: false,
      error: "Mesh API URL is not configured.",
      source: "unavailable",
    };
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const res = await fetch(`${API_BASE}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!res.ok) {
      return {
        ok: false,
        error: `Mesh API returned HTTP ${res.status}.`,
        source: "unavailable",
      };
    }

    const data = (await res.json()) as T;
    return { ok: true, data, source: "live" };
  } catch (err) {
    clearTimeout(timeout);
    return {
      ok: false,
      error: err instanceof Error ? err.message : "Unknown API error.",
      source: "unavailable",
    };
  }
}
