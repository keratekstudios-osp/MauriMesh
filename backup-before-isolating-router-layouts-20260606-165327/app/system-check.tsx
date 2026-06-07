import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { CompletionAuditPanel } from "../src/components/CompletionAuditPanel";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { getMauriCompletionAudit, MauriCompletionAudit } from "../src/lib/mauriEssentials";
import { runInventionDemo } from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function SystemCheckScreen() {
  const [audit, setAudit] = useState<MauriCompletionAudit | null>(null);

  function refresh() {
    setAudit(getMauriCompletionAudit());
  }

  async function demoThenAudit() {
    await runInventionDemo();
    refresh();
  }

  useEffect(() => {
    refresh();
  }, []);

  return (
    <AppShell>
      <StatusPill label="SYSTEM CHECK" tone="success" />
      <Text style={styles.title}>MauriMesh System Check</Text>
      <Text style={styles.subtitle}>
        Final Replit-side audit for invention engine, UI wiring, ledger, route memory,
        trust memory, and native proof boundaries.
      </Text>

      <MauriButton title="Run Demo + Refresh Audit" onPress={demoThenAudit} />
      <MauriButton title="Refresh Audit" variant="secondary" onPress={refresh} />

      {audit ? <CompletionAuditPanel audit={audit} /> : null}

      <Text style={styles.truth}>
        Completion truth: Replit can prove logic, screens, state transitions, and API wiring.
        Physical phone proof is still required for real BLE, Wi-Fi Direct, background service,
        and offline phone-to-phone packet transport.
      </Text>
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: {
    color: mauriTheme.colors.white,
    fontSize: 34,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 22,
  },
  truth: {
    color: mauriTheme.colors.warning,
    fontSize: 13,
    lineHeight: 20,
    fontWeight: "700",
  },
});
