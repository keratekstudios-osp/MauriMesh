import { MessageFallbackPanel } from "../src/components/MessageFallbackPanel";
import { HybridWifiBleMeshPanel } from "../src/components/HybridWifiBleMeshPanel";
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { BleHardwareRuntimePanel } from "../src/components/BleHardwareRuntimePanel";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function BleHardwareRuntimeScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="BLE HARDWARE RUNTIME"
        title="BLE Hardware Runtime"
        subtitle="Connects device telemetry and hardware runtime control to BLE scan cadence, retries, proof throttling, and backup failover."
        tone="info"
      />
      <BleHardwareRuntimePanel />
          <HybridWifiBleMeshPanel />
          <MessageFallbackPanel />
    </AppShell>
  );
}
