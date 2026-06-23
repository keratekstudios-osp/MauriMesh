import { planBuildAction } from "../builder/builderPlanner";
import { verifyLayer } from "../builder/verificationGate";
import { createCorePacket } from "../packet/packetEngine";
import { planRoute } from "../routing/routingEngine";
import { createProofRecord } from "../proof/proofLedger";
import { getGovernanceDashboardData } from "../dashboard/governanceDashboard";
import { createRepairPlan } from "../healing/homeostasis";

export function runMauriCoreSmokeTest() {
  createProofRecord({
    layerId: "core_constitution",
    action: "MauriCore smoke test start",
    result: "pass",
    evidence: ["smoke_test"],
    confidence: 0.9,
  });

  const decision = planBuildAction("Improve layer: routing_intelligence");

  const packet = createCorePacket({
    senderId: "PHONE_A",
    recipientId: "PHONE_B",
    payload: { text: "MauriCore test packet" },
  });

  const route = planRoute({
    from: "PHONE_A",
    to: "PHONE_B",
    nodes: [
      { id: "PHONE_A", label: "Phone A", trust: 0.95, battery: 0.8, signal: 0.9, online: true },
      { id: "PHONE_B", label: "Phone B", trust: 0.9, battery: 0.75, signal: 0.85, online: true },
    ],
    edges: [
      {
        from: "PHONE_A",
        to: "PHONE_B",
        transport: "BLE",
        latencyMs: 80,
        ackSuccess: 0.9,
        privacyRisk: 0.1,
        batteryCost: 0.2,
      },
    ],
  });

  const repair = createRepairPlan("smoke_test_health_check", {
    heartbeat: true,
    apiHealth: 0.9,
    bleHealth: 0.6,
    ackSuccessRate: 0.9,
    routingStability: 0.8,
    memoryIntegrity: 0.9,
    batteryLevel: 0.8,
    crashCount: 0,
    proofIntegrity: 0.9,
  });

  const verification = verifyLayer("core_constitution");
  const dashboard = getGovernanceDashboardData();

  return {
    ok: decision.status !== "blocked" && packet.packetId.length > 0 && route.allowed && verification.ok,
    decision,
    packet,
    route,
    repair,
    verification,
    dashboardSummary: {
      proofChainOk: dashboard.core.proofChainOk,
      layers: dashboard.layers.length,
      canBuildApk: dashboard.build.canBuildApk,
    },
  };
}
