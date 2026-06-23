import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { SelfHealingPanel } from "../src/components/SelfHealingPanel";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function SelfHealingScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>Self-Healing</Text>
      <Text style={styles.subtitle}>
        Living system UI for repair queues, resilience, route recovery, and homeostasis.
      </Text>
      <SelfHealingPanel />
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
