import React, { useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { RoutePlanPanel } from "../src/components/RoutePlanPanel";
import { StatusPill } from "../src/components/StatusPill";
import { SynthPanel } from "../src/components/SynthPanel";
import { sendMessageThroughInventionEngine } from "../src/lib/inventionEngineClient";
import { mauriTheme } from "../src/theme/mauriTheme";

type Snapshot = Awaited<ReturnType<typeof sendMessageThroughInventionEngine>>;

export default function GovernanceScreen() {
  const [snapshot, setSnapshot] = useState<Snapshot | null>(null);

  async function sendPrivate() {
    setSnapshot(await sendMessageThroughInventionEngine("Private tapu message for trusted delivery only."));
  }

  async function sendFamily() {
    setSnapshot(await sendMessageThroughInventionEngine("Whānau family check-in through MauriMesh."));
  }

  async function sendEmergency() {
    setSnapshot(await sendMessageThroughInventionEngine("Kia kaha emergency help message."));
  }

  const governance = snapshot?.lastResult?.governance;

  return (
    <AppShell>
      <StatusPill label="TIKANGA PROTOCOL ENGINE" tone="success" />
      <Text style={styles.title}>Governance</Text>
      <Text style={styles.subtitle}>
        Test how MauriMesh classifies messages into cultural/privacy states before routing.
      </Text>

      <View style={styles.buttons}>
        <MauriButton title="Test Tapu / Private" onPress={sendPrivate} />
        <MauriButton title="Test Whānau / Trusted" variant="secondary" onPress={sendFamily} />
        <MauriButton title="Test Kia Kaha / Emergency" variant="danger" onPress={sendEmergency} />
      </View>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Governance Decision</Text>
        {!governance ? (
          <Text style={styles.text}>No governance decision yet.</Text>
        ) : (
          <>
            <Text style={styles.state}>{governance.culturalState}</Text>
            <Text style={styles.text}>{governance.reason}</Text>
            {governance.restrictions.map((r, index) => (
              <Text key={index} style={styles.restriction}>• {r}</Text>
            ))}
          </>
        )}
      </View>

      <RoutePlanPanel routePlan={snapshot?.lastResult?.routePlan} />
      <SynthPanel messages={snapshot?.lastResult?.synth || []} />
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
  buttons: {
    gap: mauriTheme.spacing.md,
  },
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  cardTitle: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  state: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  text: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  restriction: {
    color: mauriTheme.colors.warning,
    lineHeight: 20,
    fontWeight: "700",
  },
});
