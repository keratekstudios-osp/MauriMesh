import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { mauriTheme } from "../theme/mauriTheme";
import { StatusPill } from "./StatusPill";

export function DeviceProofCard() {
  const checks = [
    "Install APK on Phone A and Phone B",
    "Grant Bluetooth, Nearby Devices, Location, and notification permissions",
    "Run BLE receiver on Phone B",
    "Send packet from Phone A",
    "Capture logcat proof for TX, RX, relay, ACK, and packet ID",
  ];

  return (
    <View style={styles.card}>
      <StatusPill label="APK / DEVICE PROOF REQUIRED" tone="danger" />
      <Text style={styles.title}>Device Proof</Text>
      <Text style={styles.subtitle}>
        This page does not fake BLE. It shows the exact APK/phone proof checklist needed for real native validation.
      </Text>

      {checks.map((check) => (
        <Text key={check} style={styles.item}>□ {check}</Text>
      ))}

      <View style={styles.truth}>
        <Text style={styles.truthTitle}>Truth</Text>
        <Text style={styles.truthText}>
          Replit proves UI and TypeScript only. Real BLE proof requires physical Android devices and logcat evidence.
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
  item: {
    color: mauriTheme.colors.white,
    lineHeight: 22,
  },
  truth: {
    borderWidth: 1,
    borderColor: mauriTheme.colors.danger,
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    backgroundColor: "rgba(239,68,68,0.10)",
  },
  truthTitle: {
    color: mauriTheme.colors.danger,
    fontWeight: "900",
    marginBottom: 4,
  },
  truthText: {
    color: mauriTheme.colors.white,
    lineHeight: 20,
  },
});
