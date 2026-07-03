import {
  MauriAiDecision,
  MauriAiRouteCandidate,
  MauriAiRouteScore,
  MauriAiSignal,
} from "../ai/mauriAiTypes";
import { MauriAiRoutingIntelligence } from "./mauriAiRoutingIntelligence";

export class HybridAiRoutingLogic {
  private routing = new MauriAiRoutingIntelligence();

  decide(
    signal: MauriAiSignal,
    candidates: MauriAiRouteCandidate[]
  ): {
    decision: MauriAiDecision;
    selectedRoute?: MauriAiRouteScore;
    routeScores: MauriAiRouteScore[];
    reason: string;
  } {
    const routeScores = candidates
      .map(candidate => this.routing.scoreRoute(candidate))
      .sort((a, b) => b.score - a.score);

    const selectedRoute = routeScores[0];

    if (!signal.physicalBleProven) {
      return {
        decision: "require_physical_proof",
        selectedRoute,
        routeScores,
        reason: "Physical BLE proof required before claiming live Bluetooth operation.",
      };
    }

    if (signal.tikangaSafe === false) {
      return {
        decision: "block_unsafe",
        selectedRoute,
        routeScores,
        reason: "Tikanga/governance safety blocked unsafe action.",
      };
    }

    if (!selectedRoute) {
      return {
        decision: "store_forward",
        routeScores,
        reason: "No route candidate available. Store-forward required.",
      };
    }

    if (selectedRoute.score >= 0.82) {
      return {
        decision: "send_direct",
        selectedRoute,
        routeScores,
        reason: "Strong direct route available.",
      };
    }

    if (selectedRoute.score >= 0.62) {
      return {
        decision: "send_relay",
        selectedRoute,
        routeScores,
        reason: "Moderate route available. Relay mode recommended.",
      };
    }

    if (selectedRoute.score >= 0.42) {
      return {
        decision: "send_jumpcode",
        selectedRoute,
        routeScores,
        reason: "Weak route. JumpCode alternate path recommended.",
      };
    }

    if ((signal.queueDepth ?? 0) > 0 || signal.peerStale) {
      return {
        decision: "store_forward",
        selectedRoute,
        routeScores,
        reason: "Peer unavailable or queue pressure detected. Store-forward selected.",
      };
    }

    return {
      decision: "self_heal",
      selectedRoute,
      routeScores,
      reason: "Route confidence too low. Self-healing should repair path.",
    };
  }
}
