import type { TrustRecord } from "./types";

const INITIAL_SCORE = 50;
const MAX_SCORE = 100;
const MIN_SCORE = 0;
const SUCCESS_DELTA = 5;
const FAILURE_DELTA = 10;
const ACK_DELTA = 3;

export class MeshTrustEngine {
  private records = new Map<string, TrustRecord>();

  getRecord(nodeId: string): TrustRecord {
    if (!this.records.has(nodeId)) {
      this.records.set(nodeId, {
        nodeId,
        score: INITIAL_SCORE,
        successCount: 0,
        failureCount: 0,
        lastAckAt: 0,
      });
    }
    return this.records.get(nodeId)!;
  }

  recordDeliverySuccess(nodeId: string): void {
    const rec = this.getRecord(nodeId);
    rec.successCount++;
    rec.score = Math.min(MAX_SCORE, rec.score + SUCCESS_DELTA);
  }

  recordDeliveryFailure(nodeId: string): void {
    const rec = this.getRecord(nodeId);
    rec.failureCount++;
    rec.score = Math.max(MIN_SCORE, rec.score - FAILURE_DELTA);
  }

  recordAck(nodeId: string): void {
    const rec = this.getRecord(nodeId);
    rec.lastAckAt = Date.now();
    rec.score = Math.min(MAX_SCORE, rec.score + ACK_DELTA);
  }

  getScore(nodeId: string): number {
    return this.getRecord(nodeId).score;
  }

  isTrusted(nodeId: string, threshold = 60): boolean {
    return this.getScore(nodeId) >= threshold;
  }

  allRecords(): TrustRecord[] {
    return Array.from(this.records.values());
  }
}
