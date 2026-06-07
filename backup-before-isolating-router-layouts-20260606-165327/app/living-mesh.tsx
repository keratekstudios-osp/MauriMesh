import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { InventionEngineCard } from "../src/components/InventionEngineCard";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { MauriButton } from "../src/components/MauriButton";
import { RoutePlanPanel } from "../src/components/RoutePlanPanel";
import { StatusPill } from "../src/components/StatusPill";
import {
  getInventionEngineStatus,
  runInventionDemo,
} from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof getInventionEngineStatus>>;

export default function LivingMeshScreen() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  async function refresh() {
    setSnapshot(await getInventionEngineStatus());
  }

  async function demo() {
    setSnapshot(await runInventionDemo());
  }

  useEffect(() => {
    refresh();
  }, []);

  return (
    <AppShell>
      <StatusPill label={snapshot?.mode || "CHECKING"} tone="success" />
      <Text style={styles.title}>Living Mesh</Text>
      <Text style={styles.subtitle}>
        {snapshot?.message || "Checking local invention engine."}
      </Text>

      <MauriButton title="Run Living Mesh Demo" onPress={demo} />

      <LivingMeshCanvas
        nodes={snapshot?.nodes || []}
        routes={snapshot?.routes || []}
      />

      <InventionEngineCard
        title="Visual Proof Layer"
        value={`${snapshot?.nodes.length || 0} node(s), ${snapshot?.routes.length || 0} route(s), ${snapshot?.ledgerCount || 0} ledger event(s).`}
        tone="info"
      />

      <RoutePlanPanel routePlan={snapshot?.lastResult?.routePlan} />
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
});
