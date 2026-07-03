import { useCallback, useEffect, useState } from "react";
import {
  clearProofMetrics,
  getProofMetricsSnapshot,
  ProofMetricsSnapshot,
  recordProofMetricEvent,
  ProofMetricEvent,
} from "./proofMetricsSpine";

export const TASK_190_USE_PROOF_METRICS_MARKER =
  "TASK_190_USE_PROOF_METRICS_20260608_A";

export function useProofMetrics(pollMs = 1500) {
  const [snapshot, setSnapshot] = useState<ProofMetricsSnapshot | null>(null);

  const refresh = useCallback(async () => {
    const next = await getProofMetricsSnapshot();
    setSnapshot(next);
    return next;
  }, []);

  const record = useCallback(
    async (event: Omit<ProofMetricEvent, "id" | "at">) => {
      const next = await recordProofMetricEvent(event);
      setSnapshot(next);
      return next;
    },
    []
  );

  const clear = useCallback(async () => {
    const next = await clearProofMetrics();
    setSnapshot(next);
    return next;
  }, []);

  useEffect(() => {
    let alive = true;

    getProofMetricsSnapshot().then((next) => {
      if (alive) setSnapshot(next);
    });

    const timer = setInterval(() => {
      getProofMetricsSnapshot().then((next) => {
        if (alive) setSnapshot(next);
      });
    }, pollMs);

    return () => {
      alive = false;
      clearInterval(timer);
    };
  }, [pollMs]);

  return {
    marker: TASK_190_USE_PROOF_METRICS_MARKER,
    snapshot,
    refresh,
    record,
    clear,
  };
}
