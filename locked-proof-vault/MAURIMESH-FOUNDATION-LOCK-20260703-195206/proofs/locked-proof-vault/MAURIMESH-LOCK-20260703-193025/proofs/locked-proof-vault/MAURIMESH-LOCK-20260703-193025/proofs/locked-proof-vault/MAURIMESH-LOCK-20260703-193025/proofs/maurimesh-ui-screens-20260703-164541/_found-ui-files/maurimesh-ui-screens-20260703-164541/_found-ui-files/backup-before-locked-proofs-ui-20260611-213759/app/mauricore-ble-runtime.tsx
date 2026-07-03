import { MessageFallbackPanel } from "../src/components/MessageFallbackPanel";
import { HybridWifiBleMeshPanel } from "../src/components/HybridWifiBleMeshPanel";
import { BleHardwareRuntimePanel } from "../src/components/BleHardwareRuntimePanel";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { MauriCoreStatusPanel } from "../src/components/MauriCoreStatusPanel";
import { StatusPill } from "../src/components/StatusPill";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function MauriCoreBleRuntimeScreen() {
  return (
    <AppShell>
      <StatusPill label="BLE RUNTIME / APK REQUIRED" tone="danger" />
      <Text style={styles.title}>MauriCore BLE Runtime</Text>
      <Text style={styles.subtitle}>
        UI readiness screen for Android BLE runtime. Real BLE scanning, advertising, GATT, relay, and ACK require APK/device proof.
      </Text>

      <MauriCoreStatusPanel />

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Runtime Checklist</Text>
        <Text style={styles.item}>□ Bluetooth permissions granted</Text>
        <Text style={styles.item}>□ Nearby Devices permission granted</Text>
        <Text style={styles.item}>□ Phone B receiver advertising</Text>
        <Text style={styles.item}>□ Phone A sender discovers receiver</Text>
        <Text style={styles.item}>□ ACK proof captured in logcat</Text>
      </View>
          <BleHardwareRuntimePanel />
          <HybridWifiBleMeshPanel />
          <MessageFallbackPanel />
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
    gap: 8,
  },
  cardTitle: {
    color: mauriTheme.colors.greenstone,
    fontSize: 18,
    fontWeight: "900",
  },
  item: {
    color: mauriTheme.colors.white,
    lineHeight: 21,
  },
});
