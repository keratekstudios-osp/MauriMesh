import { useCallback, useEffect, useState } from "react";
import {
  readLiveMeshState,
  startLiveMeshScan,
  stopLiveMeshScan,
} from "./nativeBleLiveSource";
import type { LiveMeshState } from "./types";

const emptyState: LiveMeshState = {
  marker: "LIVE_MESH_DATA_SPINE_20260608_A",
  updatedAt: new Date(0).toISOString(),
  nativeModulePresent: false,
  permissionsGranted: false,
  scanActive: false,
  discoveredCount: 0,
  nodes: [],
  metrics: {
    createdAt: new Date(0).toISOString(),
    scanActive: false,
    discoveredCount: 0,
    nodeCount: 0,
    routeCount: 0,
    deliveryCount: 0,
    relayCount: 0,
    ackCount: 0,
    failureCount: 0,
    averageLatencyMs: 0,
    truthLevel: "not_proven",
  },
  lastNativeStatus: {
    module: "MauriMeshBle",
    mode: "not_loaded",
    modulePresent: false,
    blePermissions: false,
    liveBleActive: false,
    scanActive: false,
    discoveredCount: 0,
  },
  truthBoundary:
    "Live mesh state has not loaded yet. No mesh delivery claim is made.",
};

export function useLiveMesh(pollMs = 2000) {
  const [state, setState] = useState<LiveMeshState>(emptyState);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const next = await readLiveMeshState();
      setState(next);
      return next;
    } finally {
      setLoading(false);
    }
  }, []);

  const startScan = useCallback(async () => {
    setLoading(true);
    try {
      const next = await startLiveMeshScan();
      setState(next);
      return next;
    } finally {
      setLoading(false);
    }
  }, []);

  const stopScan = useCallback(async () => {
    setLoading(true);
    try {
      const next = await stopLiveMeshScan();
      setState(next);
      return next;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let alive = true;

    async function tick() {
      const next = await readLiveMeshState();
      if (alive) setState(next);
    }

    tick();

    const timer = setInterval(tick, pollMs);

    return () => {
      alive = false;
      clearInterval(timer);
    };
  }, [pollMs]);

  return {
    state,
    loading,
    refresh,
    startScan,
    stopScan,
  };
}
