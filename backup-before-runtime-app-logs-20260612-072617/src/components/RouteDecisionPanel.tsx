import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

const routes = [
  { name: "BLE Direct", score: 68, reason: "Low energy, short range, best when peer is nearby." },
  { name: "BLE Relay → Wi-Fi", score: 91, reason: "Best hybrid path. Relay discovers stronger Wi-Fi completion path." },
  { name: "Internet Fallback", score: 74, reason: "Use only when mesh path cannot complete delivery." },
];

export function RouteDecisionPanel() {
  return (
    <View style={styles.card}>
      <StatusPill label="ROUTE LAB / SIMULATION" tone="info" />
      <Text style={styles.title}>Route Lab</Text>
      <Text style={styles.subtitle}>
        Visual decision layer for BLE, relay, Wi-Fi, internet fallback, trust score, TTL, and path selection.
      </Text>

      {routes.map((route) => (
        <View key={route.name} style={styles.route}>
          <View style={styles.routeTop}>
            <Text style={styles.routeName}>{route.name}</Text>
            <Text style={styles.score}>{route.score}%</Text>
          </View>
          <Text style={styles.reason}>{route.reason}</Text>
        </View>
      ))}

      <View style={styles.selected}>
        <Text style={styles.selectedTitle}>Selected Route</Text>
        <Text style={styles.selectedText}>
          BLE Relay → Wi-Fi selected because it balances delivery confidence, energy, and path resilience.
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    borderRadius: mauriTheme.radius.xl,
    padding: mauriTheme.spacing.lg,
    gap: mauriTheme.spacing.md,
  },
  title: {
    color: mauriTheme.colors.white,
    fontSize: 24,
    fontWeight: "900",
  },
  subtitle: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 21,
  },
  route: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    gap: 6,
  },
  routeTop: {
    flexDirection: "row",
    justifyContent: "space-between",
    gap: 12,
  },
  routeName: {
    color: mauriTheme.colors.white,
    fontWeight: "900",
    fontSize: 15,
  },
  score: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
  },
  reason: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
  selected: {
    backgroundColor: "rgba(0,208,132,0.12)",
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    borderWidth: 1,
    borderColor: mauriTheme.colors.greenstone,
  },
  selectedTitle: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
    marginBottom: 4,
  },
  selectedText: {
    color: mauriTheme.colors.white,
    lineHeight: 20,
  },
});
