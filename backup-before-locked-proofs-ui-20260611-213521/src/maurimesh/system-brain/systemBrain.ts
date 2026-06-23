import fs from "fs";
import path from "path";
import { getUiEngineSnapshot, runDemoMessage, ackLastRoute, failLastRoute } from "../ui/mauriUiEngine";
import { MAURIMESH_SYSTEM_LAYERS } from "./layerRegistry";
import { getButtonDecisions, scanMauriButtons } from "./buttonDecisionRouter";
import { SystemEvolutionSnapshot } from "./systemTypes";

const STATE_DIR = path.join(process.cwd(), "maurimesh-runtime-state");
const BRAIN_FILE = path.join(STATE_DIR, "system-brain-snapshot.json");
const BRAIN_LOG = path.join(STATE_DIR, "system-brain.log");

function ensureStateDir() {
  fs.mkdirSync(STATE_DIR, { recursive: true });
}

function appendLog(line: string) {
  ensureStateDir();
  fs.appendFileSync(BRAIN_LOG, `${line}\n`);
}

function writeSnapshot(snapshot: SystemEvolutionSnapshot) {
  ensureStateDir();
  fs.writeFileSync(BRAIN_FILE, JSON.stringify(snapshot, null, 2));
}

export function getSystemBrainSnapshot(): SystemEvolutionSnapshot {
  const engine = getUiEngineSnapshot();
  const buttons = getButtonDecisions();

  const activeLayers = MAURIMESH_SYSTEM_LAYERS.filter((layer) =>
    ["ACTIVE", "WIRED", "LEARNING", "OPTIMISING"].includes(layer.status)
  ).length;

  const connectedButtons = buttons.filter((b) => b.status === "CONNECTED").length;
  const buttonScore = Math.round((connectedButtons / buttons.length) * 100);
  const layerScore = Math.round((activeLayers / MAURIMESH_SYSTEM_LAYERS.length) * 100);
  const learningScore = engine.routeMemoryCount > 0 ? 100 : 60;
  const trustScore = engine.trustCount > 0 ? 100 : 60;
  const ledgerScore = engine.ledgerCount > 0 ? 100 : 60;

  const score = Math.round(
    layerScore * 0.35 +
      buttonScore * 0.25 +
      learningScore * 0.15 +
      trustScore * 0.15 +
      ledgerScore * 0.1
  );

  const recommendations: string[] = [];

  if (engine.ledgerCount === 0) recommendations.push("Run a demo message to activate the ledger.");
  if (engine.routeMemoryCount === 0) recommendations.push("ACK a route to create route learning memory.");
  if (engine.trustCount === 0) recommendations.push("Run ACK/fail route tests to create trust evolution.");
  for (const button of buttons) {
    if (button.status === "MISSING_SCREEN") {
      recommendations.push(`Create missing route ${button.targetRoute} for ${button.buttonTitle}.`);
    }
    if (button.status === "NEEDS_NATIVE_PROOF") {
      recommendations.push(`${button.buttonTitle} is correctly mapped but still needs APK/device proof.`);
    }
  }

  if (recommendations.length === 0) {
    recommendations.push("Replit-side integration is complete. Continue APK/native proof testing.");
  }

  return {
    atMs: Date.now(),
    score,
    summary:
      "System brain is coordinating inventions, UI button decisions, learning state, governance, routing, and completion puller.",
    activeLayers,
    totalLayers: MAURIMESH_SYSTEM_LAYERS.length,
    buttonConnections: buttons,
    layerMap: MAURIMESH_SYSTEM_LAYERS,
    recommendations,
  };
}

export function evolveSystemBrain(): SystemEvolutionSnapshot {
  runDemoMessage("Kia kaha emergency route training message from system brain.");
  ackLastRoute();

  const snapshot = getSystemBrainSnapshot();
  writeSnapshot(snapshot);

  appendLog(
    `[${new Date(snapshot.atMs).toISOString()}] score=${snapshot.score} activeLayers=${snapshot.activeLayers}/${snapshot.totalLayers} buttons=${snapshot.buttonConnections.length}`
  );

  return snapshot;
}

export function stressLearnSystemBrain(): SystemEvolutionSnapshot {
  runDemoMessage("Private tapu route test for trusted delivery only.");
  failLastRoute("System brain stress-learning failure path.");
  runDemoMessage("Whānau check-in route recovery test.");
  ackLastRoute();

  const snapshot = getSystemBrainSnapshot();
  writeSnapshot(snapshot);

  appendLog(
    `[${new Date(snapshot.atMs).toISOString()}] STRESS_LEARN score=${snapshot.score} recommendations=${snapshot.recommendations.length}`
  );

  return snapshot;
}

export function getButtonScanReport() {
  return {
    expected: getButtonDecisions(),
    detected: scanMauriButtons(),
    truth:
      "Button scan checks MauriButton usage and route mapping. It does not rewrite unknown buttons automatically because safe wiring requires preserving original engineering.",
  };
}
