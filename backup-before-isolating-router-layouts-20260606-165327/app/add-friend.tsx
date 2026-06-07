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
        Camera QR scanning and BLE discovery require APK/device validation.
      </Text>

      <View style={styles.qrBox}>
        <Text style={styles.qrText}>MAURIMESH QR</Text>
      </View>

      <MauriButton title="Scan QR Code" onPress={() => {}} />
      <MauriButton title="Search Nearby Mesh" variant="secondary" onPress={() => {}} />
    </AppShell>
  );
}

const styles = StyleSheet.create({
  title: { color: mauriTheme.colors.white, fontSize: 34, fontWeight: "900" },
  subtitle: { color: mauriTheme.colors.mutedWhite, lineHeight: 22 },
  qrBox: {
    height: 260,
    borderRadius: mauriTheme.radius.xl,
    borderWidth: 1,
    borderColor: mauriTheme.colors.panelBorder,
    backgroundColor: mauriTheme.colors.panel,
    alignItems: "center",
    justifyContent: "center"
  },
  qrText: { color: mauriTheme.colors.greenstone, fontWeight: "900", letterSpacing: 2 }
});
