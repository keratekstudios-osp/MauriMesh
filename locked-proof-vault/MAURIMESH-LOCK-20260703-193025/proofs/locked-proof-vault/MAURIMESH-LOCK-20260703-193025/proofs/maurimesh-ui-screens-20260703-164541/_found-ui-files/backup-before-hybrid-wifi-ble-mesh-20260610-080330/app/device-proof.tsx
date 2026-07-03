import React from "react";
import { StyleSheet, Text } from "react-native";
import { AppShell } from "../src/components/AppShell";
import { DeviceProofCard } from "../src/components/DeviceProofCard";
import { mauriTheme } from "../src/theme/mauriTheme";

export default function DeviceProofScreen() {
  return (
    <AppShell>
      <Text style={styles.title}>Device Proof</Text>
      <Text style={styles.subtitle}>
        APK/device checklist for real BLE, native Bluetooth, QR camera, logcat, packet delivery, and ACK proof.
      </Text>
      <DeviceProofCard />
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
