import React, { useState } from "react";
import { StyleSheet, Text, TextInput, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { DeliveryLedgerPanel } from "../src/components/DeliveryLedgerPanel";
import { LivingMeshCanvas } from "../src/components/LivingMeshCanvas";
import { MauriButton } from "../src/components/MauriButton";
import { RoutePlanPanel } from "../src/components/RoutePlanPanel";
import { StatusPill } from "../src/components/StatusPill";
import { SynthPanel } from "../src/components/SynthPanel";
import {
  ackInventionRoute,
  failInventionRoute,
  getInventionEngineStatus,
  sendMessageThroughInventionEngine,
} from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof getInventionEngineStatus>>;

export default function RouteLabScreen() {
  const [message, setMessage] = useState("Kia kaha emergency help message through MauriMesh.");
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  async function run() {
    setSnapshot(await sendMessageThroughInventionEngine(message));
  }

  async function ack() {
    setSnapshot(await ackInventionRoute());
  }

  async function fail() {
    setSnapshot(await failInventionRoute());
  }

  return (
    <AppShell>
      <StatusPill label="ROUTE LAB" tone="info" />
      <Text style={styles.title}>Route Lab</Text>
      <Text style={styles.subtitle}>
        Test routing decisions, store-and-forward, ACK learning, failed-route learning,
        trust memory, and synth explanations.
      </Text>

      <TextInput
        style={styles.input}
        multiline
        value={message}
        onChangeText={setMessage}
        placeholder="Type route test message..."
        placeholderTextColor="rgba(255,255,255,0.45)"
      />

      <View style={styles.buttons}>
        <MauriButton title="Run Route Test" onPress={run} />
        <MauriButton title="ACK Last Route" variant="secondary" onPress={ack} />
        <MauriButton title="Fail Last Route" variant="danger" onPress={fail} />
      </View>

      <LivingMeshCanvas nodes={snapshot?.nodes || []} routes={snapshot?.routes || []} />
      <RoutePlanPanel routePlan={snapshot?.lastResult?.routePlan} />
      <SynthPanel messages={snapshot?.lastResult?.synth || []} />
      <DeliveryLedgerPanel ledger={snapshot?.lastResult?.ledger || []} />
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
  input: {
    minHeight: 110,
    borderRadius: mauriTheme.radius.lg,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    color: mauriTheme.colors.white,
    paddingHorizontal: mauriTheme.spacing.md,
    paddingVertical: mauriTheme.spacing.md,
    backgroundColor: mauriTheme.colors.panel,
  },
  buttons: {
    gap: mauriTheme.spacing.md,
  },
});
