import React, { useEffect, useState } from "react";
import { readPlatformLiveMeshState } from "../../lib/platformLiveMeshBridge";
import type { PlatformLiveMeshState } from "../../lib/platformLiveMeshTypes";
import { PLATFORM_LIVE_BLE_MESH_BRIDGE_MARKER } from "../../lib/platformLiveMeshTypes";

function emptyState(): PlatformLiveMeshState {
  return {
    marker: PLATFORM_LIVE_BLE_MESH_BRIDGE_MARKER,
    updatedAt: new Date().toISOString(),
    source: "unavailable",
    nativeModulePresent: false,
    permissionsGranted: false,
    scanActive: false,
    discoveredCount: 0,
    nodeCount: 0,
    routeCount: 0,
    deliveryCount: 0,
    relayCount: 0,
    ackCount: 0,
    failureCount: 0,
    nodes: [],
    metrics: [],
    truthLevel: "unavailable",
    truthBoundary: "Loading platform live mesh bridge.",
  };
}

export function PlatformLiveMeshPanel({ title = "Live BLE-Mesh Data" }: { title?: string }) {
  const [state, setState] = useState<PlatformLiveMeshState>(emptyState());

  useEffect(() => {
    let alive = true;

    async function tick() {
      const next = await readPlatformLiveMeshState();
      if (alive) setState(next);
    }

    tick();
    const timer = window.setInterval(tick, 3000);

    return () => {
      alive = false;
      window.clearInterval(timer);
    };
  }, []);

  return (
    <section
      style={{
        border: "1px solid rgba(0,208,132,0.32)",
        background: "rgba(255,255,255,0.035)",
        borderRadius: 20,
        padding: 20,
        margin: "16px 0",
      }}
    >
      <h2 style={{ color: "#fff", margin: "0 0 8px" }}>{title}</h2>
      <div style={{ color: "#4FC3F7", fontSize: 12, fontWeight: 800, letterSpacing: 1 }}>
        {state.marker}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginTop: 16 }}>
        <Metric label="Source" value={state.source} />
        <Metric label="Truth" value={state.truthLevel} />
        <Metric label="Scan" value={state.scanActive ? "ACTIVE" : "STOPPED"} />
        <Metric label="Discovered" value={state.discoveredCount} />
        <Metric label="Nodes" value={state.nodeCount} />
        <Metric label="Routes" value={state.routeCount} />
        <Metric label="Delivery" value={state.deliveryCount} />
        <Metric label="ACK" value={state.ackCount} />
      </div>

      <p style={{ color: "rgba(255,255,255,0.68)", lineHeight: 1.6, marginTop: 16 }}>
        {state.truthBoundary}
      </p>
    </section>
  );
}

function Metric({ label, value }: { label: string; value: string | number | boolean }) {
  return (
    <div>
      <div style={{ color: "rgba(255,255,255,0.64)", fontSize: 12, fontWeight: 700 }}>
        {label}
      </div>
      <div style={{ color: "#fff", fontSize: 18, fontWeight: 900 }}>
        {String(value)}
      </div>
    </div>
  );
}
