import { apiGet } from "./api";
import { simulatedNodes, simulatedRoutes, SimNode, SimRoute } from "./simulation";

export type MeshStatus = {
  mode: "LIVE" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  nodes: SimNode[];
  routes: SimRoute[];
};

async function getLocalEngineStatus(): Promise<MeshStatus | null> {
  try {
    const mod = await import("../maurimesh/ui/mauriUiEngine");
    const snapshot = mod.getUiEngineSnapshot();

    if (snapshot?.nodes?.length) {
      return {
        mode: "LIVE",
        message:
          "MauriMesh local invention engine is active. API connection is not required for Replit UI proof.",
        nodes: snapshot.nodes as SimNode[],
        routes: snapshot.routes as SimRoute[],
      };
    }
  } catch {
    // Engine bridge not installed yet. Continue to API/simulation fallback.
  }

  return null;
}

export async function getMeshStatus(): Promise<MeshStatus> {
  const local = await getLocalEngineStatus();
  if (local) return local;

  const result = await apiGet<{
    nodes?: SimNode[];
    routes?: SimRoute[];
    truth?: string;
    message?: string;
  }>("/api/mesh/status");

  if (result.ok) {
    return {
      mode: "LIVE",
      message:
        result.data.truth ||
        result.data.message ||
        "Connected to MauriMesh API.",
      nodes: result.data.nodes || [],
      routes: result.data.routes || [],
    };
  }

  return {
    mode: "SIMULATION",
    message:
      "Mesh API unavailable. Showing safe simulation fallback so UI stays connected.",
    nodes: simulatedNodes,
    routes: simulatedRoutes,
  };
}
