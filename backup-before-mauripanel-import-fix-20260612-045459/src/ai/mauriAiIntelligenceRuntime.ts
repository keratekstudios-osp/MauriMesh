import {
  MauriAiRouteCandidate,
  MauriAiRuntimeSnapshot,
  MauriAiSignal,
} from "./mauriAiTypes";
import { HybridAiRoutingLogic } from "../routing/hybridAiRoutingLogic";
import { JumpCodeEngine } from "../routing/jumpCodeEngine";
import { StoreForwardIntelligence } from "../routing/storeForwardIntelligence";
import { AiGovernanceIntelligence } from "../governance/aiGovernanceIntelligence";

export class MauriAiIntelligenceRuntime {
  private hybridRouting = new HybridAiRoutingLogic();
  private jumpCode = new JumpCodeEngine();
  private storeForward = new StoreForwardIntelligence();
  private governance = new AiGovernanceIntelligence();

  private memory = {
    learnedEvents: 0,
    routeSuccess: 0,
    routeFailure: 0,
    storedPackets: 0,
    forwardedPackets: 0,
    healedEvents: 0,
  };

  decide(signal: MauriAiSignal, candidates: MauriAiRouteCandidate[]): MauriAiRuntimeSnapshot {
    this.memory.learnedEvents += 1;

    const routeDecision = this.hybridRouting.decide(signal, candidates);
    const governance = this.governance.evaluate(signal, routeDecision.decision);

    if (signal.ackSuccess) this.memory.routeSuccess += 1;
    if (signal.routeFailure) this.memory.routeFailure += 1;

    if (governance.decision === "store_forward") {
      this.memory.storedPackets += 1;
    }

    if (governance.decision === "self_heal") {
      this.memory.healedEvents += 1;
    }

    if (
      routeDecision.selectedRoute &&
      this.jumpCode.shouldUseJumpCode(routeDecision.selectedRoute.score)
    ) {
      this.jumpCode.createJumpCodePath(
        signal.peerId ?? "local",
        routeDecision.selectedRoute.peerId,
        candidates
      );
    }

    return {
      at: Date.now(),
      decision: governance.decision,
      selectedRoute: routeDecision.selectedRoute,
      routeScores: routeDecision.routeScores,
      governance,
      memory: { ...this.memory },
      truth:
        "Mauri AI routing intelligence is active. Replit validates logic only. Real BLE proof requires APK plus physical phones.",
    };
  }

  storePacket(packetId: string, peerId: string, payload: unknown): void {
    this.storeForward.store({
      packetId,
      peerId,
      payload,
      maxAttempts: 12,
      ttlMs: 120000,
      priority: 5,
    });
    this.memory.storedPackets += 1;
  }

  storeForwardSnapshot() {
    return this.storeForward.snapshot();
  }
}
