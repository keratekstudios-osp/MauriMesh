import { PixelCallingBackupFallbackPanel } from "../src/components/PixelCallingBackupFallbackPanel";
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { PixelCallingRuntimePanel } from "../src/components/PixelCallingRuntimePanel";

export default function PixelCallingScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="PIXEL CALLING"
        title="Pixel Calling"
        subtitle="Prepared call runtime with ringing, strict ACK proof, fallback calling, push-to-talk, voice note, text fallback, and store-forward protection."
        tone="warning"
      />
      <PixelCallingRuntimePanel />
          <PixelCallingBackupFallbackPanel />
    </AppShell>
  );
}
