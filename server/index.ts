import express from "express";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "Replit API is development only. It does not prove live BLE.",
  });
});

app.get("/api/mesh/status", (_req, res) => {
  res.json({
    mode: "SIMULATION",
    truth: "Replit API simulation only. Not live BLE.",
    nodes: [
      { id: "A", label: "Device A", status: "online", signal: 96, x: 18, y: 30 },
      { id: "B", label: "Relay B", status: "relay", signal: 82, x: 48, y: 54 },
      { id: "C", label: "Device C", status: "online", signal: 74, x: 78, y: 28 },
      { id: "D", label: "Stored D", status: "offline", signal: 31, x: 66, y: 78 },
    ],
    routes: [
      { from: "A", to: "B", quality: 92 },
      { from: "B", to: "C", quality: 84 },
      { from: "B", to: "D", quality: 38 },
    ],
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`[MauriMesh] Replit API running on port ${port}`);
});
