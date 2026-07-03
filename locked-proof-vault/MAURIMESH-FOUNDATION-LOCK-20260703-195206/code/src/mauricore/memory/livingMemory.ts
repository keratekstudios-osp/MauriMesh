import { MemoryQuality, MemoryRecord } from "../types/core.types";
import { bayesianUpdate, clamp01 } from "../math/mathIntelligence";

const memory: MemoryRecord[] = [];

export function recordMemory(input: {
  event: string;
  result: "success" | "failure" | "blocked" | "unknown";
  cause?: string;
  lesson?: string;
  futureBehaviour?: string;
  confidence?: number;
  quality?: MemoryQuality;
  evidence?: string[];
}): MemoryRecord {
  const record: MemoryRecord = {
    id: `memory_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    timestamp: new Date().toISOString(),
    event: input.event,
    result: input.result,
    cause: input.cause,
    lesson: input.lesson,
    futureBehaviour: input.futureBehaviour,
    confidence: clamp01(input.confidence ?? 0.5),
    quality: input.quality ?? "observed",
    evidence: input.evidence || [],
  };

  memory.push(record);
  return record;
}

export function getLivingMemory(): MemoryRecord[] {
  return [...memory];
}

export function updateMemoryConfidence(event: string, evidencePositive: boolean): number {
  const related = memory.filter((item) => item.event === event);
  const latest = related[related.length - 1];
  const prior = latest?.confidence ?? 0.5;

  return bayesianUpdate(prior, 0.35, evidencePositive);
}

export function classifyMemoryQuality(record: MemoryRecord): MemoryQuality {
  if (record.quality === "poisoned" || record.quality === "unsafe") return record.quality;

  const repeated = memory.filter((item) => item.event === record.event).length;

  if (record.confidence >= 0.92 && repeated >= 5) return "inherited";
  if (record.confidence >= 0.85 && repeated >= 3) return "trusted";
  if (record.confidence >= 0.72 && record.evidence.length > 0) return "verified";
  if (repeated >= 2) return "repeated";

  return "observed";
}

export function detectMemoryPoisoning(): string[] {
  const alerts: string[] = [];

  for (const record of memory) {
    if (record.confidence > 0.9 && record.evidence.length === 0) {
      alerts.push(`High confidence without evidence: ${record.id}`);
    }

    if (record.lesson?.toLowerCase().includes("fake proof")) {
      alerts.push(`Unsafe lesson detected: ${record.id}`);
    }
  }

  return alerts;
}
