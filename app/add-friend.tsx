import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriButton } from "../src/components/MauriButton";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function AddFriendScreen() {
  return (
    <AppShell>
      <StatusPill label="QR + NETWORK SEARCH SHELL" tone="info" />

      <Text style={styles.title}>Add Friend</Text>

      <Text style={styles.subtitle}>
        Replit can finish the UI shell. Camera QR scanning and nearby BLE discovery require APK/device validation.
      </Text>

      <View style={styles.truthBox}>
        <Text style={styles.truthTitle}>Camera QR / APK required</Text>
        <Text style={styles.truthText}>
          Camera QR scanning and nearby BLE discovery require APK/device validation. Replit shows the UI shell only.
        </Text>
      </View>

      <View style={styles.qrBox}>
        <Text style={styles.qrText}>MAURIMESH QR</Text>
        <Text style={styles.qrSub}>UI SHELL ONLY</Text>
      </View>

      <MauriButton title="Scan QR Code" onPress={() => {}} />
      <MauriButton title="Search Nearby Mesh" variant="secondary" onPress={() => {}} />
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
  truthBox: {
    borderWidth: 1,
    borderColor: "rgba(56,189,248,0.45)",
    backgroundColor: "rgba(56,189,248,0.10)",
    borderRadius: mauriTheme.radius.lg,
    padding: mauriTheme.spacing.md,
    gap: 6,
  },
  truthTitle: {
    color: mauriTheme.colors.blueWeb,
    fontWeight: "900",
  },
  truthText: {
    color: mauriTheme.colors.mutedWhite,
    lineHeight: 20,
  },
  qrBox: {
    height: 260,
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
  },
  qrText: {
    color: mauriTheme.colors.greenstone,
    fontWeight: "900",
    letterSpacing: 2,
  },
  qrSub: {
    color: mauriTheme.colors.mutedWhite,
    fontSize: 12,
    fontWeight: "800",
  },
});
