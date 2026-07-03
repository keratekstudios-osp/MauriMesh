import React from "react";
import { AppShell } from "../src/components/AppShell";
import { HybridWifiBleMeshPanel } from "../src/components/HybridWifiBleMeshPanel";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function HybridWifiBleMeshScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="HYBRID MESH"
        title="Hybrid Wi-Fi + BLE Mesh"
        subtitle="Backup transport routing across BLE direct, BLE relay, store-forward, Wi-Fi local, Wi-Fi Direct-ready, and internet gateway fallback."
        tone="info"
      />
      <HybridWifiBleMeshPanel />
    </AppShell>
  );
}
