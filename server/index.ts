import express from "express";
import { createMeshGovernanceSim } from "../src/lib/meshGovernanceSim";
import { createGovernanceHistory } from "../src/lib/governanceHistory";

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json());

// [SIMULATION - NOT LIVE BLE] Single shared instance of the real lib routing
// engine, driven on one server-side interval so every client that reads
// /api/mesh/status sees the SAME self-healing / traffic-control activity rather
// than each computing its own numbers. This is development/simulation only and
// does not prove live BLE.
const GOVERNANCE_TICK_MS = 1500;
const GOVERNANCE_HISTORY_LEN = 20;
const governanceSim = createMeshGovernanceSim();
// Rolling window of the last N counter snapshots so clients can render the
// self-heal cycle over time, not just the latest value. Recorded on the same
// single server-side tick that drives the shared counters.
const governanceHistory = createGovernanceHistory(GOVERNANCE_HISTORY_LEN);
governanceHistory.record(governanceSim.tick());
setInterval(
  () => governanceHistory.record(governanceSim.tick()),
  GOVERNANCE_TICK_MS
).unref?.();

/*
 * ============================================================================
 * PROJECT HEALTH REPAIR REPORT (Task #265 — non-destructive cleanup pass)
 * ============================================================================
 * This is a labelling/cleanup pass only. No BLE, routing, ACK, store-forward,
 * messenger, or native files were deleted or restructured. Nothing here proves
 * real BLE — the Replit API is development/simulation only.
 *
 * (a) Files created:
 *     - (none in this pass)
 *
 * (b) Files modified:
 *     - package.json            : stubbed dead scripts that referenced
 *                                 non-existent workspace packages
 *                                 (@workspace/api-server, @workspace/messenger-mobile,
 *                                 @workspace/maurimesh) so they fail loudly with a
 *                                 clear message instead of a confusing pnpm error.
 *                                 Added/kept working "dev" (tsx server/index.ts) and
 *                                 "expo:start" scripts. "mauri:check" now runs only
 *                                 the real typecheck:libs step.
 *     - lib/lib/mesh/ble-bridge.ts : prefixed the bleSend() console.log with
 *                                 "[SIMULATION - NOT LIVE BLE]" so any log reader
 *                                 knows the send did not go over real BLE hardware.
 *                                 Signature, TODO, and logic unchanged.
 *     - server/index.ts         : added this repair report comment.
 *
 * (c) Errors fixed:
 *     - "Start application" workflow was broken (npm run dev had no "dev" script).
 *     - package.json scripts referenced workspace packages that do not exist.
 *     - npx tsc --noEmit exits 0 (kept passing).
 *     - Metro (expo start) boots clean; server runs on port 5000 and
 *       /api/health returns 200.
 *
 * Note: deployment config (Static -> Autoscale) was adjusted in a prior
 * session via the Replit deploy config tool, not in this code diff, so it is
 * not reflected by any file here.
 *
 * (d) Remaining items that REQUIRE a physical Android device or signed APK
 *     (cannot be proven in Replit):
 *     - Real BLE GATT characteristic write in lib/lib/mesh/ble-bridge.ts
 *       (currently a simulation console.log).
 *     - Two-phone delivery/ACK proof over real BLE radios.
 *     - EAS production / signed APK build and on-device install.
 * ============================================================================
 */

app.get("/", (_req, res) => {
  res.status(200).json({
    ok: true,
    service: "maurimesh-replit-api",
    truth: "[SIMULATION - NOT LIVE BLE] Replit API is development/simulation only. It does not prove live BLE.",
    endpoints: ["/api/health", "/api/mesh/status"],
  });
});

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "maurimesh-replit-api",
    mode: "development",
    truth: "[SIMULATION - NOT LIVE BLE] Replit API is development only. It does not prove live BLE.",
  });
});

app.get("/api/mesh/status", (_req, res) => {
  res.json({
    mode: "SIMULATION",
    truth: "[SIMULATION - NOT LIVE BLE] Replit API simulation only. Not live BLE.",
    governance: governanceSim.read(),
    governanceHistory: governanceHistory.read(),
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
