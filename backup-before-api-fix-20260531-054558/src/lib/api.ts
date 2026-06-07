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
  if (result.ok) {
    return {
      mode: "LIVE",
      message: "Connected to Mesh API.",
      nodes: result.data.nodes || [],
      routes: result.data.routes || []
    };
  }

  return {
    mode: "SIMULATION",
    message: "Mesh API unavailable in Replit preview. Showing labelled simulation only.",
    nodes: simulatedNodes,
    routes: simulatedRoutes
  };
}
