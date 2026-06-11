import { PixelCallingBackupFallbackPanel } from "../src/components/PixelCallingBackupFallbackPanel";
import { PixelCallingRuntimePanel } from "../src/components/PixelCallingRuntimePanel";
import React from "react";
import { AppShell } from "../src/components/AppShell";
import { MauriPageHeader } from "../src/components/MauriPageHeader";
import { MessageFallbackPanel } from "../src/components/MessageFallbackPanel";

export default function MessageFallbackScreen() {
  return (
    <AppShell>
      <MauriPageHeader
        eyebrow="DELIVERY PROOF"
        title="Message Queue + ACK Fallback"
        subtitle="Durable queue, retry planning, strict ACK fallback, relay ACK fallback, pending proof states, and offline hold."
        tone="warning"
      />
      <MessageFallbackPanel />
          <PixelCallingRuntimePanel />
          <PixelCallingBackupFallbackPanel />
    </AppShell>
  );
}
