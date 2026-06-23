import React from "react";
import { AppShell } from "../src/components/AppShell";
import { HardwareRuntimeControllerPanel } from "../src/components/HardwareRuntimeControllerPanel";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function HardwareRuntimeScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="HARDWARE RUNTIME"
        title="Runtime Controller"
        subtitle="Connects native telemetry to BLE tuning, proof throttling, animation reduction, safe mode, and store-forward routing."
        tone="info"
      />
      <HardwareRuntimeControllerPanel />
    </AppShell>
  );
}
