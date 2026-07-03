import React from "react";
import { AppShell } from "../src/components/AppShell";
import { DeviceHardwarePanel } from "../src/components/DeviceHardwarePanel";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function DeviceHardwareScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="DEVICE HARDWARE"
        title="Hardware Stabilizer"
        subtitle="Studies device pressure and adjusts MauriMesh runtime behaviour for battery, thermal, memory, storage, BLE, proof tasks, and safe mode."
        tone="info"
      />
      <DeviceHardwarePanel />
    </AppShell>
  );
}
