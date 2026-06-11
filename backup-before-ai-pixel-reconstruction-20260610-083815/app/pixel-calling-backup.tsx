import React from "react";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { PixelCallingBackupFallbackPanel } from "../src/components/PixelCallingBackupFallbackPanel";

export default function PixelCallingBackupScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="PIXEL CALLING BACKUP"
        title="Pixel Calling Backup Fallback"
        subtitle="Fallback-backup path for failed call runtime: backup control, push-to-talk, voice note, text fallback, and store-forward hold."
        tone="warning"
      />
      <PixelCallingBackupFallbackPanel />
    </AppShell>
  );
}
