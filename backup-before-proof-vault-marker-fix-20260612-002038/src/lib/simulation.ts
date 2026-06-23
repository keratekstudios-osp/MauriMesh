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

export const simulatedNodes: SimNode[] = [
  { id: "A", label: "Device A", status: "online", signal: 96, x: 18, y: 30 },
  { id: "B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
  { id: "C", label: "Device C", status: "online", signal: 74, x: 78, y: 28 },
  { id: "D", label: "Stored D", status: "offline", signal: 31, x: 66, y: 78 },
];

export const simulatedRoutes: SimRoute[] = [
  { from: "A", to: "B", quality: 92 },
  { from: "B", to: "C", quality: 84 },
  { from: "B", to: "D", quality: 38 },
];
