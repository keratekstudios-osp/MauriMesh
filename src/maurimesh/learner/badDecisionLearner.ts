import { RecoveryPlan, RouteDecision } from "./types";

export function learnFromBadDecision(decision: RouteDecision): RecoveryPlan | null {
  if (decision.verdict === "LOCKED_PASS" || decision.verdict === "PASS_CANDIDATE") return null;

  if (decision.reason.includes("native BLE/GATT transport remains unconfirmed")) {
    return {
      issue: "Native transport not proven",
      cause: "packetId appeared in workflow/bridge logs but not Android BLE/GATT callback lines.",
      nextAction: "Patch real BLE/GATT callbacks or verify the bridge is called from native transport, then rerun logcat capture.",
      shellHint: "Search logcat for MAURIMESH_NATIVE_BLE_PACKET packetId=<id> transport=BLE_GATT",
      confidence: 0.9,
    };
  }

  if (decision.reason.includes("incomplete")) {
    return {
      issue: "Incomplete proof path",
      cause: "Not all required TX/RX/relay/ACK stages were observed for the same packetId.",
      nextAction: "Repeat the proof with all three phones awake, same route screen open, and monitor running before first tap.",
      shellHint: "Run 3-device monitor, then tap proof stages in order.",
      confidence: 0.78,
    };
  }

  return {
    issue: "Unknown proof weakness",
    cause: decision.reason,
    nextAction: "Review packet evidence manually and classify missing stages.",
    confidence: 0.4,
  };
}
