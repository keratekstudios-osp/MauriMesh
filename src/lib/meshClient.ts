import { apiGet } from "./api";
import { simulatedNodes, simulatedRoutes, SimNode, SimRoute } from "./simulation";

export type MeshStatus = {
  mode: "LIVE" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  nodes: SimNode[];
  routes: SimRoute[];
};

export async function getMeshStatus(): Promise<MeshStatus> {
  const result = await apiGet<{
    mode?: string;
    truth?: string;
    nodes?: SimNode[];
    routes?: SimRoute[];
  }>("/api/mesh/status");

  if (result.ok) {
    // The Replit API is development/simulation only — it returns mode "SIMULATION".
    // Never present that as "LIVE": honour the backend's declared mode so a
    // reachable API never makes simulated data look like real BLE.
    const isSimulation = result.data.mode === "SIMULATION";
    return {
      mode: isSimulation ? "SIMULATION" : "LIVE",
      message: isSimulation
        ? `[SIMULATION] ${result.data.truth ?? "Mesh API simulation only. This is not live BLE."}`
        : "Connected to Mesh API.",
      nodes: result.data.nodes || [],
      routes: result.data.routes || [],
    };
  }

  return {
    mode: "SIMULATION",
    message:
      "[SIMULATION] Mesh API unavailable in APK/Replit preview. Showing labelled simulation only. This is not live BLE.",
    nodes: simulatedNodes,
    routes: simulatedRoutes,
  };
}
