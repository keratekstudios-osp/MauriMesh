import {
  MauriDomainScore,
  MauriOperatingDecision,
  MauriOperatingLayer,
  MauriOperatingSignal,
  MauriOperatingSnapshot,
} from "./mauriOperatingTypes";
import { mauri155LayerCatalog } from "./mauri155LayerCatalog";

function clamp01(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.min(1, value));
}

function id(prefix: string): string {
  return `${prefix}_${Date.now().toString(36)}_${Math.random()
    .toString(36)
    .slice(2, 10)}`;
}

export class Mauri155OperatingRuntime {
  private layers = new Map<string, MauriOperatingLayer>();
  private signals: MauriOperatingSignal[] = [];

  constructor() {
    for (const layer of mauri155LayerCatalog) {
      this.layers.set(layer.id, { ...layer });
    }
  }

  start(): MauriOperatingSnapshot {
    this.emit({
      sourceLayerId: "runtime",
      type: "runtime_tick",
      confidence: 1,
      impact: 0.8,
      lesson:
        "MauriMesh 155+ operating runtime started. Every layer has a purpose and learns with the whole system.",
    });

    this.setDomainState("foundation", "ready", 0.92);
    this.setDomainState("learning", "learning", 0.88);
    this.setDomainState("tikanga", "ready", 0.9);
    this.setDomainState("observability", "observing", 0.78);
    this.setDomainState("experience", "ready", 0.8);

    return this.snapshot();
  }

  observeLayer(layerId: string, scoreDelta: number, lesson: string): void {
    const layer = this.layers.get(layerId);
    if (!layer) return;

    layer.state = "learning";
    layer.score = clamp01(layer.score + scoreDelta);

    this.emit({
      sourceLayerId: layerId,
      type: "observe",
      confidence: 0.85,
      impact: Math.abs(scoreDelta),
      lesson,
      data: {
        domain: layer.domain,
        layer: layer.name,
        score: layer.score,
      },
    });

    this.shareLearning(layer);
  }

  teachRouteSuccess(peerId: string, packetId: string): void {
    this.boostDomains(["routing", "packet", "learning", "whanau", "observability"], 0.04);

    this.emit({
      sourceLayerId: "routing",
      type: "route_success",
      confidence: 0.95,
      impact: 0.9,
      lesson:
        "Route success teaches routing, packet integrity, ACK confidence, whānau trust, and Living Mesh visibility.",
      data: { peerId, packetId },
    });
  }

  teachRouteFailure(peerId: string, packetId: string): void {
    this.reduceDomains(["routing", "transport"], 0.04);
    this.boostDomains(["healing", "learning"], 0.06);
    this.setDomainState("healing", "repairing");

    this.emit({
      sourceLayerId: "routing",
      type: "route_failure",
      confidence: 0.9,
      impact: 0.85,
      lesson:
        "Route failure activates store-forward, JumpCode, √2 balance, self-healing, and proof logging.",
      data: { peerId, packetId },
    });
  }

  teachAckReceived(peerId: string, packetId: string): void {
    this.boostDomains(["packet", "routing", "learning", "whanau"], 0.05);

    this.emit({
      sourceLayerId: "packet",
      type: "ack_received",
      confidence: 0.97,
      impact: 0.92,
      lesson:
        "ACK received. The system learns delivery truth, peer trust, latency expectation, and route quality.",
      data: { peerId, packetId },
    });
  }

  teachPhysicalBleRequired(reason: string): void {
    this.setDomainState("proof", "fallback", 0.5);
    this.setDomainState("physical", "fallback", 0.5);

    this.emit({
      sourceLayerId: "proof",
      type: "proof_required",
      confidence: 1,
      impact: 0.95,
      lesson:
        "Physical BLE proof is required. Replit can validate logic, but APK plus physical phones prove Bluetooth runtime.",
      data: { reason },
    });
  }

  teachTikangaWarning(reason: string): void {
    this.boostDomains(["tikanga", "observability"], 0.03);
    this.reduceDomains(["routing", "transport"], 0.02);

    this.emit({
      sourceLayerId: "tikanga",
      type: "tikanga_warning",
      confidence: 0.96,
      impact: 0.88,
      lesson:
        "Tikanga warning. Purpose, truth, consent, and safety override speed.",
      data: { reason },
    });
  }

  snapshot(): MauriOperatingSnapshot {
    const layers = [...this.layers.values()];
    const domainNames = Array.from(new Set(layers.map(layer => layer.domain)));

    const domainScores: MauriDomainScore[] = domainNames.map(domain => {
      const group = layers.filter(layer => layer.domain === domain);
      return {
        domain,
        score:
          group.reduce((sum, layer) => sum + layer.score, 0) /
          Math.max(1, group.length),
        layers: group.length,
        ready: group.filter(layer => layer.state === "ready").length,
        learning: group.filter(layer => layer.state === "learning").length,
        fallback: group.filter(layer => layer.state === "fallback").length,
        repairing: group.filter(layer => layer.state === "repairing").length,
        blocked: group.filter(layer => layer.state === "blocked").length,
      };
    });

    const wholeSystemScore =
      domainScores.reduce((sum, domain) => sum + domain.score, 0) /
      Math.max(1, domainScores.length);

    return {
      at: Date.now(),
      layerCount: layers.length,
      domainScores: domainScores.map(domain => ({
        ...domain,
        score: Number(domain.score.toFixed(4)),
      })),
      wholeSystemScore: Number(wholeSystemScore.toFixed(4)),
      decision: this.decide(wholeSystemScore),
      truth:
        "This is the one giant MauriMesh operating runtime. Replit proves logic only. Physical BLE proof requires APK plus physical phones.",
      strongestLayers: [...layers]
        .sort((a, b) => b.score - a.score)
        .slice(0, 12),
      weakestLayers: [...layers]
        .sort((a, b) => a.score - b.score)
        .slice(0, 12),
      latestSignals: this.signals.slice(-20),
    };
  }

  private emit(input: Omit<MauriOperatingSignal, "id" | "at">): void {
    this.signals.push({
      ...input,
      id: id("signal"),
      at: Date.now(),
      confidence: clamp01(input.confidence),
      impact: clamp01(input.impact),
    });

    if (this.signals.length > 1000) {
      this.signals = this.signals.slice(-500);
    }
  }

  private setDomainState(
    domain: MauriOperatingLayer["domain"],
    state: MauriOperatingLayer["state"],
    score?: number
  ): void {
    for (const layer of this.layers.values()) {
      if (layer.domain === domain) {
        layer.state = state;
        if (score !== undefined) layer.score = clamp01(score);
      }
    }
  }

  private boostDomains(domains: MauriOperatingLayer["domain"][], amount: number): void {
    for (const layer of this.layers.values()) {
      if (domains.includes(layer.domain)) {
        layer.score = clamp01(layer.score + amount);
        layer.state = layer.state === "idle" ? "learning" : layer.state;
      }
    }
  }

  private reduceDomains(domains: MauriOperatingLayer["domain"][], amount: number): void {
    for (const layer of this.layers.values()) {
      if (domains.includes(layer.domain)) {
        layer.score = clamp01(layer.score - amount);
        if (layer.score < 0.45) layer.state = "fallback";
      }
    }
  }

  private shareLearning(source: MauriOperatingLayer): void {
    for (const targetDomain of source.teachesTo) {
      for (const layer of this.layers.values()) {
        if (layer.domain === targetDomain) {
          layer.score = clamp01(layer.score + 0.005);
        }
      }
    }
  }

  private decide(score: number): MauriOperatingDecision {
    if (score >= 0.85) return "operate_strong";
    if (score >= 0.68) return "operate_monitored";
    if (score >= 0.5) return "fallback_store_forward";
    if (score >= 0.28) return "self_heal";
    return "block_unsafe_or_unproven";
  }
}
