import { MeshNode, TrustLevel } from "./types";
import { clamp } from "./utils";

export type TrustRecord = {
  nodeId: string;
  score: number;
  successes: number;
  failures: number;
  lastReason: string;
};

export class DecentralisedTrustMemory {
  private trust = new Map<string, TrustRecord>();

  observeSuccess(nodeId: string, reason = "Successful relay or ACK."): TrustRecord {
    const record = this.getOrCreate(nodeId);
    record.successes += 1;
    record.score = clamp(record.score + 0.04, 0, 1);
    record.lastReason = reason;
    this.trust.set(nodeId, record);
    return record;
  }

  observeFailure(nodeId: string, reason = "Failed relay or missing ACK."): TrustRecord {
    const record = this.getOrCreate(nodeId);
    record.failures += 1;
    record.score = clamp(record.score - 0.07, 0, 1);
    record.lastReason = reason;
    this.trust.set(nodeId, record);
    return record;
  }

  applyToNode(node: MeshNode): MeshNode {
    const record = this.trust.get(node.id);
    if (!record) return node;

    return {
      ...node,
      trust: this.scoreToTrust(record.score),
    };
  }

  scoreToTrust(score: number): TrustLevel {
    if (score <= 0.05) return "BLOCKED";
    if (score < 0.3) return "UNKNOWN";
    if (score < 0.55) return "OBSERVED";
    if (score < 0.78) return "TRUSTED";
    if (score < 0.93) return "VERIFIED";
    return "GUARDIAN";
  }

  exportTrust(): TrustRecord[] {
    return Array.from(this.trust.values());
  }

  private getOrCreate(nodeId: string): TrustRecord {
    return (
      this.trust.get(nodeId) || {
        nodeId,
        score: 0.5,
        successes: 0,
        failures: 0,
        lastReason: "Initial observation.",
      }
    );
  }
}
