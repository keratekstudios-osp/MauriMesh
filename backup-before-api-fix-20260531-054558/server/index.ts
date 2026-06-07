import express from "express";
import fs from "fs";
import path from "path";
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
import {
  evolveSystemBrain,
  getButtonScanReport,
  getSystemBrainSnapshot,
  stressLearnSystemBrain,
} from "../src/maurimesh/system-brain/systemBrain";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

function readRuntimeJson(name: string) {
  const file = path.join(process.cwd(), "maurimesh-runtime-state", name);
  if (!fs.existsSync(file)) return null;
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return null;
  }
}

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "Replit API is development only. Native BLE requires APK and physical devices.",
  });
});

app.get("/api/system-brain/status", (_req, res) => {
  res.json(getSystemBrainSnapshot());
});

app.post("/api/system-brain/evolve", (_req, res) => {
  res.json(evolveSystemBrain());
});

app.post("/api/system-brain/stress-learn", (_req, res) => {
  res.json(stressLearnSystemBrain());
});

app.get("/api/system-brain/buttons", (_req, res) => {
  res.json(getButtonScanReport());
});

app.get("/api/living-runtime/status", (_req, res) => {
  res.json({
    memory: readRuntimeJson("living-runtime-memory.json"),
    snapshot: readRuntimeJson("living-runtime-snapshot.json"),
    systemBrain: readRuntimeJson("system-brain-snapshot.json"),
    truth:
      "Living runtime proves Replit-side self-learning and routing logic only. Native BLE requires APK and physical devices.",
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
