import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { RouteDecisionPanel } from "../src/components/RouteDecisionPanel";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function RouteLabScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>Route Lab</Text>
      <Text style={styles.subtitle}>
        SIMULATION route design for BLE, relay, Wi-Fi, internet fallback, trust, TTL, and path selection.
      </Text>
      <RouteDecisionPanel />
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
