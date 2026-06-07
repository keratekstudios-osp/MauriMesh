import express from "express";
import {
  getUiEngineSnapshot,
  runDemoMessage,
  sendUiMessage,
  ackLastRoute,
  failLastRoute,
} from "../src/maurimesh/ui/mauriUiEngine";
import {
  getMauriCompletionAudit,
  MAURIMESH_INVENTION_REGISTER,
} from "../src/lib/mauriEssentials";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "Replit API is development only. Native BLE requires APK and physical devices.",
  });
});

app.get("/api/mesh/status", (_req, res) => {
  const snapshot = getUiEngineSnapshot();

  res.json({
    mode: snapshot.mode,
    truth: snapshot.message,
    nodes: snapshot.nodes,
    routes: snapshot.routes,
    ledgerCount: snapshot.ledgerCount,
    trustCount: snapshot.trustCount,
    routeMemoryCount: snapshot.routeMemoryCount,
    lastResult: snapshot.lastResult,
  });
});

app.get("/api/invention/status", (_req, res) => {
  res.json(getUiEngineSnapshot());
});

app.get("/api/invention/register", (_req, res) => {
  res.json({
    count: MAURIMESH_INVENTION_REGISTER.length,
    inventions: MAURIMESH_INVENTION_REGISTER,
  });
});

app.get("/api/invention/audit", (_req, res) => {
  res.json(getMauriCompletionAudit());
});

app.post("/api/invention/demo", (req, res) => {
  const body =
    typeof req.body?.body === "string"
      ? req.body.body
      : "Kia kaha, emergency help message through MauriMesh.";

  runDemoMessage(body);
  res.json(getUiEngineSnapshot());
});

app.post("/api/invention/send", (req, res) => {
  const body =
    typeof req.body?.body === "string"
      ? req.body.body
      : "MauriMesh test message.";

  sendUiMessage({
    from: typeof req.body?.from === "string" ? req.body.from : "PHONE_A",
    to: typeof req.body?.to === "string" ? req.body.to : "PHONE_C",
    body,
  });

  res.json(getUiEngineSnapshot());
});

app.post("/api/invention/ack", (_req, res) => {
  ackLastRoute();
  res.json(getUiEngineSnapshot());
});

app.post("/api/invention/fail", (_req, res) => {
  failLastRoute("API-triggered failure simulation.");
  res.json(getUiEngineSnapshot());
});

app.listen(port, "0.0.0.0", () => {
  console.log(`[MauriMesh] Replit API running on port ${port}`);
});
