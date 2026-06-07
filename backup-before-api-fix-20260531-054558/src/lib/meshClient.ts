import { apiGet } from "./api";
import { simulatedNodes, simulatedRoutes, SimNode, SimRoute } from "./simulation";
import { getUiEngineSnapshot } from "../maurimesh/ui/mauriUiEngine";

export type MeshStatus = {
  mode: "LIVE" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  nodes: SimNode[];
  routes: SimRoute[];
};

export async function getMeshStatus(): Promise<MeshStatus> {
  const engineSnapshot = getUiEngineSnapshot();

  if (engineSnapshot.nodes.length > 0) {
    return {
      mode: "LIVE",
      message:
        "Local MauriMesh invention engine is active in Replit UI. Native BLE still requires APK/device proof.",
      nodes: engineSnapshot.nodes,
      routes: engineSnapshot.routes,
    };
  }

  const result = await apiGet<{
    nodes?: SimNode[];
    routes?: SimRoute[];
  }>("/api/mesh/status");

  if (result.ok) {
    return {
      mode: "LIVE",
      message: "Connected to Mesh API.",
      nodes: result.data.nodes || [],
      routes: result.data.routes || [],
    };
  }

  return {
    mode: "SIMULATION",
    message:
      "Mesh API unavailable in Replit preview. Showing labelled simulation only.",
    nodes: simulatedNodes,
    routes: simulatedRoutes,
  };
}
