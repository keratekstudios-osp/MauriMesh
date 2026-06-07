import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { DeliveryLedgerPanel } from "../src/components/DeliveryLedgerPanel";
import { InventionEngineCard } from "../src/components/InventionEngineCard";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { MauriButton } from "../src/components/MauriButton";
import { RoutePlanPanel } from "../src/components/RoutePlanPanel";
import { StatusPill } from "../src/components/StatusPill";
import { SynthPanel } from "../src/components/SynthPanel";
import {
  ackInventionRoute,
  failInventionRoute,
  getInventionEngineStatus,
  resetInventionEngine,
  runInventionDemo,
} from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof getInventionEngineStatus>>;

export default function InventionEngineScreen() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  async function refresh() {
    setSnapshot(await getInventionEngineStatus());
  }

  useEffect(() => {
    refresh();
  }, []);

  async function runDemo() {
    setSnapshot(await runInventionDemo());
  }

  async function ackRoute() {
    setSnapshot(await ackInventionRoute());
  }

  async function failRoute() {
    setSnapshot(await failInventionRoute());
  }

  async function reset() {
    setSnapshot(await resetInventionEngine());
  }

  const result = snapshot?.lastResult;

  return (
    <AppShell>
      <StatusPill label="LOCAL LOGIC ENGINE" tone="success" />
      <Text style={styles.title}>MauriMesh Invention Engine</Text>
      <Text style={styles.subtitle}>
        This wires Mauri AI, Tikanga governance, hybrid routing, store-and-forward,
        self-healing, trust memory, and Cleo + Chanelle Synth AI into the Replit UI.
      </Text>

      <InventionEngineCard
        title="Engine Status"
        value={snapshot?.message || "Loading invention engine..."}
        tone="success"
      />

      <View style={styles.buttonGrid}>
        <MauriButton title="Run Demo Message" onPress={runDemo} />
        <MauriButton title="ACK Last Route" variant="secondary" onPress={ackRoute} />
        <MauriButton title="Fail Last Route" variant="danger" onPress={failRoute} />
        <MauriButton title="Reset Demo" variant="secondary" onPress={reset} />
      </View>

      <View style={styles.metrics}>
        <InventionEngineCard
          title="Ledger Events"
          value={`${snapshot?.ledgerCount || 0} proof event(s) recorded.`}
          tone="info"
        />
        <InventionEngineCard
          title="Trust Memory"
          value={`${snapshot?.trustCount || 0} node trust record(s) active.`}
          tone="info"
        />
        <InventionEngineCard
          title="Route Memory"
          value={`${snapshot?.routeMemoryCount || 0} route learning record(s) active.`}
          tone="info"
        />
      </View>

      <Text style={styles.section}>Living Mesh Visual Proof</Text>
      <LivingMeshCanvas
        nodes={snapshot?.nodes || []}
        routes={snapshot?.routes || []}
      />

      <RoutePlanPanel routePlan={result?.routePlan} />
      <SynthPanel messages={result?.synth || []} />
      <DeliveryLedgerPanel ledger={result?.ledger || []} />

      <Text style={styles.truth}>
        Truth: This proves the Replit-safe invention logic and UI wiring. Real BLE,
        phone-to-phone transport, background Bluetooth, and APK behaviour still need
        physical device validation.
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
  buttonGrid: {
    gap: mauriTheme.spacing.md,
  },
  metrics: {
    gap: mauriTheme.spacing.md,
  },
  section: {
    color: mauriTheme.colors.white,
    fontSize: 22,
    fontWeight: "900",
    marginTop: mauriTheme.spacing.sm,
  },
  truth: {
    color: mauriTheme.colors.warning,
    fontSize: 13,
    lineHeight: 20,
    fontWeight: "700",
  },
});
