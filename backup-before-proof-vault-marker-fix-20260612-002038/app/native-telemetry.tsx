import React from "react";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { NativeTelemetryPanel } from "../src/components/NativeTelemetryPanel";

export default function NativeTelemetryScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="NATIVE TELEMETRY"
        title="Native Telemetry"
        subtitle="APK-ready hardware bridge for battery, memory, storage, thermal, BLE adapter state, and runtime optimisation."
        tone="info"
      />
      <NativeTelemetryPanel />
    </AppShell>
  );
}
