import React, { useEffect, useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { StatusPill } from "../src/components/StatusPill";
import { getMauriSystemBrain } from "../src/lib/mauriSystemBrainClient";
import { SystemEvolutionSnapshot } from "../src/maurimesh/system-brain/systemTypes";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function LayerMapScreen() {
  const [snapshot, setSnapshot] = useState<SystemEvolutionSnapshot | null>(null);

  useEffect(() => {
    getMauriSystemBrain().then(setSnapshot);
  }, []);

  return (
    <AppShell>
      <StatusPill label="LAYER MAP" tone="info" />
      <Text style={styles.title}>All Inventions + Integrations</Text>
      <Text style={styles.subtitle}>
        Every layer is placed where it belongs in the system, with dependencies,
        optimisation targets, and proof boundary.
      </Text>

      {snapshot?.layerMap.map((layer) => (
        <View key={layer.id} style={styles.card}>
          <StatusPill
            label={layer.status}
            tone={
              layer.status === "ACTIVE" || layer.status === "LEARNING" || layer.status === "OPTIMISING"
                ? "success"
                : layer.status === "NEEDS_NATIVE_PROOF" || layer.status === "NEEDS_REVIEW"
                  ? "warning"
                  : "info"
            }
          />
          <Text style={styles.name}>{layer.name}</Text>
          <Text style={styles.label}>Purpose</Text>
          <Text style={styles.text}>{layer.purpose}</Text>
          <Text style={styles.label}>Belongs because</Text>
          <Text style={styles.text}>{layer.belongsBecause}</Text>
          <Text style={styles.label}>Optimises</Text>
          <Text style={styles.text}>{layer.optimises.join(", ")}</Text>
          <Text style={styles.label}>Dependencies</Text>
          <Text style={styles.text}>{layer.dependencies.join(", ")}</Text>
          <Text style={styles.boundary}>{layer.proofBoundary}</Text>
        </View>
      ))}
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
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.sm,
  },
  name: {
    color: mauriTheme.colors.white,
    fontSize: 20,
    fontWeight: "900",
  },
  label: {
    color: mauriTheme.colors.greenstone,
    fontSize: 12,
    fontWeight: "900",
    letterSpacing: 0.7,
  },
  text: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  boundary: {
    color: mauriTheme.colors.warning,
    lineHeight: 21,
    fontWeight: "700",
  },
});
