import React from "react";
import { IntelligencePanel } from "../src/components/IntelligencePanel";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function IntelligenceScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="INTELLIGENCE ORCHESTRATION"
        title="Intelligence"
        subtitle="Route scoring, proof confidence, Tikanga governance, self-healing, device readiness, and final truth state."
        tone="info"
      />
      <IntelligencePanel />
    </AppShell>
  );
}
