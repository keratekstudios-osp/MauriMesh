import React, { useEffect, useState } from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { ButtonWiringPanel } from "../src/components/ButtonWiringPanel";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { SystemBrainPanel } from "../src/components/SystemBrainPanel";
import {
  evolveMauriSystemBrain,
  getMauriSystemBrain,
  stressLearnMauriSystemBrain,
} from "../src/lib/mauriSystemBrainClient";
import { SystemEvolutionSnapshot } from "../src/maurimesh/system-brain/systemTypes";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function SystemBrainScreen() {
  const [snapshot, setSnapshot] = useState<SystemEvolutionSnapshot | null>(null);

  async function refresh() {
    setSnapshot(await getMauriSystemBrain());
  }

  async function evolve() {
    setSnapshot(await evolveMauriSystemBrain());
  }

  async function stressLearn() {
    setSnapshot(await stressLearnMauriSystemBrain());
  }

  useEffect(() => {
    refresh();
  }, []);

  return (
    <AppShell>
      <StatusPill label="SELF-EFFICIENT SYSTEM" tone="success" />
      <Text style={styles.title}>MauriMesh System Brain</Text>
      <Text style={styles.subtitle}>
        Coordinates every invention, every integration, every button decision,
        and pulls incomplete wiring into the correct proof boundary.
      </Text>

      <MauriButton title="Evolve System Now" onPress={evolve} />
      <MauriButton title="Stress Learn + Recover" variant="secondary" onPress={stressLearn} />
      <MauriButton title="Refresh System Brain" variant="secondary" onPress={refresh} />

      {snapshot ? <SystemBrainPanel snapshot={snapshot} /> : null}
      {snapshot ? <ButtonWiringPanel buttons={snapshot.buttonConnections} /> : null}
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
