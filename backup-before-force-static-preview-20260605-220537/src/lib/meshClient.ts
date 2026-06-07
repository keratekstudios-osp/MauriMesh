import { apiGet } from "./api";

export type SimNode = {
  id: string;
  label: string;
  status: "online" | "relay" | "offline";
  signal: number;
  x: number;
  y: number;
};

export type SimRoute = {
  from: string;
  to: string;
  quality: number;
};

export type MeshStatus = {
  mode: "LIVE" | "SIMULATION" | "UNAVAILABLE";
  message: string;
  nodes: SimNode[];
  routes: SimRoute[];
};

const fallbackNodes: SimNode[] = [
  { id: "A", label: "Phone A", status: "online", signal: 96, x: 18, y: 30 },
  { id: "B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
  { id: "C", label: "Phone C", status: "online", signal: 74, x: 78, y: 28 },
  { id: "D", label: "Store Forward D", status: "offline", signal: 31, x: 66, y: 78 }
];

const fallbackRoutes: SimRoute[] = [
  { from: "A", to: "B", quality: 92 },
  { from: "B", to: "C", quality: 84 },
  { from: "B", to: "D", quality: 38 }
];

export async function getMeshStatus(): Promise<MeshStatus> {
  const result = await apiGet<{
    nodes?: SimNode[];
    routes?: SimRoute[];
  }>("/api/mesh/status");

  if (result.ok) {
    return {
      mode: "LIVE",
      message: "Connected to Mesh API.",
      nodes: result.data.nodes || fallbackNodes,
      routes: result.data.routes || fallbackRoutes
    };
  }

  return {
    mode: "SIMULATION",
    message:
      "Static Replit preview is running. Mesh API is unavailable, so MauriMesh is showing labelled simulation fallback.",
    nodes: fallbackNodes,
    routes: fallbackRoutes
  };
}
