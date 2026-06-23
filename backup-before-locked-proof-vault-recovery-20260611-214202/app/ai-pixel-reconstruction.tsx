import React from "react";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { AiPixelReconstructionPanel } from "../src/components/AiPixelReconstructionPanel";

export default function AiPixelReconstructionScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="AI PIXEL ENGINE"
        title="AI Pixel Reconstruction"
        subtitle="1080p compressed source frames enhanced toward a 32K reconstruction target on the receiver, with quality score, frame hash, and reconstructed-pixel ACK proof."
        tone="warning"
      />
      <AiPixelReconstructionPanel />
    </AppShell>
  );
}
