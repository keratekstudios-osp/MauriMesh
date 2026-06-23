import { MauriMeshExamResult, MauriMeshProofSignal } from "../types";
import { mauriMeshProofVerdict, REQUIRED_3_DEVICE_EVENTS, REQUIRED_STORE_FORWARD_EVENTS } from "../proof/proofVerdict";
import { mauriMeshTikangaGovernance } from "../governance/tikangaGovernance";
import { mauriMeshSelfHealingPlan } from "../resilience/selfHealing";
import { mauriMeshChooseBestRoute, mauriMeshScoreRoute } from "../routing/routeScoring";

function check(id: string, label: string, passed: boolean, evidence: string) {
  return { id, label, passed, evidence };
}

export function mauriMeshRunUnifiedExam(input: {
  packetId: string;
  proofType: "3_DEVICE" | "STORE_FORWARD" | "NATIVE_BLE_GATT";
  signals: MauriMeshProofSignal[];
  vaultStored: boolean;
  dashboardStable: boolean;
  userApprovedExam: boolean;
  adbOnline?: boolean;
  appOpened?: boolean;
  routeGlitch?: boolean;
}): MauriMeshExamResult {
  const requiredEvents =
    input.proofType === "STORE_FORWARD" ? REQUIRED_STORE_FORWARD_EVENTS : REQUIRED_3_DEVICE_EVENTS;

  const proof = mauriMeshProofVerdict({
    packetId: input.packetId,
    signals: input.signals,
    requiredEvents,
  });

  const governance = mauriMeshTikangaGovernance({
    packetId: input.packetId,
    proofType: input.proofType,
    claimsNativeBleGattPass: input.proofType === "NATIVE_BLE_GATT",
    hasNativeBleGattEvidence: proof.nativeBleGattPacketBoundPass,
    storesProof: input.vaultStored,
    userApprovedExam: input.userApprovedExam,
  });

  const resilience = mauriMeshSelfHealingPlan({
    adbOnline: input.adbOnline ?? true,
    appOpened: input.appOpened ?? true,
    dashboardStable: input.dashboardStable,
    vaultStable: input.vaultStored,
    packetIdMatched: proof.missingEvents.length === 0,
    nativeBleGattSeen: proof.nativeBleGattPacketBoundPass,
    routeGlitch: input.routeGlitch ?? false,
  });

  const routes = [
    mauriMeshScoreRoute({
      id: "route_ble_relay",
      path: ["A06", "S10", "A16", "S10", "A06"],
      transport: proof.nativeBleGattPacketBoundPass ? "BLE_GATT" : "BLE_SCREEN_WORKFLOW",
      latencyMs: 25,
      trust: input.vaultStored ? 75 : 50,
      resilience: resilience.health === "GREEN" ? 90 : resilience.health === "AMBER" ? 65 : 35,
      governance: governance.decision === "APPROVED" ? 90 : governance.decision === "APPROVED_WITH_WARNING" ? 70 : 35,
      congestion: 10,
    }),
    mauriMeshScoreRoute({
      id: "route_store_forward",
      path: ["A06", "S10_STORE", "A16_RETURN", "S10_ACK", "A06"],
      transport: "STORE_FORWARD",
      latencyMs: 45,
      trust: input.vaultStored ? 80 : 55,
      resilience: 85,
      governance: 85,
      congestion: 15,
    }),
  ];

  const bestRoute = mauriMeshChooseBestRoute(routes);

  const checks = [
    check("dashboard", "Safe Dashboard opens", input.dashboardStable, input.dashboardStable ? "Dashboard stable." : "Dashboard unstable."),
    check("packet-path", "Required packet path complete", proof.missingEvents.length === 0, proof.missingEvents.length ? `Missing: ${proof.missingEvents.join(", ")}` : "All required events found."),
    check("exam-approved", "Exam approved by workflow", input.userApprovedExam, input.userApprovedExam ? "EXAM_APPROVED present/user approved." : "Exam approval missing."),
    check("vault", "Local proof vault storage confirmed", input.vaultStored, input.vaultStored ? "Proof key found in storage." : "Proof key missing from storage."),
    check("governance", "Governance permits claim", governance.decision !== "REFUSED", governance.reason),
    check("resilience", "Self-healing has a plan", resilience.health !== "RED" || resilience.recoveryPlan.length > 0, resilience.recoveryPlan.join(" | ") || "No recovery needed."),
    check("route", "Best route selected", Boolean(bestRoute), `${bestRoute.id} score=${bestRoute.finalScore} decision=${bestRoute.decision}`),
    check(
      "native-truth",
      "Native BLE/GATT truth protected",
      input.proofType !== "NATIVE_BLE_GATT" || proof.nativeBleGattPacketBoundPass,
      proof.nativeBleGattPacketBoundPass
        ? "Native BLE/GATT packet-bound proof confirmed."
        : "Native BLE/GATT PASS not claimed."
    ),
  ];

  const passed = checks.every((item) => item.passed);
  const score = Math.round((checks.filter((item) => item.passed).length / checks.length) * 100);

  return {
    examId: `MM-UNIFIED-EXAM-${Date.now()}`,
    name: "MauriMesh Unified Intelligence Spine Exam",
    passed,
    decision: passed ? "APPROVED" : score >= 70 ? "APPROVED_WITH_WARNING" : "REVIEW_REQUIRED",
    truthClass: proof.truthClass,
    score,
    checks,
  };
}
