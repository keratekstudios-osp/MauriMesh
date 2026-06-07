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
    // The Replit HTTP API is development/simulation only. Reaching it NEVER
    // proves live BLE, whatever "mode" it reports — an HTTP response is not a
    // trusted native/live transport proof. Always label this data as
    // simulation so a reachable API can never masquerade as real BLE.
    return {
      mode: "SIMULATION",
      message: `[SIMULATION] ${result.data.truth ?? "Mesh API simulation only. This is not live BLE."}`,
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
