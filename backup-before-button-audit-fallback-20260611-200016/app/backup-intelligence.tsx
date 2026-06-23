import React from "react";
import { AppShell } from "../src/components/AppShell";
import { BackupIntelligencePanel } from "../src/components/BackupIntelligencePanel";
import { MauriPageHeader } from "../src/components/MauriPageHeader";

export default function BackupIntelligenceScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="BACKUP INTELLIGENCE"
        title="Backup Intelligence"
        subtitle="Failover brain for route scoring, proof state, Tikanga governance, self-healing, and device readiness."
        tone="warning"
      />
      <BackupIntelligencePanel />
    </AppShell>
  );
}
